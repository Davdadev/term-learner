import Foundation
import WidgetKit

struct WidgetData: Codable {
    var dueCount: Int
    var learnedCount: Int
    var totalCount: Int
    var streak: Int
    var nextDueWord: String?
}

enum WidgetStore {
    static let suiteName = "group.com.termlearner.app"

    static func save(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: "widgetData")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let raw = defaults.data(forKey: "widgetData"),
              let data = try? JSONDecoder().decode(WidgetData.self, from: raw) else {
            return WidgetData(dueCount: 0, learnedCount: 0, totalCount: 0, streak: 0, nextDueWord: nil)
        }
        return data
    }
}
