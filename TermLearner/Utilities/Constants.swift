import SwiftUI

enum AppColors {
    static let primary    = Color(hex: "6C63FF")
    static let secondary  = Color(hex: "FF6584")
    static let accent     = Color(hex: "43C6AC")
    static let background = Color(UIColor.systemGroupedBackground)
    static let card       = Color(UIColor.secondarySystemGroupedBackground)

    static let gradientPrimary   = [Color(hex: "6C63FF"), Color(hex: "8B85FF")]
    static let gradientSecondary = [Color(hex: "FF6584"), Color(hex: "FF8FA3")]
    static let gradientAccent    = [Color(hex: "43C6AC"), Color(hex: "5DE6C8")]
}

enum AppFonts {
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func heading(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

enum AppConstants {
    static let claudeAPIEndpoint = "https://api.anthropic.com/v1/messages"
    static let claudeModel = "claude-haiku-4-5-20251001"
    static let maxTermsPerImage = 70
    static let defaultRemindersPerDay = 3
    static let apiKeyDefaultsKey = "claudeAPIKey"
    static let remindersPerDayKey = "remindersPerDay"
    static let notificationCategoryID = "TERM_QUIZ"
    static let notificationCorrectAction = "CORRECT"
    static let notificationIncorrectAction = "INCORRECT"
}

let collectionColors = [
    "6C63FF", "FF6584", "43C6AC", "FF9F43",
    "48C9B0", "E74C3C", "3498DB", "9B59B6"
]
