import Foundation
import Combine

enum HomeState {
    case idle
    case loading
    case visitor
    case profileIncomplete
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
        startsAsVisitor: Bool = false
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.startsAsVisitor = startsAsVisitor
    }

    private init() {
        self.apiClient = nil
        self.tokenStore = nil
        self.startsAsVisitor = true
    }

    static func visitor() -> HomeViewModel {
        HomeViewModel()
    }

    func load() async {
        guard case .idle = state else {
            return
        }
        await refresh()
    }

    func refresh() async {
        if startsAsVisitor {
            state = .visitor
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
                state = .profileIncomplete
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
    func isEmptyHome(_ home: TodayHome) -> Bool {
        home.foodEntries.isEmpty
            && home.caloriesInKcal == 0
            && home.currentWeightKg == nil
            && home.reportSummary == nil
    }
}
