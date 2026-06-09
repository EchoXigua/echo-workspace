import SwiftUI

enum AppRootState: Equatable {
    case coldStart
    case onboarding
    case profileSetup
    case visitorHome
    case home
}

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case record
    case report
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "首页"
        case .record:
            "记录"
        case .report:
            "日报"
        case .profile:
            "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .record:
            "plus"
        case .report:
            "sparkles"
        case .profile:
            "person"
        }
    }
}

enum DietEntryLaunchMode: Equatable {
    case photo
    case text
    case manual
}

struct ProfileRoutePayload: Hashable {
    let displayName: String
    let summary: String
    let currentWeight: String
    let targetWeight: String
    let height: String
    let bmi: String
    let bmr: String
    let dailyTarget: String
    let activityLevel: String
}

enum AppRoute: Hashable {
    case profileSetup
    case profileDataPlan(ProfileRoutePayload)
    case profileWeightTrend(ProfileRoutePayload)
    case profileDataSync
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var rootState: AppRootState = .coldStart
    @Published var selectedTab: AppTab = .home
    @Published var pendingDietEntryMode: DietEntryLaunchMode?
    @Published var pendingDietEntryMealType: MealType?
    @Published var path: [AppRoute] = []
    @Published var profileSetupIsVisitor = false
    @Published var contentReloadKey = 0

    func showOnboarding() {
        path = []
        profileSetupIsVisitor = false
        rootState = .onboarding
    }

    func showProfileSetup() {
        path = []
        profileSetupIsVisitor = false
        rootState = .profileSetup
    }

    func showVisitorProfileSetup() {
        path = []
        profileSetupIsVisitor = true
        rootState = .profileSetup
    }

    func showVisitorHome() {
        path = []
        selectedTab = .home
        profileSetupIsVisitor = false
        rootState = .visitorHome
    }

    func showHome() {
        path = []
        selectedTab = .home
        profileSetupIsVisitor = false
        rootState = .home
    }

    func showProfileSetupRoute() {
        path.append(.profileSetup)
    }

    func showProfileDataPlan(_ payload: ProfileRoutePayload) {
        path.append(.profileDataPlan(payload))
    }

    func showProfileWeightTrend(_ payload: ProfileRoutePayload) {
        path.append(.profileWeightTrend(payload))
    }

    func showProfileDataSync() {
        path.append(.profileDataSync)
    }

    func popRoute() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }

    func completeProfileSetupRoute() {
        popRoute()
        contentReloadKey += 1
    }
}
