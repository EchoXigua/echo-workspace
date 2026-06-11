import SwiftUI

struct LMMilestoneCelebrationOverlay: View {
    let days: Int
    let message: String
    let nextMilestoneDays: Int?
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var cardScale: CGFloat = 0.92
    @State private var iconScale: CGFloat = 0.75
    @State private var particlePhase = 0
    @State private var hasDismissed = false

    var body: some View {
        ZStack {
            Color(hex: 0x061A10, alpha: 0.6)
                .opacity(isVisible ? 1 : 0)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                milestoneIcon
                milestoneCopy
                statsRow
                primaryButton
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: 342)
            .frame(height: 366)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LMColors.border, lineWidth: 1)
            }
            .shadow(color: Color(hex: 0x05160D, alpha: 0.18), radius: 34, x: 0, y: 18)
            .scaleEffect(cardScale)
            .opacity(isVisible ? 1 : 0)
            .padding(.horizontal, 30)
        }
        .onAppear(perform: animateIn)
        .task(id: days) {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            dismiss()
        }
        .accessibilityAddTraits(.isModal)
    }
}

private extension LMMilestoneCelebrationOverlay {
    var milestoneIcon: some View {
        ZStack {
            LMMilestoneParticleBurst(phase: particlePhase)
                .frame(width: 126, height: 126)

            ZStack {
                Circle()
                    .fill(LMColors.primarySoft)
                    .frame(width: 86, height: 86)
                    .overlay {
                        Circle()
                            .stroke(LMColors.primaryBorder, lineWidth: 1)
                    }

                Circle()
                    .fill(LMColors.card)
                    .frame(width: 58, height: 58)
                    .overlay {
                        Circle()
                            .stroke(LMColors.primary, lineWidth: 1)
                    }

                Image(systemName: "checkmark.seal")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }
            .scaleEffect(iconScale)
        }
        .frame(width: 104, height: 94)
        .accessibilityHidden(true)
    }

    var milestoneCopy: some View {
        VStack(spacing: 8) {
            Text("连续记录 \(days) 天")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(LMColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    var statsRow: some View {
        HStack(spacing: 8) {
            statTile(title: "本次里程碑", value: "\(days) 天", isPrimary: false)
            statTile(title: "继续目标", value: nextTargetText, isPrimary: true)
        }
    }

    var primaryButton: some View {
        Button(action: dismiss) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))

                Text("知道了")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(LMColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("知道了")
    }

    var nextTargetText: String {
        guard let nextMilestoneDays else {
            return "全部达成"
        }
        return "\(nextMilestoneDays) 天"
    }

    func statTile(title: String, value: String, isPrimary: Bool) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isPrimary ? LMColors.primary : LMColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(LMColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }

    func animateIn() {
        guard !reduceMotion else {
            isVisible = true
            cardScale = 1
            iconScale = 1
            return
        }

        withAnimation(.easeOut(duration: 0.18)) {
            isVisible = true
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
            cardScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.44)) {
                iconScale = 1.08
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                iconScale = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            particlePhase = 1
            withAnimation(.easeOut(duration: 0.65)) {
                particlePhase = 2
            }
        }
    }

    func dismiss() {
        guard !hasDismissed else {
            return
        }
        hasDismissed = true

        guard !reduceMotion else {
            onDismiss()
            return
        }

        withAnimation(.easeOut(duration: 0.16)) {
            isVisible = false
            cardScale = 0.96
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            onDismiss()
        }
    }
}

private struct LMMilestoneParticleBurst: View {
    let phase: Int

    var body: some View {
        ZStack {
            ForEach(Self.particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(
                        x: phase == 2 ? particle.offset.width : 0,
                        y: phase == 2 ? particle.offset.height : 0
                    )
                    .opacity(phase == 1 ? 1 : 0)
                    .scaleEffect(phase == 2 ? 0.7 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let particles = [
        LMMilestoneParticle(offset: CGSize(width: -44, height: -24), size: 6, color: LMColors.primary),
        LMMilestoneParticle(offset: CGSize(width: -30, height: 26), size: 5, color: Color(hex: 0xF4C96B)),
        LMMilestoneParticle(offset: CGSize(width: 38, height: -30), size: 6, color: LMColors.primary),
        LMMilestoneParticle(offset: CGSize(width: 46, height: 18), size: 4, color: Color(hex: 0xF4C96B)),
        LMMilestoneParticle(offset: CGSize(width: 0, height: -48), size: 5, color: LMColors.primary.opacity(0.86))
    ]
}

private struct LMMilestoneParticle: Identifiable {
    let id = UUID()
    let offset: CGSize
    let size: CGFloat
    let color: Color
}
