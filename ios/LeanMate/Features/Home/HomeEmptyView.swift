import SwiftUI

struct HomeEmptyView: View {
    let onRecordRequested: () -> Void

    var body: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            LMTag(title: "今天还没有记录")

            Text("第一条记录从早餐开始。")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            Text("先记大概也比完全不记更有帮助。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LMButton(
                title: "去记录",
                systemImage: "plus",
                action: onRecordRequested
            )
        }
    }
}

struct HomeEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        HomeEmptyView {}
            .padding()
            .background(LMColors.background)
    }
}
