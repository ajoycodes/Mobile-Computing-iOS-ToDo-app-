import SwiftUI

struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign in"
        case createAccount = "Create account"
        var id: Self { self }
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
            VStack(spacing: 28) {
                header

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .fieldStyle()

                    SecureField("Password", text: $password)
                        .textContentType(isCreating ? .newPassword : .password)
                        .focused($focus, equals: .password)
                        .submitLabel(isCreating ? .next : .go)
                        .onSubmit { isCreating ? (focus = .confirm) : submit() }
                        .fieldStyle()

                    if isCreating {
                        SecureField("Confirm password", text: $confirm)
                            .textContentType(.newPassword)
                            .focused($focus, equals: .confirm)
                            .submitLabel(.go)
                            .onSubmit(submit)
                            .fieldStyle()
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: submit) {
                    Group {
                        if isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text(mode.rawValue).fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(isBusy)
            }
            .padding(.horizontal, 24)
            .padding(.top, 72)
            .padding(.bottom, 24)
            .animation(.snappy, value: mode)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .onChange(of: mode) {
            errorMessage = nil
            confirm = ""
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.bottom, 6)
            Text("Todo")
                .font(.largeTitle.bold())
            Text(isCreating ? "Create an account to save your tasks." : "Sign in to see your tasks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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

private extension View {
    func fieldStyle() -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
