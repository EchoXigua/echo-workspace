import SwiftUI

struct LMCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 14
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: LMSpacing.medium) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
        .shadow(color: Color(hex: 0x143B23, alpha: 0.04), radius: 8, x: 0, y: 2)
    }
}

struct LMCard_Previews: PreviewProvider {
    static var previews: some View {
        LMCard {
            Text("把记录变成生活节奏")
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)
            Text("而不是表格任务")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
        .padding()
        .background(LMColors.background)
    }
}
