import SwiftUI

struct GradientCard: View {
    let title: String
    let subtitle: String
    let gradient: [Color]
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.heading(18))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(AppFonts.caption())
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(18)
        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: gradient.first?.opacity(0.35) ?? .clear, radius: 12, x: 0, y: 6)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(AppFonts.title(24))
                .foregroundStyle(.primary)
            Text(label)
                .font(AppFonts.caption())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct MasteryBadge: View {
    let level: Int

    private var label: String {
        switch level {
        case 0: return "New"
        case 1: return "Learning"
        case 2: return "Familiar"
        case 3: return "Practiced"
        case 4: return "Mastered"
        case 5: return "Expert"
        default: return ""
        }
    }

    private var color: Color {
        switch level {
        case 0: return .gray
        case 1: return .orange
        case 2: return .yellow
        case 3: return .blue
        case 4: return AppColors.primary
        case 5: return AppColors.accent
        default: return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(AppFonts.caption(11))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}
