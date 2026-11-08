import SwiftUI

struct AuthView: View {
    enum Mode: Hashable {
        case signIn, createAccount

        var title: String { self == .signIn ? "Sign In" : "Create Account" }
    }

    private enum Field {
        case email, password, confirm
    }

    let auth: AuthStore

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var errorMessage: String?
    @State private var isBusy = false
    @FocusState private var focus: Field?

    private var isCreating: Bool { mode == .createAccount }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AppBadge(size: 76)

                Text(isCreating ? "Create your account" : "Welcome back")
                    .font(.system(size: 32))
                    .tracking(-0.4)
                    .padding(.top, 22)
                    .contentTransition(.opacity)

                Text(isCreating ? "Your tasks are saved to your account." : "Sign in to see your tasks.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                    .contentTransition(.opacity)

                form
                    .padding(.top, 34)
            }
            .padding(.horizontal, 18)
            .padding(.top, 76)
            .padding(.bottom, 24)
            .animation(.snappy(duration: 0.3), value: mode)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Pearl.page.ignoresSafeArea())
        .onChange(of: mode) {
            errorMessage = nil
            confirm = ""
        }
    }

    private var form: some View {
        VStack(spacing: 10) {
            PearlSegmented(selection: $mode, options: [
                (.signIn, "Sign In"),
                (.createAccount, "Create Account"),
            ])
            .padding(.bottom, 6)

            TextField("Email", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }
                .pearlWell(icon: "envelope.fill")

            SecureField("Password", text: $password)
                .textContentType(isCreating ? .newPassword : .password)
                .focused($focus, equals: .password)
                .submitLabel(isCreating ? .next : .go)
                .onSubmit { isCreating ? (focus = .confirm) : submit() }
                .pearlWell(icon: "lock.fill")

            if isCreating {
                SecureField("Confirm password", text: $confirm)
                    .textContentType(.newPassword)
                    .focused($focus, equals: .confirm)
                    .submitLabel(.go)
                    .onSubmit(submit)
                    .pearlWell(icon: "lock.fill")
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            Button(action: submit) {
                if isBusy {
                    ProgressView().tint(Pearl.onInk)
                } else {
                    Text(mode.title)
                }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(isBusy)
            .padding(.top, 8)
        }
        .padding(18)
        .pearlCard(radius: 30)
    }

    private func submit() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }
        if isCreating && password != confirm {
            errorMessage = "Passwords don't match."
            return
        }

        focus = nil
        errorMessage = nil
        isBusy = true
        Task {
            do {
                if isCreating {
                    try await auth.createAccount(email: cleanEmail, password: password)
                } else {
                    try await auth.signIn(email: cleanEmail, password: password)
                }
                // AuthStore's listener switches to the task list.
            } catch {
                errorMessage = AuthStore.message(for: error)
            }
            isBusy = false
        }
    }
}
