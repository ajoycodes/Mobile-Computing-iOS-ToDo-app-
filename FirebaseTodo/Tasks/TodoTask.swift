import Foundation
import FirebaseFirestore

/// One task, stored at users/{uid}/tasks/{id}.
struct TodoTask: Identifiable, Equatable {
    static let titleLimit = 100
    static let descriptionLimit = 1000

    let id: String
    var title: String
    var description: String
    var createdAt: Date?
    var updatedAt: Date?

    init(document: QueryDocumentSnapshot) {
        // .estimate fills in a local time while the server timestamp is still on its way.
        let data = document.data(with: .estimate)
        id = document.documentID
        title = data["title"] as? String ?? ""
        description = data["description"] as? String ?? ""
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
    }

    /// "Added Nov 8, 3:12 PM" or "Edited Nov 8, 3:40 PM".
    var timeLabel: String {
        guard let createdAt else { return "" }
        if let updatedAt, updatedAt.timeIntervalSince(createdAt) > 1 {
            return "Edited \(updatedAt.formatted(date: .abbreviated, time: .shortened))"
        }
        return "Added \(createdAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
