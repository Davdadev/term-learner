import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService
    @AppStorage(AppConstants.remindersPerDayKey) private var remindersPerDay = AppConstants.defaultRemindersPerDay

    @Query private var allTerms: [Term]
    @Query private var collections: [TermCollection]

    @State private var showStudy = false
    @State private var greeting = ""

    private var dueTerms: [Term] { allTerms.filter { $0.isDueForReview } }
    private var learnedTerms: [Term] { allTerms.filter { $0.isLearned } }
    private var streak: Int { calculateStreak() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    statsRow
                    if !dueTerms.isEmpty { dueSection }
                    collectionsPreview
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Term Learner")
                        .font(AppFonts.heading(18))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !dueTerms.isEmpty {
                        Button {
                            showStudy = true
                        } label: {
                            Label("Study", systemImage: "play.circle.fill")
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showStudy) {
                StudyView(terms: dueTerms)
            }
        }
        .task {
            updateGreeting()
            if notificationService.isAuthorized {
                await notificationService.scheduleReminders(terms: dueTerms, remindersPerDay: remindersPerDay)
            }
        }
    }

    private var headerCard: some View {
        GradientCard(
            title: greeting,
            subtitle: dueTerms.isEmpty
                ? "You're all caught up! Great work."
                : "\(dueTerms.count) term\(dueTerms.count == 1 ? "" : "s") due for review",
            gradient: AppColors.gradientPrimary,
            icon: "brain.head.profile"
        )
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(allTerms.count)",
                label: "Total Terms",
                icon: "text.book.closed.fill",
                color: AppColors.primary
            )
            StatCard(
                value: "\(learnedTerms.count)",
                label: "Learned",
                icon: "checkmark.seal.fill",
                color: AppColors.accent
            )
            StatCard(
                value: "\(streak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: AppColors.secondary
            )
        }
    }

    private var dueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Due for Review")
                    .font(AppFonts.heading())
                Spacer()
                Button("Study All") { showStudy = true }
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.primary)
            }

            ForEach(dueTerms.prefix(5)) { term in
                TermRowView(term: term)
                    .cardStyle(padding: 14)
            }

            if dueTerms.count > 5 {
                Text("+ \(dueTerms.count - 5) more")
                    .font(AppFonts.caption())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var collectionsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Collections")
                .font(AppFonts.heading())

            if collections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.primary.opacity(0.4))
                    Text("No collections yet.\nUpload terms to get started.")
                        .font(AppFonts.body())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 32)
            } else {
                ForEach(collections.prefix(3)) { collection in
                    NavigationLink(destination: CollectionDetailView(collection: collection)) {
                        CollectionRow(collection: collection)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        default: greeting = "Good evening"
        }
    }

    private func calculateStreak() -> Int {
        // Simplified streak: count consecutive days with at least one reviewed term
        return UserDefaults.standard.integer(forKey: "currentStreak")
    }
}

struct CollectionRow: View {
    let collection: TermCollection

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: collection.colorHex).opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(String(collection.name.prefix(1)).uppercased())
                    .font(AppFonts.heading(20))
                    .foregroundStyle(Color(hex: collection.colorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.name)
                    .font(AppFonts.heading(15))
                Text("\(collection.termCount) terms · \(collection.learnedCount) learned")
                    .font(AppFonts.caption())
                    .foregroundStyle(.secondary)
                ProgressView(value: collection.progress)
                    .tint(Color(hex: collection.colorHex))
                    .frame(height: 4)
            }

            Spacer()

            if collection.dueCount > 0 {
                Text("\(collection.dueCount)")
                    .font(AppFonts.caption(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.secondary)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .cardStyle(padding: 14)
    }
}
