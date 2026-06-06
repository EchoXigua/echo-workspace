import SwiftUI

struct LMMetricTile: View {
    let title: String
    let value: String
    var unit: String?
    var accent: Color = LMColors.primary

    var body: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let unit {
                    Text(unit)
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(accent.opacity(0.14))
                .frame(width: 28, height: 28)
                .padding(12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }
}

struct LMMetricTile_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            LMMetricTile(title: "当前体重", value: "55.8", unit: "kg")
            LMMetricTile(title: "连续记录", value: "12", unit: "天")
        }
        .padding()
        .background(LMColors.background)
    }
}
