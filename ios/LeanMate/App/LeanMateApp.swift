import SwiftUI

@main
struct LeanMateApp: App {
    private let environment = AppEnvironment.mock

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}
