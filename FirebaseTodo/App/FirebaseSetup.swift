import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Starts Firebase once at launch.
///
/// - Normal runs read `GoogleService-Info.plist` (downloaded from the Firebase console).
/// - Runs with the `-useEmulators` launch argument talk to the local Firebase emulators
///   (`firebase emulators:start`), so no real project is needed.
enum FirebaseSetup {
    enum Mode {
        case live
        case emulators
        case notConfigured
    }

    static func configure() -> Mode {
        if ProcessInfo.processInfo.arguments.contains("-useEmulators") {
            configureForEmulators()
            return .emulators
        }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return .notConfigured
        }
        FirebaseApp.configure()
        return .live
    }

    private static func configureForEmulators() {
        // Placeholder values: the emulators accept any project whose id starts with "demo-".
        let options = FirebaseOptions(googleAppID: "1:1234567890:ios:0123456789abcdef", gcmSenderID: "1234567890")
        options.apiKey = "AIza" + String(repeating: "0", count: 35)
        options.projectID = "demo-todo"
        FirebaseApp.configure(options: options)

        Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)

        // The emulator speaks plain HTTP, so SSL is off. Memory cache keeps old emulator
        // data from showing up after the emulators restart.
        let db = Firestore.firestore()
        let settings = db.settings
        settings.host = "127.0.0.1:8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
    }
}
