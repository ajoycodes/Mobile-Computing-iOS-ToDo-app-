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

    /// "2h ago", "yesterday", or "Edited 5m ago" once the task has been changed.
    var timeLabel: String {
        guard let createdAt else { return "" }
        if let updatedAt, updatedAt.timeIntervalSince(createdAt) > 1 {
            return "Edited \(Self.relative.localizedString(for: updatedAt, relativeTo: .now))"
        }
        return Self.relative.localizedString(for: createdAt, relativeTo: .now)
    }

    private static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        return formatter
    }()
}
