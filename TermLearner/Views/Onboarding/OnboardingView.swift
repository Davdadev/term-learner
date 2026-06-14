import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(AppConstants.remindersPerDayKey) private var remindersPerDay = AppConstants.defaultRemindersPerDay
    @AppStorage(AppConstants.apiKeyDefaultsKey) private var apiKey = ""

    @State private var currentPage = 0
    @State private var apiKeyInput = ""

    private let pages: [(icon: String, gradient: [Color], title: String, body: String)] = [
        ("brain.head.profile", AppColors.gradientPrimary,
         "Welcome to Term Learner",
         "Upload images of vocabulary lists — from a single word to 70 terms — and let AI sort them out for you."),
        ("bell.badge.fill", AppColors.gradientSecondary,
         "Daily Reminders",
         "Receive pop-up quizzes throughout the day. Enter a term's meaning and track your mastery as it grows."),
        ("chart.line.uptrend.xyaxis", AppColors.gradientAccent,
         "Track Your Progress",
         "Spaced repetition keeps you reviewing terms at the right time. Watch your learned term count climb every day."),
        ("key.fill", [Color(hex: "FF9F43"), Color(hex: "FFC371")],
         "Set Your API Key",
         "Term Learner uses Claude AI to extract terms from images. Your data is never used for AI training."),
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page: page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    private func pageView(page: (icon: String, gradient: [Color], title: String, body: String), index: Int) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: page.gradient.first?.opacity(0.4) ?? .clear, radius: 20)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(AppFonts.title(28))
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(AppFonts.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if index == 3 {
                apiKeyField
            } else if index == 1 {
                reminderPicker
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var apiKeyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claude API Key")
                .font(AppFonts.caption())
                .foregroundStyle(.secondary)
            SecureField("sk-ant-...", text: $apiKeyInput)
                .font(AppFonts.body())
                .padding(14)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.primary.opacity(0.3), lineWidth: 1))
            Text("Get your free API key at console.anthropic.com")
                .font(AppFonts.caption(11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
    }

    private var reminderPicker: some View {
        VStack(spacing: 12) {
            Text("Reminders per day")
                .font(AppFonts.caption())
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach([1, 3, 5, 8], id: \.self) { count in
                    Button {
                        remindersPerDay = count
                    } label: {
                        Text("\(count)")
                            .font(AppFonts.heading(18))
                            .foregroundStyle(remindersPerDay == count ? .white : AppColors.primary)
                            .frame(width: 56, height: 56)
                            .background(remindersPerDay == count ? AppColors.primary : AppColors.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3), value: remindersPerDay)
                }
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? AppColors.primary : AppColors.primary.opacity(0.2))
                        .frame(width: i == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            if currentPage < pages.count - 1 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("Continue")
                        .primaryButton()
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    if !apiKeyInput.isEmpty {
                        apiKey = apiKeyInput
                    }
                    Task { await notificationService.requestAuthorization() }
                    hasCompletedOnboarding = true
                } label: {
                    Text("Get Started")
                        .primaryButton()
                }
                .buttonStyle(.plain)
            }

            if currentPage > 0 {
                Button("Back") {
                    withAnimation { currentPage -= 1 }
                }
                .font(AppFonts.body())
                .foregroundStyle(.secondary)
            }
        }
    }
}
