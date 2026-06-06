import SwiftUI

struct AppRootView: View {
    let environment: AppEnvironment
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            InfrastructurePreviewView(selectedTab: $router.selectedTab)
                .navigationBarBackButtonHidden()
        }
        .environment(\.appEnvironment, environment)
    }
}
