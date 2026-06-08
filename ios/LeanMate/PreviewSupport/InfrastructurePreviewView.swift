import SwiftUI

struct InfrastructurePreviewView: View {
    @Binding var selectedTab: AppTab
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.regular) {
                    header
                    calorieCard
                    quickControls
                    stateSamples
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

private extension InfrastructurePreviewView {
    var header: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text("LeanMate")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Text("基础设施预览")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    var calorieCard: some View {
        LMCard {
            HStack {
                Text("还能吃 · 当前55.8kg · 连续12天")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                LMTag(title: "今日")
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("863")
                    .font(LMTypography.numberLarge)
                    .foregroundStyle(LMColors.textPrimary)
                Text("千卡")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LMColors.primarySoft)
                    Capsule()
                        .fill(LMColors.primary)
                        .frame(width: proxy.size.width * 0.62)
                }
            }
            .frame(height: 12)
            .clipShape(Capsule())

            HStack(spacing: LMSpacing.small) {
                LMNutrientChip(label: "碳水", value: "116", unit: "g")
                LMNutrientChip(label: "蛋白质", value: "42", unit: "g")
                LMNutrientChip(label: "脂肪", value: "28", unit: "g")
            }
        }
    }

    var quickControls: some View {
        VStack(spacing: LMSpacing.regular) {
            LMSearchField(text: $searchText, placeholder: "输入一句话，如：早餐两个鸡蛋一杯豆浆")

            HStack(spacing: LMSpacing.medium) {
                LMButton(title: "保存记录") {}
                LMButton(title: "取消", role: .secondary) {}
            }

            HStack(spacing: LMSpacing.small) {
                LMMetricTile(title: "当前体重", value: "55.8", unit: "kg")
                LMMetricTile(title: "连续记录", value: "12", unit: "天")
            }
        }
    }

    var stateSamples: some View {
        VStack(spacing: LMSpacing.regular) {
            LMStateView(
                kind: .empty,
                title: "今天还没有记录",
                message: "第一条记录从早餐开始。"
            )

            LMStateView(
                kind: .loading,
                title: "正在整理今天的饮食变化",
                message: "热量目标和明日建议会在完成后展示。"
            )

            LMCard {
                HStack {
                    Spacer()
                    LMSheetHandle()
                    Spacer()
                }
                Text("记录今天体重")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textPrimary)
                LMButton(title: "保存并更新趋势") {}
            }
        }
    }
}

private struct InfrastructurePreviewContainer: View {
    @State private var selectedTab = AppTab.home

    var body: some View {
        InfrastructurePreviewView(selectedTab: $selectedTab)
            .environment(\.appEnvironment, PreviewEnvironment.success)
    }
}

struct InfrastructurePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InfrastructurePreviewContainer()
    }
}
