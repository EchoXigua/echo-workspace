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
        self.startsAsVisitor = startsAsVisitor
    }

    private init() {
        self.apiClient = nil
        self.tokenStore = nil
        self.startsAsVisitor = true
    }

    static func visitor() -> ProfileSummaryViewModel {
        ProfileSummaryViewModel()
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
            state = .visitor
            milestoneToPresent = nil
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

            let snapshot = ProfileSummarySnapshot(user: user, profile: profile, streak: streak)
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
}
