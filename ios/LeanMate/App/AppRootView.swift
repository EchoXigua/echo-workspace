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
                    localStore: environment.localStore,
                    appleSignInAuthorizer: environment.appleSignInAuthorizer
                ),
                onProfileRequired: router.showProfileSetup,
                onCompleted: router.showHome,
                onVisitorPreview: router.showVisitorHome,
                isLocalDebugLoginEnabled: environment.isLocalDebugLoginEnabled
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
            #if DEBUG
            let resetLocalDataOnLaunch = ProcessInfo.processInfo.arguments.contains("-LeanMateResetLocalDataOnLaunch")
            #else
            let resetLocalDataOnLaunch = false
            #endif

            let rootState = try await AppStartupSessionResolver(
                apiClient: environment.apiClient,
                tokenStore: environment.tokenStore,
                localStore: environment.localStore
            ).resolve(resetLocalDataOnLaunch: resetLocalDataOnLaunch)
            route(to: rootState)
        } catch {
            if case AppError.unauthorized = AppError(error) {
                try? await environment.tokenStore.clearTokens()
            }
            router.showOnboarding()
        }
    }

    func route(to rootState: AppRootState) {
        switch rootState {
        case .coldStart:
            break
        case .onboarding:
            router.showOnboarding()
        case .profileSetup:
            router.showProfileSetup()
        case .visitorHome:
            router.showVisitorHome()
        case .home:
            router.showHome()
        }
    }
}

struct AppStartupSessionResolver {
    let apiClient: any APIClient
    let tokenStore: any TokenStore
    let localStore: any LocalStore

    func resolve(resetLocalDataOnLaunch: Bool = false) async throws -> AppRootState {
        if resetLocalDataOnLaunch {
            try await tokenStore.clearTokens()
            try await localStore.clearAllLocalData()
        }

        guard try await tokenStore.loadTokens() != nil else {
            if try await localStore.guestSession() != nil {
                return .visitorHome
            }
            return .onboarding
        }

        let user = try await apiClient.currentUser()
        return user.profileCompleted ? .home : .profileSetup
    }
}

private struct MainTabContainerView: View {
    let environment: AppEnvironment
    @Binding var selectedTab: AppTab
    @Binding var pendingDietEntryMode: DietEntryLaunchMode?
    @Binding var pendingDietEntryMealType: MealType?
    @State private var recordHidesTabBar = false
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
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                tabContent(.home)
                    .tag(AppTab.home)
                tabContent(.record)
                    .tag(AppTab.record)
                tabContent(.report)
                    .tag(AppTab.report)
                tabContent(.profile)
                    .tag(AppTab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .environment(\.lmTabScreenHidesBottomTabs, true)

            if !hidesBottomTabs {
                LMBottomTabs(
                    items: AppTab.allCases.map {
                        LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
                    },
                    selection: $selectedTab
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(LMColors.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: hidesBottomTabs)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .record {
                recordHidesTabBar = false
            }
        }
    }

    private var hidesBottomTabs: Bool {
        selectedTab == .record && recordHidesTabBar
    }

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
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
                onLoginRequired: onLoginRequired,
                onTabChromeHiddenChange: { recordHidesTabBar = $0 }
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
