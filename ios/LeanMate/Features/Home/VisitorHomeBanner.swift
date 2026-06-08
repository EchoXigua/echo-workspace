import SwiftUI

struct VisitorHomeBanner: View {
    let onLoginRequired: () -> Void
    let onClose: () -> Void
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 34, height: 34)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("登录后同步到账号")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)
                    .lineLimit(1)

                Text("饮食、体重和日报会自动保留")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onLoginRequired) {
                Text("登录同步")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(LMColors.primaryDeep)
                    .lineLimit(1)
                    .frame(width: 62, height: 28)
                    .background(LMColors.card)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(LMColors.primaryBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 14)
        .padding(.trailing, 38)
        .frame(height: 66)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xF4FBF6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xCFEBD8), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LMColors.textSecondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Circle())
                    .accessibilityLabel("关闭登录提示")
            }
            .buttonStyle(.plain)
            .offset(x: 2, y: -2)
            .padding(.top, 7)
            .padding(.trailing, 8)
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 18)
                .updating($dragOffset) { value, state, _ in
                    state = min(max(value.translation.width, -80), 80)
                }
                .onEnded { value in
                    if abs(value.translation.width) > 70 {
                        onClose()
                    }
                }
        )
        .animation(.snappy(duration: 0.18), value: dragOffset)
    }
}

struct VisitorHomeBanner_Previews: PreviewProvider {
    static var previews: some View {
        VisitorHomeBanner(onLoginRequired: {}, onClose: {})
            .padding()
            .background(LMColors.background)
    }
}
