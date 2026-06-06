import SwiftUI

struct LMSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: LMSpacing.medium) {
            Image(systemName: "search")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color(hex: 0x7A746A))

            TextField(placeholder, text: $text)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textBody)
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, LMSpacing.regular)
        .frame(height: 48)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.inputBorder, lineWidth: 1)
        }
    }
}

private struct LMSearchFieldPreview: View {
    @State private var text = ""

    var body: some View {
        LMSearchField(text: $text, placeholder: "输入一句话，如：早餐两个鸡蛋一杯豆浆")
            .padding()
            .background(LMColors.background)
    }
}

struct LMSearchField_Previews: PreviewProvider {
    static var previews: some View {
        LMSearchFieldPreview()
    }
}
