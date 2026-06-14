import SwiftUI
import SwiftData

/// Full-screen quiz sheet triggered when the user taps a reminder notification.
struct QuizPopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let termID: UUID
    let previewDefinition: String   // passed from notification userInfo as fallback

    @Query private var allTerms: [Term]

    private var term: Term? { allTerms.first { $0.id == termID } }

    @State private var userAnswer = ""
    @State private var hasSubmitted = false
    @State private var isCorrect = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if let term {
                    quizContent(term: term)
                } else {
                    // Term was deleted — fall back to stored preview
                    fallbackContent
                }
            }
            .navigationTitle("Quick Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func quizContent(term: Term) -> some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("What does this mean?")
                    .font(AppFonts.caption())
                    .foregroundStyle(.secondary)
                Text(term.word)
                    .font(AppFonts.title(40))
                    .multilineTextAlignment(.center)
                MasteryBadge(level: term.masteryLevel)
            }
            .frame(maxWidth: .infinity)
            .cardStyle(padding: 32)

            if hasSubmitted {
                resultBanner(term: term)
            } else {
                answerField
            }

            if hasSubmitted {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .primaryButton()
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var answerField: some View {
        VStack(spacing: 16) {
            TextField("Type the meaning or translation…", text: $userAnswer, axis: .vertical)
                .font(AppFonts.body())
                .padding(16)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .lineLimit(3)

            Button {
                checkAnswer()
            } label: {
                Text("Submit")
                    .primaryButton()
            }
            .buttonStyle(.plain)
            .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
    }

    private func resultBanner(term: Term) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(isCorrect ? AppColors.accent : AppColors.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isCorrect ? "Correct!" : "Almost!")
                        .font(AppFonts.heading())
                    Text("Answer: \(term.definition)")
                        .font(AppFonts.body())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle(padding: 18)
    }

    private var fallbackContent: some View {
        VStack(spacing: 16) {
            Text("Answer: \(previewDefinition)")
                .font(AppFonts.heading())
                .multilineTextAlignment(.center)
            Text("This term may have been deleted.")
                .font(AppFonts.caption())
                .foregroundStyle(.secondary)
            Button("Close") { dismiss() }
        }
        .padding(32)
    }

    private func checkAnswer() {
        guard let term else { return }
        let answer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let expected = term.definition.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Correct if the user's answer contains the key word(s) from the definition
        isCorrect = answer == expected
            || expected.contains(answer)
            || answer.contains(expected.prefix(8))
        hasSubmitted = true
        term.recordReview(correct: isCorrect)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)
    }
}
