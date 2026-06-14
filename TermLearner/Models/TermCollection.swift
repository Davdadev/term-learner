import SwiftData
import Foundation

@Model
final class TermCollection {
    var id: UUID
    var name: String
    var descriptionText: String
    var colorHex: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Term.collection)
    var terms: [Term]

    init(name: String, description: String = "", colorHex: String = "6C63FF") {
        self.id = UUID()
        self.name = name
        self.descriptionText = description
        self.colorHex = colorHex
        self.createdAt = Date()
        self.terms = []
    }

    var learnedCount: Int { terms.filter { $0.isLearned }.count }

    var progress: Double {
        guard !terms.isEmpty else { return 0 }
        return Double(learnedCount) / Double(terms.count)
    }

    var dueCount: Int { terms.filter { $0.isDueForReview }.count }

    var termCount: Int { terms.count }
}
