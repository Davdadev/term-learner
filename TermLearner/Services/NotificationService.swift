import UserNotifications
import SwiftUI

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    @Published var pendingCount = 0

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        Task { await checkAuthorizationStatus() }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted { registerActions() }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleReminders(terms: [Term], remindersPerDay: Int) async {
        await center.removeAllPendingNotificationRequests()
        guard isAuthorized, !terms.isEmpty else { return }

        let dueTerms = terms.filter { $0.isDueForReview }
        let pool = dueTerms.isEmpty ? terms : dueTerms

        let wakeHour = 8
        let sleepHour = 22
        let totalSlots = sleepHour - wakeHour
        let interval = max(1, totalSlots / remindersPerDay)

        var scheduled = 0
        for i in 0..<min(remindersPerDay, pool.count) {
            let term = pool[i % pool.count]
            let hour = wakeHour + (i * interval)
            guard hour < sleepHour else { break }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = 0

            // If the time has already passed today, schedule for tomorrow
            if let date = Calendar.current.date(from: components), date < Date() {
                components = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
                components.hour = hour
                components.minute = 0
            }

            let content = UNMutableNotificationContent()
            content.title = "Term Learner"
            content.body = "What does '\(term.word)' mean?"
            content.sound = .default
            content.userInfo = ["termID": term.id.uuidString, "definition": term.definition]
            content.categoryIdentifier = AppConstants.notificationCategoryID
            // Deep-link URL so tapping the notification opens the quiz
            let encodedDef = term.definition.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            content.targetContentIdentifier = "termlearner://quiz?termID=\(term.id.uuidString)&definition=\(encodedDef)"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "reminder_\(i)_\(term.id.uuidString)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
            scheduled += 1
        }

        let pending = await center.pendingNotificationRequests()
        pendingCount = pending.count
    }

    func cancelAllReminders() async {
        await center.removeAllPendingNotificationRequests()
        pendingCount = 0
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Private

    private func registerActions() {
        let correctAction = UNNotificationAction(
            identifier: AppConstants.notificationCorrectAction,
            title: "Got it!",
            options: [.foreground]
        )
        let incorrectAction = UNNotificationAction(
            identifier: AppConstants.notificationIncorrectAction,
            title: "Still learning",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: AppConstants.notificationCategoryID,
            actions: [correctAction, incorrectAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }
}
