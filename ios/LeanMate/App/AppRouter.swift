import SwiftUI

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

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var path = NavigationPath()
}
