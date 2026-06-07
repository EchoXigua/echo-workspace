import SwiftUI

struct AppRootView: View {
    let environment: AppEnvironment
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            rootContent
                .navigationBarBackButtonHidden()
        }
        .environment(\.appEnvironment, environment)
        .task {
            await bootstrap()
        }
    }
}

private extension AppRootView {
    @ViewBuilder
    var rootContent: some View {
        switch router.rootState {
        case .coldStart:
            coldStartView
        case .onboarding:
            OnboardingView(
                viewModel: OnboardingViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                onProfileRequired: router.showProfileSetup,
                onCompleted: router.showHome,
                onVisitorPreview: router.showVisitorHome
            )
        case .profileSetup:
            ProfileSetupView(
                viewModel: ProfileSetupViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                onCompleted: router.showHome,
                onAuthExpired: router.showOnboarding
            )
        case .visitorHome:
            MainTabContainerView(
                environment: environment,
                selectedTab: $router.selectedTab,
                isVisitor: true,
                onLoginRequired: router.showOnboarding,
                onProfileRequired: router.showProfileSetup
            )
        case .home:
            MainTabContainerView(
                environment: environment,
                selectedTab: $router.selectedTab,
                isVisitor: false,
                onLoginRequired: router.showOnboarding,
                onProfileRequired: router.showProfileSetup
            )
        }
    }

    var coldStartView: some View {
        VStack {
            LMStateView(
                kind: .loading,
                title: "正在进入 LeanMate",
                message: "正在确认登录和档案状态。"
            )
            .padding(.horizontal, LMSpacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LMColors.background.ignoresSafeArea())
    }

    func bootstrap() async {
        guard router.rootState == .coldStart else {
            return
        }

        do {
            guard try await environment.tokenStore.loadTokens() != nil else {
                router.showOnboarding()
                return
            }

            let user = try await environment.apiClient.currentUser()
            if user.profileCompleted {
                router.showHome()
            } else {
                router.showProfileSetup()
            }
        } catch {
            if case AppError.unauthorized = AppError(error) {
                try? await environment.tokenStore.clearTokens()
            }
            router.showOnboarding()
        }
    }
}

private struct MainTabContainerView: View {
    let environment: AppEnvironment
    @Binding var selectedTab: AppTab
    let isVisitor: Bool
    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void

    var body: some View {
        switch selectedTab {
        case .home:
            HomeView(
                viewModel: isVisitor ? HomeViewModel.visitor() : HomeViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                selectedTab: $selectedTab,
                onLoginRequired: onLoginRequired,
                onProfileRequired: onProfileRequired
            )
        case .record:
            DietEntryView(
                viewModel: DietEntryViewModel(apiClient: environment.apiClient),
                weightViewModel: WeightViewModel(apiClient: environment.apiClient),
                selectedTab: $selectedTab,
                isVisitor: isVisitor,
                onLoginRequired: onLoginRequired
            )
        case .report:
            DailyReportView(
                viewModel: DailyReportViewModel(apiClient: environment.apiClient),
                selectedTab: $selectedTab,
                isVisitor: isVisitor,
                onLoginRequired: onLoginRequired
            )
        case .profile:
            MainTabPlaceholderView(
                selectedTab: $selectedTab,
                title: "我的页后续接入",
                message: "第 3 批不实现我的页和连续打卡里程碑。"
            )
        }
    }
}

private struct MainTabPlaceholderView: View {
    @Binding var selectedTab: AppTab
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                LMStateView(
                    kind: .empty,
                    title: title,
                    message: message,
                    actionTitle: "回到首页",
                    action: { selectedTab = .home }
                )
                .padding(.horizontal, LMSpacing.large)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LMBottomTabs(
                items: AppTab.allCases.map {
                    LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
                },
                selection: $selectedTab
            )
        }
        .background(LMColors.background.ignoresSafeArea())
    }
}
