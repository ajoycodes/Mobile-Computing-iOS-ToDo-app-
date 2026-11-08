import SwiftUI

struct TaskListView: View {
    let email: String
    let auth: AuthStore

    @State private var store: TaskStore
    @State private var editorTarget: EditorTarget?
    @State private var taskToDelete: TodoTask?
    @State private var actionError: String?

    init(uid: String, email: String, auth: AuthStore) {
        self.email = email
        self.auth = auth
        _store = State(initialValue: TaskStore(uid: uid))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Pearl.page.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                editorTarget = .new
            } label: {
                Label("New Task", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle(fullWidth: false))
            .shadow(color: .black.opacity(0.22), radius: 13, y: 10)
            .padding(.bottom, 6)
        }
        .sheet(item: $editorTarget) { target in
            TaskEditorView(target: target) { title, description in
                switch target {
                case .new:
                    try await store.add(title: title, description: description)
                case .edit(let task):
                    try await store.update(task, title: title, description: description)
                }
            }
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: Binding(get: { taskToDelete != nil }, set: { if !$0 { taskToDelete = nil } }),
            titleVisibility: .visible,
            presenting: taskToDelete
        ) { task in
            Button("Delete Task", role: .destructive) {
                delete(task)
            }
        } message: { task in
            Text("“\(task.title)” will be removed for good.")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } }),
            presenting: actionError
        ) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
        .onAppear { store.startListening() }
        .onDisappear { store.stopListening() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Tasks")
                    .font(.system(size: 34))
                    .tracking(-0.5)
            }
            Spacer()
            Menu {
                Section(email) {
                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        auth.signOut()
                    }
                }
            } label: {
                Text(email.first.map { String($0).uppercased() } ?? "?")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .pearlCard(radius: 21)
            }
            .tint(.primary) // menu labels otherwise take the blue accent colour
            .accessibilityLabel("Account")
        }
        .padding(.horizontal, 6)
        .padding(.top, 10)
        .padding(.bottom, 22)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else if let loadError = store.loadError, store.tasks.isEmpty {
            MessageCard(symbol: "exclamationmark.icloud", title: "Can't load tasks", message: loadError)
        } else if store.tasks.isEmpty {
            MessageCard(symbol: "checklist", title: "No tasks yet", message: "Tap New Task to add your first one.")
        } else {
            LazyVStack(spacing: 12) {
                ForEach(store.tasks) { task in
                    TaskCard(
                        task: task,
                        onEdit: { editorTarget = .edit(task) },
                        onDelete: { taskToDelete = task }
                    )
                }
            }
            Text(store.tasks.count == 1 ? "1 task" : "\(store.tasks.count) tasks")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
    }

    private func delete(_ task: TodoTask) {
        Task {
            do {
                try await store.delete(task)
            } catch {
                actionError = "Couldn't delete the task. Please try again."
            }
        }
    }
}

// MARK: - Pieces

/// One task: title, description, when it was added or edited, and a ••• menu.
private struct TaskCard: View {
    let task: TodoTask
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(task.title)
                .font(.headline)
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.top, 5)
            }
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                    Text(task.timeLabel)
                }
                .font(.footnote)
                .foregroundStyle(.tertiary)
                Spacer()
                Menu {
                    actions
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Pearl.well, in: Circle())
                }
                .tint(.secondary)
                .accessibilityLabel("More")
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .pearlCard()
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Pearl.cardRadius, style: .continuous))
        .onTapGesture(perform: onEdit)
        .contextMenu { actions }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Edit", onEdit)
        .accessibilityAction(named: "Delete", onDelete)
    }

    @ViewBuilder
    private var actions: some View {
        Button("Edit", systemImage: "pencil", action: onEdit)
        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
    }
}

/// A card with a symbol and a short message, for the empty and error states.
private struct MessageCard: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 4)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 24)
        .pearlCard()
    }
}
