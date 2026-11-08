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

/// Title + description sheet, used for both adding and editing.
struct TaskEditorView: View {
    let target: EditorTarget
    let onSave: (_ title: String, _ description: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    private enum Field {
        case title, description
    }

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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(isNew ? "New task" : "Edit task")
                        .font(.system(size: 26))
                        .tracking(-0.4)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Pearl.well, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .accessibilityLabel("Close")
                }

                FieldLabel("Title")
                    .padding(.top, 22)
                TextField("What needs doing?", text: $title)
                    .focused($focus, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focus = .description }
                    .pearlWell()

                FieldLabel("Description")
                    .padding(.top, 16)
                TextField("Add details (optional)", text: $description, axis: .vertical)
                    .focused($focus, equals: .description)
                    .lineLimit(4...8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(minHeight: 116, alignment: .topLeading)
                    .background(Pearl.well, in: RoundedRectangle(cornerRadius: Pearl.wellRadius, style: .continuous))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, 12)
                        .padding(.leading, 4)
                }

                Button(action: save) {
                    if isSaving {
                        ProgressView().tint(Pearl.onInk)
                    } else {
                        Text(isNew ? "Add Task" : "Save Changes")
                    }
                }
                .buttonStyle(InkButtonStyle())
                .disabled(cleanTitle.isEmpty || isSaving)
                .padding(.top, 22)
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.height(470), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Pearl.card)
        .presentationCornerRadius(40)
        .interactiveDismissDisabled(isSaving)
        .onChange(of: title) { _, newValue in
            if newValue.count > TodoTask.titleLimit { title = String(newValue.prefix(TodoTask.titleLimit)) }
        }
        .onChange(of: description) { _, newValue in
            if newValue.count > TodoTask.descriptionLimit { description = String(newValue.prefix(TodoTask.descriptionLimit)) }
        }
        .onAppear {
            if isNew { focus = .title }
        }
    }

    private func save() {
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        focus = nil
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
