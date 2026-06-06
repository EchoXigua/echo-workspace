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
            HomeView(
                viewModel: HomeViewModel.visitor(),
                selectedTab: $router.selectedTab,
                onLoginRequired: router.showOnboarding,
                onProfileRequired: router.showProfileSetup
            )
        case .home:
            HomeView(
                viewModel: HomeViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                selectedTab: $router.selectedTab,
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
