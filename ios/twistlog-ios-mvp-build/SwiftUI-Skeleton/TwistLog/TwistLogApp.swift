import SwiftUI

@main
struct TwistLogApp: App {
    @StateObject private var store = AppStore.preview

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

