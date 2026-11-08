import Foundation
import Observation
import FirebaseAuth

/// Keeps track of the signed-in user and wraps Firebase email/password auth.
@MainActor
@Observable
final class AuthStore {
    private(set) var user: User?
    private(set) var isChecking = true

    @ObservationIgnored private var handle: AuthStateDidChangeListenerHandle?

    init() {
        // Fires right away with the saved session (if any), then on every sign-in and sign-out.
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            MainActor.assumeIsolated {
                self?.user = user
                self?.isChecking = false
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func createAccount(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    /// Turns a Firebase Auth error into a sentence for the user.
    static func message(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: nsError.code) else {
            return "Something went wrong. Please try again."
        }
        switch code {
        case .invalidEmail:
            return "That email address isn't valid."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Sign in instead."
        case .invalidCredential, .wrongPassword, .userNotFound:
            return "Email or password is incorrect."
        case .tooManyRequests:
            return "Too many attempts. Try again in a few minutes."
        case .networkError:
            return "Can't reach Firebase. Check your connection."
        case .operationNotAllowed:
            return "Email/password sign-in is turned off. Enable it in Firebase console → Authentication → Sign-in method."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
