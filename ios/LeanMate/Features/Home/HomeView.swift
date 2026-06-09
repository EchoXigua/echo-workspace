import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Binding private var selectedTab: AppTab
    @Binding private var pendingDietEntryMode: DietEntryLaunchMode?
    @Binding private var pendingDietEntryMealType: MealType?
    @State private var isVisitorBannerVisible = true
    @State private var isTargetCalibrationPromptVisible = true

    let isVisitor: Bool
    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void

    init(
        viewModel: HomeViewModel,
        selectedTab: Binding<AppTab>,
        pendingDietEntryMode: Binding<DietEntryLaunchMode?> = .constant(nil),
        pendingDietEntryMealType: Binding<MealType?> = .constant(nil),
        isVisitor: Bool = false,
        onLoginRequired: @escaping () -> Void,
        onProfileRequired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = selectedTab
        _pendingDietEntryMode = pendingDietEntryMode
        _pendingDietEntryMealType = pendingDietEntryMealType
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
        case .profileIncomplete(let home):
            navHeader(date: home.date)
            profileIncompleteContent(home)
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

    func navHeader(date _: Date?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("今天吃得怎么样")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
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
            todaySummary(home)
        }
    }

    func profileIncompleteContent(_ home: TodayHome) -> some View {
        VStack(alignment: .leading, spacing: LMSpacing.regular) {
            profileIncompleteCalorieCard(home)

            if isTargetCalibrationPromptVisible {
                targetCalibrationPromptCard
            }

            todaySummary(home)
        }
    }

    func remainingCaloriesCard(_ home: TodayHome) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack {
                Text(calorieContextLabel(home))
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

                Text("千卡还能吃")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            calorieProgress(home)

            HStack(spacing: LMSpacing.small) {
                LMNutrientChip(label: "碳水", value: gramValue(home.carbsG), unit: gramUnit(home.carbsG))
                LMNutrientChip(label: "蛋白质", value: gramValue(home.proteinG), unit: gramUnit(home.proteinG))
                LMNutrientChip(label: "脂肪", value: gramValue(home.fatG), unit: gramUnit(home.fatG))
            }
        }
    }

    @ViewBuilder
    func profileIncompleteCalorieCard(_ home: TodayHome) -> some View {
        if home.calorieTargetKcal > 0 {
            remainingCaloriesCard(home)
        } else {
            profileIncompleteTargetPlaceholder(home)
        }
    }

    func profileIncompleteTargetPlaceholder(_ home: TodayHome) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack {
                Text("热量目标待校准")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer()

                LMTag(title: monthDayText(home.date))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("补充身体信息后生成目标")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("年龄、身高、当前体重和活动水平会用于估算每日推荐热量。")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var targetCalibrationPromptCard: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 38, height: 38)

                Image(systemName: "target")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("让热量目标更贴近你")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("补充年龄、身高和活动水平，首页目标会更准。")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Button(action: onProfileRequired) {
                    Text("校准目标")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.primaryDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(LMColors.card)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(LMColors.primaryBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button {
                    isTargetCalibrationPromptVisible = false
                } label: {
                    Text("稍后")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.textSecondary)
                        .frame(width: 54, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.primarySoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.primaryBorder, lineWidth: 1)
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

    func todaySummary(_ home: TodayHome) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日饮食")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Spacer()

                mealHeaderAction(home)
            }

            VStack(spacing: 10) {
                ForEach(mealRows(home)) { row in
                    foodEntryRow(row)
                }
            }
        }
    }

    func foodEntryRow(_ row: HomeMealRow) -> some View {
        let iconIsHighlighted = mealIconIsHighlighted(row)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconIsHighlighted ? LMColors.primarySoft : LMColors.warmMuted)
                    .frame(width: 42, height: 42)

                Image(systemName: "fork.knife")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconIsHighlighted ? LMColors.primary : Color(hex: 0x7A746A))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.mealType.title)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)

                Text(row.description)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            if row.isRecorded {
                Text("\(row.totalCaloriesKcal)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.primaryDeep)
            } else {
                Button {
                    openRecordTab(mealType: row.mealType)
                } label: {
                    Text("补录")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.primary)
                }
                .buttonStyle(.plain)
            }
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

    @ViewBuilder
    func mealHeaderAction(_ home: TodayHome) -> some View {
        let title = mealHeaderActionTitle(home)
        if HomeMealSummaryFormatter.hasRecordAction(foodEntries: home.foodEntries) {
            Button {
                openRecordTab(mealType: HomeMealSummaryFormatter.singleMissingMealType(foodEntries: home.foodEntries))
            } label: {
                Text(title)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
        } else {
            Text(title)
                .font(LMTypography.badge)
                .foregroundStyle(LMColors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
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
        pendingDietEntryMealType = nil
        selectedTab = .record
    }

    func openRecordTab(mode: DietEntryLaunchMode) {
        pendingDietEntryMode = mode
        pendingDietEntryMealType = nil
        selectedTab = .record
    }

    func openRecordTab(mealType: MealType?) {
        pendingDietEntryMode = nil
        pendingDietEntryMealType = mealType
        selectedTab = .record
    }

    func calorieContextLabel(_ home: TodayHome) -> String {
        "已摄入\(home.caloriesInKcal) / 目标\(home.calorieTargetKcal)"
    }

    func calorieRatio(_ home: TodayHome) -> CGFloat {
        guard home.calorieTargetKcal > 0 else {
            return 0
        }
        let ratio = Double(home.caloriesInKcal) / Double(home.calorieTargetKcal)
        return CGFloat(min(max(ratio, 0), 1))
    }

    func gramValue(_ value: Double?) -> String {
        display(value ?? 0)
    }

    func gramUnit(_: Double?) -> String? {
        "g"
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

    func mealHeaderActionTitle(_ home: TodayHome) -> String {
        HomeMealSummaryFormatter.headerActionTitle(foodEntries: home.foodEntries)
    }

    func mealRows(_ home: TodayHome) -> [HomeMealRow] {
        let baseMealTypes: [MealType] = [.breakfast, .lunch, .dinner]
        var extraMealTypes: [MealType] = []
        for entry in home.foodEntries where !baseMealTypes.contains(entry.mealType) && !extraMealTypes.contains(entry.mealType) {
            extraMealTypes.append(entry.mealType)
        }
        let mealTypes = baseMealTypes + extraMealTypes.sorted { $0.sortOrder < $1.sortOrder }

        return mealTypes.map { mealType in
            let entries = home.foodEntries.filter { $0.mealType == mealType }
            let calories = entries.map(\.totalCaloriesKcal).reduce(0, +)
            let names = entries.flatMap(\.itemNames)
            return HomeMealRow(
                mealType: mealType,
                totalCaloriesKcal: calories,
                description: names.isEmpty ? "还没记录，点补录添加这一餐" : names.joined(separator: "、"),
                isRecorded: !entries.isEmpty
            )
        }
    }

    func hasRecordedMeal(_ mealType: MealType, in home: TodayHome) -> Bool {
        home.foodEntries.contains { $0.mealType == mealType }
    }

    func mealIconIsHighlighted(_ row: HomeMealRow) -> Bool {
        row.isRecorded || row.mealType == .breakfast || row.mealType == .lunch
    }
}

private struct HomeMealRow: Identifiable {
    var id: MealType { mealType }

    let mealType: MealType
    let totalCaloriesKcal: Int
    let description: String
    let isRecorded: Bool
}

enum HomeMealSummaryFormatter {
    private static let baseMealTypes: [MealType] = [.breakfast, .lunch, .dinner]

    static func headerActionTitle(foodEntries: [FoodEntrySummary]) -> String {
        guard !foodEntries.isEmpty else {
            return "开始记录"
        }

        let recordedMealTypes = foodEntries.map(\.mealType)
        let missingMealTypes = baseMealTypes.filter { !recordedMealTypes.contains($0) }

        switch missingMealTypes.count {
        case 0:
            return "今日已记录"
        case 1:
            return "\(missingMealTypes[0].title)可补录"
        default:
            return "\(missingMealTypes.count)餐可补录"
        }
    }

    static func hasRecordAction(foodEntries: [FoodEntrySummary]) -> Bool {
        !missingBaseMealTypes(foodEntries: foodEntries).isEmpty
    }

    static func singleMissingMealType(foodEntries: [FoodEntrySummary]) -> MealType? {
        let missingMealTypes = missingBaseMealTypes(foodEntries: foodEntries)
        return missingMealTypes.count == 1 ? missingMealTypes[0] : nil
    }

    private static func missingBaseMealTypes(foodEntries: [FoodEntrySummary]) -> [MealType] {
        let recordedMealTypes = foodEntries.map(\.mealType)
        return baseMealTypes.filter { !recordedMealTypes.contains($0) }
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

    var sortOrder: Int {
        switch self {
        case .breakfast:
            0
        case .lunch:
            1
        case .dinner:
            2
        case .snack:
            3
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
