import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Binding private var selectedTab: AppTab
    @Binding private var pendingDietEntryMode: DietEntryLaunchMode?
    @State private var isVisitorBannerVisible = true

    let isVisitor: Bool
    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void

    init(
        viewModel: HomeViewModel,
        selectedTab: Binding<AppTab>,
        pendingDietEntryMode: Binding<DietEntryLaunchMode?> = .constant(nil),
        isVisitor: Bool = false,
        onLoginRequired: @escaping () -> Void,
        onProfileRequired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = selectedTab
        _pendingDietEntryMode = pendingDietEntryMode
        self.isVisitor = isVisitor
        self.onLoginRequired = onLoginRequired
        self.onProfileRequired = onProfileRequired
    }

    var body: some View {
        LMTabScreen(
            items: AppTab.allCases.map {
                LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
            },
            selection: $selectedTab
        ) {
            content
        }
        .task {
            await viewModel.refresh()
        }
    }
}

private extension HomeView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            navHeader
            LMStateView(
                kind: .loading,
                title: "正在读取今日状态",
                message: "目标、摄入和记录会以后端返回为准。"
            )
        case .visitor:
            navHeader
            visitorPreviewCard
            visitorRecordPreview
            if isVisitorBannerVisible {
                VisitorHomeBanner(
                    onLoginRequired: onLoginRequired,
                    onClose: { isVisitorBannerVisible = false }
                )
            }
        case .profileIncomplete:
            navHeader
            LMStateView(
                kind: .empty,
                title: "先完成档案",
                message: "生成目标后再展示今日热量和连续打卡。",
                actionTitle: "去填写档案",
                action: onProfileRequired
            )
        case .empty(let home):
            navHeader(date: home.date)
            HomeEmptyView(onRecordRequested: openRecordTab)
        case .loaded(let home):
            navHeader(date: home.date)
            loadedContent(home)
            if isVisitor && isVisitorBannerVisible {
                VisitorHomeBanner(
                    onLoginRequired: onLoginRequired,
                    onClose: { isVisitorBannerVisible = false }
                )
            }
        case .error(let message, let recovery):
            navHeader
            LMStateView(
                kind: .error,
                title: "首页加载失败",
                message: message,
                actionTitle: recovery == .login ? "重新登录" : "重试",
                action: recovery == .login ? onLoginRequired : retry
            )
        }
    }

    var navHeader: some View {
        navHeader(date: nil)
    }

    func navHeader(date: Date?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("今天吃得怎么样")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                if let date {
                    Text(APICoding.dateString(from: date))
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }

            Spacer()

            Button(action: openRecordTab) {
                Text("补记录")
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.primary)
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
        .frame(height: 52)
    }

    func loadedContent(_ home: TodayHome) -> some View {
        VStack(alignment: .leading, spacing: LMSpacing.regular) {
            remainingCaloriesCard(home)
            quickActions
            todaySummary(home)
        }
    }

    func remainingCaloriesCard(_ home: TodayHome) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack {
                Text(heroLabel(home))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer()

                LMTag(title: monthDayText(home.date))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(home.remainingCaloriesKcal)")
                    .font(LMTypography.numberLarge)
                    .foregroundStyle(LMColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("千卡")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            calorieProgress(home)

            HStack(spacing: LMSpacing.small) {
                LMNutrientChip(label: "碳水", value: gramText(home.carbsG))
                LMNutrientChip(label: "蛋白质", value: gramText(home.proteinG))
                LMNutrientChip(label: "脂肪", value: gramText(home.fatG))
            }
        }
    }

    func calorieProgress(_ home: TodayHome) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LMColors.primarySoft)
                Capsule()
                    .fill(LMColors.primary)
                    .frame(width: proxy.size.width * calorieRatio(home))
            }
        }
        .frame(height: 12)
        .clipShape(Capsule())
    }

    var quickActions: some View {
        HStack(spacing: LMSpacing.small) {
            quickAction(title: "拍照", systemImage: "camera", mode: .photo)
            quickAction(title: "文本", systemImage: "text.bubble", mode: .text)
            quickAction(title: "手动", systemImage: "pencil", mode: .manual)
        }
    }

    func quickAction(title: String, systemImage: String, mode: DietEntryLaunchMode) -> some View {
        Button {
            openRecordTab(mode: mode)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(title == "手动" ? LMColors.warmMuted : LMColors.primarySoft)
                        .frame(width: 42, height: 42)

                    if title == "手动" {
                        LMManualEntryIcon(size: 18)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(LMColors.primary)
                    }
                }

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LMColors.inputBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    func todaySummary(_ home: TodayHome) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日饮食")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Spacer()

                Text(home.reportSummary ?? "暂无日报摘要")
                    .font(LMTypography.badge)
                    .foregroundStyle(home.reportSummary == nil ? LMColors.textMuted : LMColors.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack(spacing: LMSpacing.small) {
                LMMetricTile(title: "目标", value: "\(home.calorieTargetKcal)", unit: "kcal")
                LMMetricTile(title: "已摄入", value: "\(home.caloriesInKcal)", unit: "kcal")
            }

            HStack(spacing: LMSpacing.small) {
                LMMetricTile(
                    title: "当前体重",
                    value: weightText(home.currentWeightKg),
                    unit: home.currentWeightKg == nil ? nil : "kg"
                )
                LMMetricTile(title: "连续打卡", value: "\(home.streakDays)", unit: "天")
            }

            if home.foodEntries.isEmpty {
                Text("今天还没有正式饮食记录。")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            } else {
                VStack(spacing: LMSpacing.medium) {
                    ForEach(home.foodEntries) { entry in
                        foodEntryRow(entry)
                    }
                }
            }
        }
    }

    func foodEntryRow(_ entry: FoodEntrySummary) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 42, height: 42)

                Text(entry.mealType.shortTitle)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.mealType.title)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)

                Text(entry.itemNames.joined(separator: "、"))
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            Text("\(entry.totalCaloriesKcal)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMColors.primaryDeep)
        }
    }

    var visitorPreviewCard: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日热量预览")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 10)

                LMTag(title: "体验预览")
            }

            Text("记录一餐后，首页会这样展示热量和营养结构。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("863")
                    .font(LMTypography.numberLarge)
                    .foregroundStyle(LMColors.textPrimary)
                    .lineLimit(1)

                Text("千卡还能吃")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            visitorCalorieProgress

            HStack(spacing: LMSpacing.small) {
                previewMetric(title: "已摄入", value: "637", unit: "kcal")
                previewMetric(title: "蛋白", value: "18", unit: "g")
                previewMetric(title: "碳水", value: "58", unit: "g")
            }
        }
    }

    var visitorCalorieProgress: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LMColors.primarySoft)
                Capsule()
                    .fill(LMColors.primary)
                    .frame(width: proxy.size.width * 0.42)
            }
        }
        .frame(height: 12)
        .clipShape(Capsule())
    }

    var visitorRecordPreview: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("选择一种记录方式")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)

                    Text("选一种方式，先把这一餐记下来。")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: openRecordTab) {
                    Text("开始")
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

            HStack(spacing: LMSpacing.small) {
                visitorRecordAction(title: "拍照", systemImage: "camera", mode: .photo)
                visitorRecordAction(title: "文本", systemImage: "text.bubble", mode: .text)
                visitorRecordAction(title: "手动", systemImage: "pencil", mode: .manual)
            }
        }
    }

    func visitorRecordAction(title: String, systemImage: String, mode: DietEntryLaunchMode) -> some View {
        Button {
            openRecordTab(mode: mode)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(title == "手动" ? LMColors.warmMuted : LMColors.primarySoft)
                        .frame(width: 38, height: 38)

                    if title == "手动" {
                        LMManualEntryIcon(size: 18)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LMColors.primary)
                    }
                }

                Text(title)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.textBody)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LMColors.inputBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    func previewMetric(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Text(unit)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func retry() {
        Task {
            await viewModel.refresh()
        }
    }

    func openRecordTab() {
        pendingDietEntryMode = nil
        selectedTab = .record
    }

    func openRecordTab(mode: DietEntryLaunchMode) {
        pendingDietEntryMode = mode
        selectedTab = .record
    }

    func heroLabel(_ home: TodayHome) -> String {
        let weight = home.currentWeightKg.map { "当前\(display($0))kg" } ?? "体重暂无"
        return "还能吃 · \(weight) · 连续\(home.streakDays)天"
    }

    func calorieRatio(_ home: TodayHome) -> CGFloat {
        guard home.calorieTargetKcal > 0 else {
            return 0
        }
        let ratio = Double(home.caloriesInKcal) / Double(home.calorieTargetKcal)
        return CGFloat(min(max(ratio, 0), 1))
    }

    func gramText(_ value: Double?) -> String {
        guard let value else {
            return "暂无"
        }
        return "\(display(value))g"
    }

    func weightText(_ value: Double?) -> String {
        guard let value else {
            return "暂无"
        }
        return display(value)
    }

    func display(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    func monthDayText(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return APICoding.dateString(from: date)
        }
        return "\(month)月\(day)日"
    }
}

private extension MealType {
    var title: String {
        switch self {
        case .breakfast:
            "早餐"
        case .lunch:
            "午餐"
        case .dinner:
            "晚餐"
        case .snack:
            "加餐"
        }
    }

    var shortTitle: String {
        switch self {
        case .breakfast:
            "早"
        case .lunch:
            "午"
        case .dinner:
            "晚"
        case .snack:
            "加"
        }
    }
}

private struct HomePreviewContainer: View {
    @State private var selectedTab = AppTab.home

    var body: some View {
        HomeView(
            viewModel: HomeViewModel(apiClient: MockAPIClient(delayNanoseconds: 0)),
            selectedTab: $selectedTab,
            onLoginRequired: {},
            onProfileRequired: {}
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomePreviewContainer()
    }
}
