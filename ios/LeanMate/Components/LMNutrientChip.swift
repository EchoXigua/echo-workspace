import SwiftUI

struct LMNutrientChip: View {
    let label: String
    let value: String
    var unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: 0x7A746A))
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                if let unit {
                    Text(unit)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LMColors.textSecondary)
                }
            }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct LMNutrientChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            LMNutrientChip(label: "碳水", value: "116", unit: "g")
            LMNutrientChip(label: "蛋白质", value: "42", unit: "g")
            LMNutrientChip(label: "脂肪", value: "28", unit: "g")
        }
        .padding()
        .background(LMColors.background)
    }
}
