import SwiftUI

/// Shows the sign-in screen or the task list, depending on who is signed in.
struct RootView: View {
    @State private var auth = AuthStore()

    var body: some View {
        Group {
            if auth.isChecking {
                ProgressView()
            } else if let user = auth.user {
                TaskListView(uid: user.uid, email: user.email ?? "", auth: auth)
                    .id(user.uid)
            } else {
                AuthView(auth: auth)
            }
        }
        .animation(.default, value: auth.user?.uid)
    }
}

/// Shown when GoogleService-Info.plist hasn't been added to the project yet.
struct SetupNeededView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Connect Firebase", systemImage: "flame")
        } description: {
            Text("Add GoogleService-Info.plist to the FirebaseTodo folder, then build and run again.")
        }
    }
}
