import Foundation
import Combine

enum ProfileSummaryState {
    case idle
    case loading
    case visitor
    case profileIncomplete
    case loaded(ProfileSummarySnapshot)
    case error(String, ProfileSummaryRecovery)
}

enum ProfileSummaryRecovery: Equatable {
    case retry
    case login
}

struct ProfileSummarySnapshot: Sendable {
    let user: CurrentUser
    let profile: UserProfile
    let streak: Streak
    let weeklyWeightChangeKg: Double?

    var displayName: String {
        let name = user.nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else {
            return "LeanMate 用户"
        }
        return name
    }
}

@MainActor
final class ProfileSummaryViewModel: ObservableObject {
    private let apiClient: (any APIClient)?
    private let tokenStore: (any TokenStore)?
    private let localStore: (any LocalStore)?
    private let startsAsVisitor: Bool
    private var shownMilestoneDays: Set<Int> = []

    @Published private(set) var state: ProfileSummaryState = .idle
    @Published private(set) var milestoneToPresent: StreakMilestone?

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
        self.localStore = nil
        self.startsAsVisitor = startsAsVisitor
    }

    private init(localStore: any LocalStore) {
        self.apiClient = nil
        self.tokenStore = nil
        self.localStore = localStore
        self.startsAsVisitor = true
    }

    static func visitor(localStore: any LocalStore) -> ProfileSummaryViewModel {
        ProfileSummaryViewModel(localStore: localStore)
    }

    func load() async {
        guard case .idle = state else {
            return
        }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else {
            return
        }

        if startsAsVisitor {
            await refreshVisitorProfile()
            return
        }

        guard let apiClient else {
            state = .visitor
            milestoneToPresent = nil
            return
        }

        state = .loading

        do {
            async let userRequest = apiClient.currentUser()
            async let profileRequest = apiClient.profile()
            async let streakRequest = apiClient.streak()
            let (user, payload, streak) = try await (userRequest, profileRequest, streakRequest)

            guard user.profileCompleted, payload.profileCompleted, let profile = payload.profile else {
                state = .profileIncomplete
                milestoneToPresent = nil
                return
            }

            let weeklyWeightChange = await loadRemoteWeeklyWeightChange(apiClient: apiClient)
            let snapshot = ProfileSummarySnapshot(
                user: user,
                profile: profile,
                streak: streak,
                weeklyWeightChangeKg: weeklyWeightChange
            )
            state = .loaded(snapshot)
            presentMilestoneIfNeeded(from: streak)
        } catch {
            let appError = AppError(error)
            if case .unauthorized = appError {
                try? await tokenStore?.clearTokens()
                state = .error(appError.errorDescription ?? "登录状态已失效", .login)
                milestoneToPresent = nil
                return
            }
            state = .error(appError.errorDescription ?? "我的页加载失败，请稍后重试", .retry)
            milestoneToPresent = nil
        }
    }

    func dismissMilestone() {
        if let days = milestoneToPresent?.days {
            shownMilestoneDays.insert(days)
        }
        milestoneToPresent = nil
    }
}

private extension ProfileSummaryViewModel {
    func refreshVisitorProfile() async {
        guard let localStore else {
            state = .visitor
            milestoneToPresent = nil
            return
        }

        state = .loading

        do {
            guard let profile = try await localStore.localProfile() else {
                state = .profileIncomplete
                milestoneToPresent = nil
                return
            }

            let weights = try await localStore.localWeightEntries()
            let user = CurrentUser(
                id: UUID(),
                nickname: "我的档案",
                avatarUrl: nil,
                status: .active,
                profileCompleted: true,
                createdAt: Date()
            )
            state = .loaded(
                ProfileSummarySnapshot(
                    user: user,
                    profile: profile,
                    streak: Streak(currentDays: 0, longestDays: 0, lastActiveDate: nil, milestones: []),
                    weeklyWeightChangeKg: weeklyWeightChange(from: weights)
                )
            )
            milestoneToPresent = nil
        } catch {
            state = .error(AppError(error).localizedDescription, .retry)
            milestoneToPresent = nil
        }
    }

    func presentMilestoneIfNeeded(from streak: Streak) {
        guard milestoneToPresent == nil else {
            return
        }

        let achievedMilestones = streak.milestones
            .filter({ $0.achieved })
            .sorted { $0.days > $1.days }

        guard let milestone = achievedMilestones.first, !shownMilestoneDays.contains(milestone.days) else {
            milestoneToPresent = nil
            return
        }

        milestoneToPresent = milestone
    }

    func loadRemoteWeeklyWeightChange(apiClient: any APIClient) async -> Double? {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        do {
            let weights = try await apiClient.weightEntries(startDate: startDate, endDate: today)
            return weeklyWeightChange(from: weights)
        } catch {
            return nil
        }
    }

    func weeklyWeightChange(from entries: [WeightEntry]) -> Double? {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recentEntries = entries
            .filter { entry in
                (entry.recordDate >= startDate && entry.recordDate <= today)
                    || calendar.isDate(entry.recordDate, inSameDayAs: today)
            }
            .sorted { $0.recordDate < $1.recordDate }

        guard let first = recentEntries.first, let last = recentEntries.last, first.id != last.id else {
            return nil
        }
        return last.weightKg - first.weightKg
    }
}
