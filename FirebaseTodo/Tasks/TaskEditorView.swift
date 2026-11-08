import SwiftUI

/// What the editor sheet is for: a new task or an existing one.
enum EditorTarget: Identifiable {
    case new
    case edit(TodoTask)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let task): task.id
        }
    }
}

/// Title + description form, used for both adding and editing.
struct TaskEditorView: View {
    let target: EditorTarget
    let onSave: (_ title: String, _ description: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var titleFocused: Bool

    init(target: EditorTarget, onSave: @escaping (String, String) async throws -> Void) {
        self.target = target
        self.onSave = onSave
        if case .edit(let task) = target {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
        } else {
            _title = State(initialValue: "")
            _description = State(initialValue: "")
        }
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
    }

    private var cleanTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What needs doing?", text: $title)
                        .focused($titleFocused)
                        .submitLabel(.done)
                }
                Section("Description") {
                    TextField("Add details (optional)", text: $description, axis: .vertical)
                        .lineLimit(4...12)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isNew ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(isNew ? "Add" : "Save", action: save)
                            .fontWeight(.semibold)
                            .disabled(cleanTitle.isEmpty)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onChange(of: title) { _, newValue in
                if newValue.count > TodoTask.titleLimit { title = String(newValue.prefix(TodoTask.titleLimit)) }
            }
            .onChange(of: description) { _, newValue in
                if newValue.count > TodoTask.descriptionLimit { description = String(newValue.prefix(TodoTask.descriptionLimit)) }
            }
            .onAppear {
                if isNew { titleFocused = true }
            }
        }
    }

    private func save() {
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await onSave(cleanTitle, cleanDescription)
                dismiss()
            } catch {
                errorMessage = "Couldn't save the task. Please try again."
                isSaving = false
            }
        }
    }
}
