import WidgetKit
import SwiftUI

// MARK: - Shared data (mirrors _WidgetData/_WidgetStore in the main app target)

private struct __WidgetData: Codable {
    var dueCount: Int
    var learnedCount: Int
    var totalCount: Int
    var streak: Int
    var nextDueWord: String?
}

private enum __WidgetStore {
    static let suiteName = "group.com.termlearner.app"

    static func load() -> __WidgetData {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let raw = defaults.data(forKey: "widgetData"),
              let data = try? JSONDecoder().decode(__WidgetData.self, from: raw) else {
            return __WidgetData(dueCount: 0, learnedCount: 0, totalCount: 0, streak: 0, nextDueWord: nil)
        }
        return data
    }
}

// MARK: - Timeline Provider

struct TermLearnerEntry: TimelineEntry {
    let date: Date
    let data: _WidgetData
}

struct TermLearnerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TermLearnerEntry {
        TermLearnerEntry(date: Date(), data: _WidgetData(dueCount: 5, learnedCount: 12, totalCount: 30, streak: 3, nextDueWord: "ephemeral"))
    }

    func getSnapshot(in context: Context, completion: @escaping (TermLearnerEntry) -> Void) {
        completion(TermLearnerEntry(date: Date(), data: _WidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TermLearnerEntry>) -> Void) {
        let entry = TermLearnerEntry(date: Date(), data: _WidgetStore.load())
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TermLearnerEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "6C63FF"), Color(hex: "8B85FF")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if entry.data.streak > 0 {
                        Label("\(entry.data.streak)", systemImage: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                Spacer()

                Text("\(entry.data.dueCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)

                Text(entry.data.dueCount == 1 ? "term due" : "terms due")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                if let word = entry.data.nextDueWord {
                    Text("Next: \(word)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TermLearnerEntry

    var body: some View {
        ZStack {
            Color(hex: "F8F9FA")

            HStack(spacing: 0) {
                // Left — due count
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "6C63FF"), Color(hex: "8B85FF")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    VStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(entry.data.dueCount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Due")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity)

                // Right — stats grid
                VStack(alignment: .leading, spacing: 10) {
                    statRow(icon: "checkmark.seal.fill", color: Color(hex: "43C6AC"),
                            value: "\(entry.data.learnedCount)", label: "Mastered")
                    statRow(icon: "text.book.closed.fill", color: Color(hex: "6C63FF"),
                            value: "\(entry.data.totalCount)", label: "Total")
                    statRow(icon: "flame.fill", color: Color(hex: "FF6584"),
                            value: "\(entry.data.streak)", label: "Streak")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private func statRow(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(label)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Widget Bundle

struct TermLearnerWidget: Widget {
    let kind = "TermLearnerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TermLearnerProvider()) { entry in
            Group {
                if entry.configuration is SmallWidgetView { EmptyView() }
            }
        }
        .configurationDisplayName("Term Learner")
        .description("See how many terms are due for review.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct TermLearnerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TermLearnerSmallWidget()
        TermLearnerMediumWidget()
    }
}

struct TermLearnerSmallWidget: Widget {
    let kind = "TermLearnerSmall"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TermLearnerProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(
                    LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "8B85FF")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    for: .widget
                )
        }
        .configurationDisplayName("Term Learner")
        .description("Daily due count and streak.")
        .supportedFamilies([.systemSmall])
    }
}

struct TermLearnerMediumWidget: Widget {
    let kind = "TermLearnerMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TermLearnerProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(Color(hex: "F8F9FA"), for: .widget)
        }
        .configurationDisplayName("Term Learner Stats")
        .description("Due terms, mastered count, and streak.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Color extension (duplicated here — widget target can't import main app)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
