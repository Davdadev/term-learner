import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let terms: [Term]

    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @State private var correctCount = 0
    @State private var incorrectCount = 0
    @State private var isFinished = false
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0

    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let successHaptic = UINotificationFeedbackGenerator()

    private var current: Term? {
        guard currentIndex < terms.count else { return nil }
        return terms[currentIndex]
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if isFinished {
                resultView
            } else {
                studyContent
            }
        }
    }

    private var studyContent: some View {
        VStack(spacing: 0) {
            studyHeader
            Spacer()

            if let term = current {
                cardArea(term: term)
            }

            Spacer()
            actionBar
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var studyHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(currentIndex + 1) / \(terms.count)")
                    .font(AppFonts.heading(15))
                ProgressView(value: Double(currentIndex + 1), total: Double(terms.count))
                    .tint(AppColors.primary)
                    .frame(width: 120)
            }

            Spacer()

            HStack(spacing: 10) {
                Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.accent)
                    .font(AppFonts.caption())
                Label("\(incorrectCount)", systemImage: "xmark.circle.fill")
                    .foregroundStyle(AppColors.secondary)
                    .font(AppFonts.caption())
            }
        }
    }

    private func cardArea(term: Term) -> some View {
        ZStack {
            // Shadow card behind
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.card.opacity(0.5))
                .frame(height: 360)
                .offset(y: 12)
                .scaleEffect(0.95)

            // Main card
            VStack(spacing: 20) {
                MasteryBadge(level: term.masteryLevel)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text(term.word)
                    .font(AppFonts.title(36))
                    .multilineTextAlignment(.center)

                if isShowingAnswer {
                    Divider().padding(.horizontal, 32)

                    Text(term.definition)
                        .font(AppFonts.heading(22))
                        .foregroundStyle(AppColors.primary)
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    if !term.notes.isEmpty {
                        Text(term.notes)
                            .font(AppFonts.body())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                } else {
                    Text("Tap to reveal")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(32)
            .frame(height: 360)
            .frame(maxWidth: .infinity)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.08), radius: 16)
            .offset(x: cardOffset)
            .rotationEffect(.degrees(cardRotation))
            .onTapGesture {
                if !isShowingAnswer {
                    haptic.impactOccurred()
                    withAnimation(.spring(response: 0.35)) {
                        isShowingAnswer = true
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isShowingAnswer {
                            cardOffset = value.translation.width
                            cardRotation = value.translation.width / 20
                        }
                    }
                    .onEnded { value in
                        if isShowingAnswer {
                            if value.translation.width > 80 {
                                swipeCard(correct: true)
                            } else if value.translation.width < -80 {
                                swipeCard(correct: false)
                            } else {
                                withAnimation(.spring()) {
                                    cardOffset = 0
                                    cardRotation = 0
                                }
                            }
                        }
                    }
            )
        }
    }

    private var actionBar: some View {
        VStack(spacing: 16) {
            if isShowingAnswer {
                HStack(spacing: 16) {
                    Button {
                        swipeCard(correct: false)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.secondary)
                            Text("Missed it")
                                .font(AppFonts.caption())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    Button {
                        swipeCard(correct: true)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.accent)
                            Text("Got it!")
                                .font(AppFonts.caption())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Swipe right if you knew it · left if you missed it")
                    .font(AppFonts.caption(12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: AppColors.gradientPrimary, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                Image(systemName: "star.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppColors.primary.opacity(0.4), radius: 16)

            VStack(spacing: 8) {
                Text("Session Complete!")
                    .font(AppFonts.title())
                Text("You reviewed \(terms.count) term\(terms.count == 1 ? "" : "s")")
                    .font(AppFonts.body())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 32) {
                VStack(spacing: 6) {
                    Text("\(correctCount)")
                        .font(AppFonts.title(40))
                        .foregroundStyle(AppColors.accent)
                    Text("Correct")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 6) {
                    Text("\(incorrectCount)")
                        .font(AppFonts.title(40))
                        .foregroundStyle(AppColors.secondary)
                    Text("Missed")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle(padding: 24)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .primaryButton()
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func swipeCard(correct: Bool) {
        guard let term = current else { return }

        if correct {
            successHaptic.notificationOccurred(.success)
        } else {
            successHaptic.notificationOccurred(.error)
        }

        let direction: CGFloat = correct ? 400 : -400
        withAnimation(.spring(response: 0.4)) {
            cardOffset = direction
            cardRotation = correct ? 12 : -12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            term.recordReview(correct: correct)
            try? modelContext.save()

            if correct { correctCount += 1 } else { incorrectCount += 1 }

            cardOffset = 0
            cardRotation = 0
            isShowingAnswer = false

            if currentIndex + 1 >= terms.count {
                withAnimation(.spring()) { isFinished = true }
                updateStreak()
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentIndex += 1
                }
            }
        }
    }

    private func updateStreak() {
        let defaults = UserDefaults.standard
        let lastStudy = defaults.object(forKey: "lastStudyDate") as? Date
        let streak = defaults.integer(forKey: "currentStreak")

        if let last = lastStudy, Calendar.current.isDateInYesterday(last) {
            defaults.set(streak + 1, forKey: "currentStreak")
        } else if let last = lastStudy, Calendar.current.isDateInToday(last) {
            // Already studied today — keep streak unchanged
        } else {
            defaults.set(1, forKey: "currentStreak")
        }
        defaults.set(Date(), forKey: "lastStudyDate")

        // Tell the widget to update
        TermLearnerApp.refreshWidget(terms: terms)
    }
}
