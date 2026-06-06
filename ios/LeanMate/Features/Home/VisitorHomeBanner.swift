import SwiftUI

struct VisitorHomeBanner: View {
    let onLoginRequired: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 42, height: 42)

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("登录后同步记录")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)

                Text("保存体重趋势、饮食记录和 AI 日报")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: onLoginRequired) {
                Text("登录")
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.primaryDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(LMColors.primarySoft)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(LMColors.primaryBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.primaryBorder, lineWidth: 1)
        }
    }
}

struct VisitorHomeBanner_Previews: PreviewProvider {
    static var previews: some View {
        VisitorHomeBanner {}
            .padding()
            .background(LMColors.background)
    }
}
