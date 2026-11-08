import Foundation
import Observation
import FirebaseFirestore

/// Create, read, update and delete for one user's tasks in Firestore.
@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [TodoTask] = []
    private(set) var isLoading = true
    private(set) var loadError: String?

    @ObservationIgnored private let uid: String
    @ObservationIgnored private var listener: ListenerRegistration?

    init(uid: String) {
        self.uid = uid
    }

    private var collection: CollectionReference {
        Firestore.firestore().collection("users").document(uid).collection("tasks")
    }

    // Read: keeps `tasks` in sync with Firestore, newest first.
    func startListening() {
        guard listener == nil else { return }
        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if let snapshot {
                        self.tasks = snapshot.documents.map { TodoTask(document: $0) }
                        self.loadError = nil
                    } else {
                        self.loadError = "Couldn't load your tasks. Check your connection and open the app again."
                        print("Task listener error:", error?.localizedDescription ?? "unknown")
                    }
                    self.isLoading = false
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // Create
    func add(title: String, description: String) async throws {
        try await collection.addDocument(data: [
            "title": title,
            "description": description,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    // Update
    func update(_ task: TodoTask, title: String, description: String) async throws {
        try await collection.document(task.id).updateData([
            "title": title,
            "description": description,
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    // Delete
    func delete(_ task: TodoTask) async throws {
        try await collection.document(task.id).delete()
    }
}
