import Foundation
import Combine

enum HomeState {
    case idle
    case loading
    case visitor
    case profileIncomplete(TodayHome)
    case empty(TodayHome)
    case loaded(TodayHome)
    case error(String, HomeErrorRecovery)
}

enum HomeErrorRecovery: Equatable {
    case retry
    case login
}

@MainActor
final class HomeViewModel: ObservableObject {
    private let apiClient: (any APIClient)?
    private let tokenStore: (any TokenStore)?
    private let localStore: (any LocalStore)?
    private let startsAsVisitor: Bool

    @Published private(set) var state: HomeState = .idle

    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    init(
        apiClient: any APIClient,
        tokenStore: (any TokenStore)? = nil,
        localStore: (any LocalStore)? = nil,
        startsAsVisitor: Bool = false
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.localStore = localStore
        self.startsAsVisitor = startsAsVisitor
    }

    private init(localStore: (any LocalStore)?) {
        self.apiClient = nil
        self.tokenStore = nil
        self.localStore = localStore
        self.startsAsVisitor = true
    }

    static func visitor(localStore: (any LocalStore)? = nil) -> HomeViewModel {
        HomeViewModel(localStore: localStore)
    }

    func load() async {
        guard case .idle = state else {
            return
        }
        await refresh()
    }

    func refresh() async {
        if startsAsVisitor {
            await refreshVisitorHome()
            return
        }

        guard let apiClient else {
            state = .visitor
            return
        }

        state = .loading

        do {
            let home = try await apiClient.todayHome(date: nil)
            guard home.profileCompleted else {
                state = .profileIncomplete(home)
                return
            }

            state = isEmptyHome(home) ? .empty(home) : .loaded(home)
        } catch {
            let appError = AppError(error)
            if case .unauthorized = appError {
                try? await tokenStore?.clearTokens()
                state = .error(appError.errorDescription ?? "登录状态已失效", .login)
                return
            }
            state = .error(appError.errorDescription ?? "首页加载失败，请稍后重试", .retry)
        }
    }
}

private extension HomeViewModel {
    func refreshVisitorHome() async {
        guard let localStore else {
            state = .visitor
            return
        }

        state = .loading

        do {
            let today = Date()
            let profile = try await localStore.localProfile()
            let entries = try await localStore.localDietEntries(date: today)
            let weights = try await localStore.localWeightEntries()
            let home = makeVisitorHome(date: today, profile: profile, entries: entries, weights: weights)

            guard profile != nil else {
                state = .profileIncomplete(home)
                return
            }

            state = .loaded(home)
        } catch {
            state = .error(AppError(error).localizedDescription, .retry)
        }
    }

    func makeVisitorHome(date: Date, profile: UserProfile?, entries: [FoodEntry], weights: [WeightEntry]) -> TodayHome {
        let calorieTarget = profile?.dailyCalorieTargetKcal ?? 0
        let caloriesIn = entries.map(\.totalCaloriesKcal).reduce(0, +)
        let protein = entries.map(\.totalProteinG).reduce(0, +)
        let fat = entries.map(\.totalFatG).reduce(0, +)
        let carbs = entries.map(\.totalCarbsG).reduce(0, +)
        let latestWeight = weights
            .filter { $0.recordDate <= date || Calendar.current.isDate($0.recordDate, inSameDayAs: date) }
            .sorted { $0.recordDate > $1.recordDate }
            .first

        return TodayHome(
            date: date,
            profileCompleted: profile != nil,
            calorieTargetKcal: calorieTarget,
            caloriesInKcal: caloriesIn,
            remainingCaloriesKcal: max(calorieTarget - caloriesIn, 0),
            proteinG: entries.isEmpty ? nil : protein,
            fatG: entries.isEmpty ? nil : fat,
            carbsG: entries.isEmpty ? nil : carbs,
            currentWeightKg: latestWeight?.weightKg ?? profile?.currentWeightKg,
            streakDays: 1,
            reportSummary: nil,
            foodEntries: entries.map { entry in
                FoodEntrySummary(
                    id: entry.id,
                    mealType: entry.mealType,
                    totalCaloriesKcal: entry.totalCaloriesKcal,
                    itemNames: entry.items.map(\.name)
                )
            }
        )
    }

    func isEmptyHome(_ home: TodayHome) -> Bool {
        home.foodEntries.isEmpty
            && home.caloriesInKcal == 0
            && home.currentWeightKg == nil
            && home.reportSummary == nil
    }
}
