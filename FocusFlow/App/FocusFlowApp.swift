import SwiftUI

@main
struct FocusFlowApp: App {
    @State private var app = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(app)
        } label: {
            MenuBarLabel(app: app)
        }
        .menuBarExtraStyle(.window)
    }
}
