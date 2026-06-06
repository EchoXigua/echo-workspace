import SwiftUI

struct HomePlaceholderView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.regular) {
                    header

                    LMStateView(
                        kind: .empty,
                        title: "目标已保存",
                        message: "今日状态会以后端返回的数据展示。"
                    )
                }
                .padding(.horizontal, LMSpacing.large)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            LMBottomTabs(
                items: AppTab.allCases.map {
                    LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
                },
                selection: $selectedTab
            )
        }
        .background(LMColors.background.ignoresSafeArea())
    }
}

private extension HomePlaceholderView {
    var header: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text("首页")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Text("LeanMate")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomePlaceholderPreview: View {
    @State private var selectedTab = AppTab.home

    var body: some View {
        HomePlaceholderView(selectedTab: $selectedTab)
    }
}

struct HomePlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        HomePlaceholderPreview()
    }
}
