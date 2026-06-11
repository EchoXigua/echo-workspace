import SwiftUI

enum LMTagStyle {
    case primary
    case neutral
    case warning
    case danger
}

struct LMTag: View {
    let title: String
    var systemImage: String?
    var style: LMTagStyle = .primary

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(title)
                .font(LMTypography.badge)
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
}

private extension LMTag {
    var foregroundColor: Color {
        switch style {
        case .primary:
            LMColors.primaryDeep
        case .neutral:
            LMColors.textSecondary
        case .warning:
            Color(hex: 0xD48A19)
        case .danger:
            LMColors.danger
        }
    }

    var backgroundColor: Color {
        switch style {
        case .primary:
            LMColors.primarySoft
        case .neutral:
            LMColors.warmMuted
        case .warning:
            Color(hex: 0xFFF7E8)
        case .danger:
            LMColors.dangerSoft
        }
    }

    var borderColor: Color {
        style == .primary ? LMColors.primaryBorder : .clear
    }

    var borderWidth: CGFloat {
        style == .primary ? 1 : 0
    }
}

struct LMTag_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            LMTag(title: "今天还能吃 863 千卡")
            LMTag(title: "手动记录", style: .neutral)
            LMTag(title: "记录不足", style: .warning)
            LMTag(title: "识别失败", style: .danger)
        }
        .padding()
        .background(LMColors.background)
    }
}
