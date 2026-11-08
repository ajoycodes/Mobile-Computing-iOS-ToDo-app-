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
        NavigationStack {
            content
                .navigationTitle("Tasks")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Text(email)
                            Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                                auth.signOut()
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        .accessibilityLabel("Account")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New Task", systemImage: "plus") {
                            editorTarget = .new
                        }
                    }
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
        }
        .onAppear { store.startListening() }
        .onDisappear { store.stopListening() }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView()
        } else if let loadError = store.loadError, store.tasks.isEmpty {
            ContentUnavailableView("Can't Load Tasks", systemImage: "exclamationmark.icloud", description: Text(loadError))
        } else if store.tasks.isEmpty {
            ContentUnavailableView {
                Label("No Tasks Yet", systemImage: "checklist")
            } description: {
                Text("Tap + to add your first task.")
            }
        } else {
            List {
                Section {
                    ForEach(store.tasks) { task in
                        Button {
                            editorTarget = .edit(task)
                        } label: {
                            TaskRow(task: task)
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", systemImage: "trash") {
                                taskToDelete = task
                            }
                            .tint(.red)
                            Button("Edit", systemImage: "pencil") {
                                editorTarget = .edit(task)
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { editorTarget = .edit(task) }
                            Button("Delete", systemImage: "trash", role: .destructive) { taskToDelete = task }
                        }
                    }
                } footer: {
                    Text(store.tasks.count == 1 ? "1 task" : "\(store.tasks.count) tasks")
                }
            }
            .listStyle(.insetGrouped)
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

private struct TaskRow: View {
    let task: TodoTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Text(task.timeLabel)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
