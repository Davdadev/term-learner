import SwiftUI
import SwiftData
import UserNotifications

@main
struct TermLearnerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var notificationService = NotificationService()

    // State for notification-triggered quiz
    @State private var quizTermID: UUID?
    @State private var quizDefinition = ""
    @State private var showQuizPopup = false

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
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(notificationService)
                } else {
                    OnboardingView()
                        .environmentObject(notificationService)
                }
            }
            .sheet(isPresented: $showQuizPopup) {
                if let id = quizTermID {
                    QuizPopupView(termID: id, previewDefinition: quizDefinition)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "termlearner",
              url.host == "quiz",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let termIDString = components.queryItems?.first(where: { $0.name == "termID" })?.value,
              let id = UUID(uuidString: termIDString) else { return }
        let definition = components.queryItems?.first(where: { $0.name == "definition" })?.value ?? ""
        quizTermID = id
        quizDefinition = definition
        showQuizPopup = true
    }
}
