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

@MainActor
final class AppRouter: ObservableObject {
    @Published var rootState: AppRootState = .coldStart
    @Published var selectedTab: AppTab = .home
    @Published var pendingDietEntryMode: DietEntryLaunchMode?
    @Published var path = NavigationPath()

    func showOnboarding() {
        path = NavigationPath()
        rootState = .onboarding
    }

    func showProfileSetup() {
        path = NavigationPath()
        rootState = .profileSetup
    }

    func showVisitorHome() {
        path = NavigationPath()
        selectedTab = .home
        rootState = .visitorHome
    }

    func showHome() {
        path = NavigationPath()
        selectedTab = .home
        rootState = .home
    }
}
