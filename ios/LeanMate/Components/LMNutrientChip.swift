import SwiftUI

struct LMNutrientChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: LMSpacing.xSmall) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: 0x7A746A))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
        .shadow(color: Color(hex: 0x143B23, alpha: 0.04), radius: 8, x: 0, y: 2)
    }
}

struct LMNutrientChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            LMNutrientChip(label: "碳水", value: "116g")
            LMNutrientChip(label: "蛋白质", value: "42g")
            LMNutrientChip(label: "脂肪", value: "28g")
        }
        .padding()
        .background(LMColors.background)
    }
}
