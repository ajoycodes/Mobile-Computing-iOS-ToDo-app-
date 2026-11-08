import SwiftUI

@main
struct FirebaseTodoApp: App {
    private let firebase: FirebaseSetup.Mode

    init() {
        firebase = FirebaseSetup.configure()
    }

    var body: some Scene {
        WindowGroup {
            if firebase == .notConfigured {
                SetupNeededView()
            } else {
                RootView()
            }
        }
    }
}
