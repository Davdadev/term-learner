import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query private var allTerms: [Term]
    @Query private var collections: [TermCollection]

    private var masteryDistribution: [(label: String, count: Int, color: Color)] {
        [
            ("New",       allTerms.filter { $0.masteryLevel == 0 }.count, .gray),
            ("Learning",  allTerms.filter { $0.masteryLevel == 1 }.count, .orange),
            ("Familiar",  allTerms.filter { $0.masteryLevel == 2 }.count, .yellow),
            ("Practiced", allTerms.filter { $0.masteryLevel == 3 }.count, .blue),
            ("Mastered",  allTerms.filter { $0.masteryLevel == 4 }.count, AppColors.primary),
            ("Expert",    allTerms.filter { $0.masteryLevel == 5 }.count, AppColors.accent),
        ].filter { $0.count > 0 }
    }

    private var overallAccuracy: Double {
        let correct = allTerms.reduce(0) { $0 + $1.timesCorrect }
        let total = allTerms.reduce(0) { $0 + $1.timesCorrect + $1.timesIncorrect }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }

    private var streak: Int { UserDefaults.standard.integer(forKey: "currentStreak") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    overviewCards
                    if !allTerms.isEmpty { masteryChart }
                    if !collections.isEmpty { collectionProgress }
                    motivationCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationTitle("Progress")
        }
    }

    private var overviewCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    value: "\(allTerms.filter { $0.isLearned }.count)",
                    label: "Mastered",
                    icon: "checkmark.seal.fill",
                    color: AppColors.primary
                )
                StatCard(
                    value: "\(Int(overallAccuracy))%",
                    label: "Accuracy",
                    icon: "target",
                    color: AppColors.accent
                )
            }
            HStack(spacing: 12) {
                StatCard(
                    value: "\(streak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: AppColors.secondary
                )
                StatCard(
                    value: "\(allTerms.reduce(0) { $0 + $1.timesCorrect + $1.timesIncorrect })",
                    label: "Total Reviews",
                    icon: "arrow.counterclockwise",
                    color: .blue
                )
            }
        }
    }

    @ViewBuilder
    private var masteryChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mastery Distribution")
                .font(AppFonts.heading())

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(masteryDistribution, id: \.label) { item in
                        BarMark(
                            x: .value("Level", item.label),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(6)
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(AppFonts.caption(10))
                                    .rotationEffect(.degrees(-20))
                            }
                        }
                    }
                }
            } else {
                // Fallback for older OS
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(masteryDistribution, id: \.label) { item in
                        VStack(spacing: 4) {
                            Text("\(item.count)")
                                .font(AppFonts.caption(11))
                                .foregroundStyle(.secondary)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(
                                    width: 36,
                                    height: max(8, CGFloat(item.count) / CGFloat(allTerms.count) * 120)
                                )
                            Text(String(item.label.prefix(3)))
                                .font(AppFonts.caption(10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                ForEach(masteryDistribution.prefix(3), id: \.label) { item in
                    legendItem(label: item.label, color: item.color)
                }
            }
            HStack(spacing: 12) {
                ForEach(masteryDistribution.dropFirst(3), id: \.label) { item in
                    legendItem(label: item.label, color: item.color)
                }
            }
        }
        .cardStyle()
    }

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(AppFonts.caption(12)).foregroundStyle(.secondary)
        }
    }

    private var collectionProgress: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Collections")
                .font(AppFonts.heading())

            ForEach(collections) { col in
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color(hex: col.colorHex))
                        .frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(col.name)
                                .font(AppFonts.heading(14))
                            Spacer()
                            Text("\(Int(col.progress * 100))%")
                                .font(AppFonts.caption(12))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: col.progress)
                            .tint(Color(hex: col.colorHex))
                    }
                }
            }
        }
        .cardStyle()
    }

    private var motivationCard: some View {
        let messages: [(icon: String, text: String)] = [
            ("🎯", "Keep going — consistency beats perfection."),
            ("🧠", "Every term you learn rewires your brain."),
            ("🌟", "You're doing great. One term at a time."),
            ("🚀", "Spaced repetition is scientifically proven to work."),
            ("💡", "Review daily for long-term retention."),
        ]
        let message = messages[abs(Calendar.current.component(.day, from: Date())) % messages.count]

        return HStack(spacing: 14) {
            Text(message.icon).font(.system(size: 36))
            Text(message.text)
                .font(AppFonts.body())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
