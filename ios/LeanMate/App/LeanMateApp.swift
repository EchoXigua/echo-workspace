import SwiftUI

@main
struct LeanMateApp: App {
    private let environment = AppEnvironment.configured()

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}
