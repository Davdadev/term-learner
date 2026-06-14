import SwiftUI
import SwiftData
import UserNotifications

@main
struct TermLearnerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var notificationService = NotificationService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Term.self, TermCollection.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(notificationService)
            } else {
                OnboardingView()
                    .environmentObject(notificationService)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
