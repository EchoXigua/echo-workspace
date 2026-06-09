import SwiftUI

struct AppRootView: View {
    let environment: AppEnvironment
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            rootContent
                .navigationBarBackButtonHidden()
                .navigationDestination(for: AppRoute.self) { route in
                    routeDestination(route)
                        .navigationBarBackButtonHidden()
                }
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
                    tokenStore: environment.tokenStore,
                    localStore: environment.localStore
                ),
                onProfileRequired: router.showProfileSetup,
                onCompleted: router.showHome,
                onVisitorPreview: router.showVisitorHome
            )
        case .profileSetup:
            ProfileSetupView(
                viewModel: ProfileSetupViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore,
                    localStore: environment.localStore,
                    savesLocally: router.profileSetupIsVisitor
                ),
                onCompleted: router.profileSetupIsVisitor ? router.showVisitorHome : router.showHome,
                onAuthExpired: router.showOnboarding,
                onSkipped: router.profileSetupIsVisitor ? router.showVisitorHome : router.showHome
            )
        case .visitorHome:
            MainTabContainerView(
                environment: environment,
                selectedTab: $router.selectedTab,
                pendingDietEntryMode: $router.pendingDietEntryMode,
                pendingDietEntryMealType: $router.pendingDietEntryMealType,
                isVisitor: true,
                reloadKey: router.contentReloadKey,
                onLoginRequired: router.showOnboarding,
                onProfileRequired: router.showProfileSetupRoute,
                onOpenProfileSettings: router.showProfileSettings,
                onOpenProfileEdit: router.showProfileEdit,
                onOpenProfileDataPlan: router.showProfileDataPlan,
                onOpenProfileWeightTrend: router.showProfileWeightTrend,
                onOpenProfileDataSync: router.showProfileDataSync
            )
        case .home:
            MainTabContainerView(
                environment: environment,
                selectedTab: $router.selectedTab,
                pendingDietEntryMode: $router.pendingDietEntryMode,
                pendingDietEntryMealType: $router.pendingDietEntryMealType,
                isVisitor: false,
                reloadKey: router.contentReloadKey,
                onLoginRequired: router.showOnboarding,
                onProfileRequired: router.showProfileSetupRoute,
                onOpenProfileSettings: router.showProfileSettings,
                onOpenProfileEdit: router.showProfileEdit,
                onOpenProfileDataPlan: router.showProfileDataPlan,
                onOpenProfileWeightTrend: router.showProfileWeightTrend,
                onOpenProfileDataSync: router.showProfileDataSync
            )
        }
    }

    @ViewBuilder
    func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .profileSetup:
            ProfileSetupView(
                viewModel: ProfileSetupViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore,
                    localStore: environment.localStore,
                    savesLocally: router.rootState == .visitorHome
                ),
                onCompleted: router.completeProfileSetupRoute,
                onAuthExpired: router.showOnboarding,
                onSkipped: router.popRoute,
                usesBackButtonIcon: true
            )
        case .profileSettings(let payload):
            ProfileSettingsView(
                payload: payload,
                isVisitor: router.rootState == .visitorHome,
                onBack: router.popRoute,
                onLoginRequired: router.showOnboarding,
                onNavigate: { router.path.append($0) }
            )
        case .profileEdit:
            ProfileEditView(
                viewModel: ProfileSetupViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore,
                    localStore: environment.localStore,
                    savesLocally: router.rootState == .visitorHome
                ),
                onBack: router.popRoute,
                onCompleted: router.completeProfileSetupRoute,
                onAuthExpired: router.showOnboarding
            )
        case .profileDataPlan(let payload):
            ProfileDataPlanDetailView(
                payload: payload,
                onBack: router.popRoute,
                onEditProfile: { router.showProfileEdit(payload) }
            )
        case .profileWeightTrend(let payload):
            ProfileWeightTrendView(
                payload: payload,
                weightViewModel: WeightViewModel(
                    apiClient: environment.apiClient,
                    localStore: environment.localStore,
                    savesLocally: router.rootState == .visitorHome
                ),
                onBack: router.popRoute
            )
        case .profileDataSync:
            ProfileDataSyncView(
                isVisitor: router.rootState == .visitorHome,
                onBack: router.popRoute,
                onLoginRequired: router.showOnboarding
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
                if try await environment.localStore.guestSession() != nil {
                    router.showVisitorHome()
                } else {
                    router.showOnboarding()
                }
                return
            }

            _ = try await environment.apiClient.currentUser()
            router.showHome()
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
    @Binding var pendingDietEntryMealType: MealType?
    let isVisitor: Bool
    let reloadKey: Int
    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void
    let onOpenProfileSettings: (ProfileRoutePayload?) -> Void
    let onOpenProfileEdit: (ProfileRoutePayload) -> Void
    let onOpenProfileDataPlan: (ProfileRoutePayload) -> Void
    let onOpenProfileWeightTrend: (ProfileRoutePayload) -> Void
    let onOpenProfileDataSync: () -> Void

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
                pendingDietEntryMealType: $pendingDietEntryMealType,
                isVisitor: isVisitor,
                onLoginRequired: onLoginRequired,
                onProfileRequired: onProfileRequired
            )
            .id(reloadKey)
        case .record:
            DietEntryView(
                viewModel: DietEntryViewModel(
                    apiClient: environment.apiClient,
                    localStore: environment.localStore,
                    savesLocally: isVisitor
                ),
                weightViewModel: WeightViewModel(
                    apiClient: environment.apiClient,
                    localStore: environment.localStore,
                    savesLocally: isVisitor
                ),
                selectedTab: $selectedTab,
                pendingLaunchMode: $pendingDietEntryMode,
                pendingLaunchMealType: $pendingDietEntryMealType,
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
                viewModel: isVisitor ? ProfileSummaryViewModel.visitor(localStore: environment.localStore) : ProfileSummaryViewModel(
                    apiClient: environment.apiClient,
                    tokenStore: environment.tokenStore
                ),
                weightViewModel: WeightViewModel(
                    apiClient: environment.apiClient,
                    localStore: environment.localStore,
                    savesLocally: isVisitor
                ),
                selectedTab: $selectedTab,
                onLoginRequired: onLoginRequired,
                onProfileRequired: onProfileRequired,
                onOpenSettings: onOpenProfileSettings,
                onOpenDataPlan: onOpenProfileDataPlan,
                onOpenProfileEdit: onOpenProfileEdit,
                onOpenWeightTrend: onOpenProfileWeightTrend,
                onOpenDataSync: onOpenProfileDataSync,
                onDebugClearLocalData: debugClearLocalData
            )
            .id(reloadKey)
        }
    }

    #if DEBUG
    func debugClearLocalData() async throws {
        try await environment.localStore.clearAllLocalData()
        try await environment.tokenStore.clearTokens()
        await MainActor.run {
            onLoginRequired()
        }
    }
    #else
    var debugClearLocalData: (() async throws -> Void)? {
        nil
    }
    #endif
}
