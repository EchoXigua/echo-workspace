import SwiftUI

enum LMButtonRole {
    case primary
    case secondary
    case destructive
}

struct LMButton: View {
    let title: String
    var systemImage: String?
    var role: LMButtonRole = .primary
    var height: CGFloat = 54
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LMSpacing.small) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(LMTypography.bodyStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

private extension LMButton {
    var cornerRadius: CGFloat {
        role == .destructive ? 14 : 16
    }

    var backgroundColor: Color {
        switch role {
        case .primary:
            LMColors.primary
        case .secondary:
            LMColors.warmMuted
        case .destructive:
            LMColors.danger
        }
    }

    var foregroundColor: Color {
        switch role {
        case .primary, .destructive:
            .white
        case .secondary:
            LMColors.textBody
        }
    }

    var borderColor: Color {
        role == .secondary ? LMColors.inputBorder : .clear
    }

    var borderWidth: CGFloat {
        role == .secondary ? 1 : 0
    }
}

struct LMButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            LMButton(title: "保存并更新日报") {}
            LMButton(title: "取消", role: .secondary, height: 48) {}
            LMButton(title: "删除", role: .destructive, height: 48) {}
        }
        .padding()
        .background(LMColors.background)
    }
}
