import SwiftData
import Foundation

@Model
final class Term {
    var id: UUID
    var word: String
    var definition: String
    var notes: String
    var masteryLevel: Int        // 0–5 (spaced repetition)
    var nextReviewDate: Date
    var timesCorrect: Int
    var timesIncorrect: Int
    var createdAt: Date
    var imageData: Data?
    var collection: TermCollection?

    init(word: String, definition: String, notes: String = "", imageData: Data? = nil) {
        self.id = UUID()
        self.word = word
        self.definition = definition
        self.notes = notes
        self.masteryLevel = 0
        self.nextReviewDate = Date()
        self.timesCorrect = 0
        self.timesIncorrect = 0
        self.createdAt = Date()
        self.imageData = imageData
    }

    var accuracyPercentage: Double {
        let total = timesCorrect + timesIncorrect
        guard total > 0 else { return 0 }
        return Double(timesCorrect) / Double(total) * 100
    }

    var isLearned: Bool { masteryLevel >= 4 }

    var isDueForReview: Bool { nextReviewDate <= Date() }

    var masteryLabel: String {
        switch masteryLevel {
        case 0: return "New"
        case 1: return "Learning"
        case 2: return "Familiar"
        case 3: return "Practiced"
        case 4: return "Mastered"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }

    // SM-2 spaced repetition scheduling
    func recordReview(correct: Bool) {
        if correct {
            timesCorrect += 1
            masteryLevel = min(5, masteryLevel + 1)
            let days = [1, 3, 7, 14, 30, 60][min(masteryLevel, 5)]
            nextReviewDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        } else {
            timesIncorrect += 1
            masteryLevel = max(0, masteryLevel - 1)
            nextReviewDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        }
    }
}
