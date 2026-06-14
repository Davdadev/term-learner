import SwiftUI

struct TermRowView: View {
    let term: Term

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(term.word)
                    .font(AppFonts.heading(16))
                    .foregroundStyle(.primary)
                Text(term.definition)
                    .font(AppFonts.body())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !term.notes.isEmpty {
                    Text(term.notes)
                        .font(AppFonts.caption())
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                MasteryBadge(level: term.masteryLevel)
                if term.isDueForReview {
                    Label("Due", systemImage: "clock.fill")
                        .font(AppFonts.caption(11))
                        .foregroundStyle(AppColors.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TermFlashcard: View {
    let term: Term
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            frontFace
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? -90 : 0), axis: (x: 0, y: 1, z: 0))

            backFace
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }

    private var frontFace: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(term.word)
                .font(AppFonts.title(32))
                .multilineTextAlignment(.center)
            Text("Tap to reveal")
                .font(AppFonts.caption())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 16)
    }

    private var backFace: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(term.definition)
                .font(AppFonts.heading(22))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.primary)
            if !term.notes.isEmpty {
                Text(term.notes)
                    .font(AppFonts.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 16)
    }
}
