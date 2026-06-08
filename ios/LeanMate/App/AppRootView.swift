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
                pendingDietEntryMode: $router.pendingDietEntryMode,
                isVisitor: true,
                onLoginRequired: router.showOnboarding,
                onProfileRequired: router.showProfileSetup
            )
        case .home:
            MainTabContainerView(
                environment: environment,
                selectedTab: $router.selectedTab,
                pendingDietEntryMode: $router.pendingDietEntryMode,
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
    @Binding var pendingDietEntryMode: DietEntryLaunchMode?
    let isVisitor: Bool
    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void

    var body: some View {
        switch selectedTab {
        case .home:
            HomeView(
                viewModel: isVisitor ? HomeViewModel.visitor(localStore: environment.localStore) : HomeViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                selectedTab: $selectedTab,
                pendingDietEntryMode: $pendingDietEntryMode,
                isVisitor: isVisitor,
                onLoginRequired: onLoginRequired,
                onProfileRequired: onProfileRequired
            )
        case .record:
            DietEntryView(
                viewModel: DietEntryViewModel(
                    apiClient: environment.apiClient,
                    localStore: environment.localStore,
                    savesLocally: isVisitor
                ),
                weightViewModel: WeightViewModel(apiClient: environment.apiClient),
                selectedTab: $selectedTab,
                pendingLaunchMode: $pendingDietEntryMode,
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
            ProfileSummaryView(
                viewModel: isVisitor ? ProfileSummaryViewModel.visitor() : ProfileSummaryViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                selectedTab: $selectedTab,
                onLoginRequired: onLoginRequired,
                onProfileRequired: onProfileRequired
            )
        }
    }
}
