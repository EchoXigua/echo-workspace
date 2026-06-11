import SwiftUI

struct ProfileSummaryView: View {
    @StateObject private var viewModel: ProfileSummaryViewModel
    @StateObject private var weightViewModel: WeightViewModel
    @Binding private var selectedTab: AppTab
    @State private var showsDebugResetConfirmation = false
    @State private var debugResetErrorMessage: String?
    @State private var isDebugResetting = false
    @State private var showsWeightSheet = false

    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void
    let onOpenSettings: (ProfileRoutePayload?) -> Void
    let onOpenDataPlan: (ProfileRoutePayload) -> Void
    let onOpenProfileEdit: (ProfileRoutePayload) -> Void
    let onOpenWeightTrend: (ProfileRoutePayload) -> Void
    let onOpenDataSync: () -> Void
    let onDebugClearLocalData: (() async throws -> Void)?

    init(
        viewModel: ProfileSummaryViewModel,
        weightViewModel: WeightViewModel,
        selectedTab: Binding<AppTab>,
        onLoginRequired: @escaping () -> Void,
        onProfileRequired: @escaping () -> Void,
        onOpenSettings: @escaping (ProfileRoutePayload?) -> Void = { _ in },
        onOpenDataPlan: @escaping (ProfileRoutePayload) -> Void = { _ in },
        onOpenProfileEdit: @escaping (ProfileRoutePayload) -> Void = { _ in },
        onOpenWeightTrend: @escaping (ProfileRoutePayload) -> Void = { _ in },
        onOpenDataSync: @escaping () -> Void = {},
        onDebugClearLocalData: (() async throws -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _weightViewModel = StateObject(wrappedValue: weightViewModel)
        _selectedTab = selectedTab
        self.onLoginRequired = onLoginRequired
        self.onProfileRequired = onProfileRequired
        self.onOpenSettings = onOpenSettings
        self.onOpenDataPlan = onOpenDataPlan
        self.onOpenProfileEdit = onOpenProfileEdit
        self.onOpenWeightTrend = onOpenWeightTrend
        self.onOpenDataSync = onOpenDataSync
        self.onDebugClearLocalData = onDebugClearLocalData
    }

    var body: some View {
        ZStack {
            LMTabScreen(
                items: AppTab.allCases.map {
                    LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
                },
                selection: $selectedTab
            ) {
                content
            }

            if let milestone = viewModel.milestoneToPresent {
                milestoneOverlay(milestone)
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showsWeightSheet, onDismiss: refreshAfterWeightEntry) {
            WeightEntrySheet(viewModel: weightViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(LMColors.background)
        }
        .alert("清空本地数据？", isPresented: $showsDebugResetConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task {
                    await debugClearLocalData()
                }
            }
        } message: {
            Text("会清除游客会话、身体档案、饮食和体重本地记录、草稿与待同步数据。")
        }
        .alert("清理失败", isPresented: debugResetErrorBinding) {
            Button("知道了", role: .cancel) {
                debugResetErrorMessage = nil
            }
        } message: {
            Text(debugResetErrorMessage ?? "请稍后再试。")
        }
    }
}

private extension ProfileSummaryView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            navHeader(settingsPayload: nil)
            LMStateView(
                kind: .loading,
                title: "正在读取我的计划",
                message: "档案、目标和连续打卡会以后端返回为准。"
            )
        case .visitor:
            navHeader(settingsPayload: nil)
            LMStateView(
                kind: .empty,
                title: "登录后查看我的计划",
                message: "同步档案、目标热量和连续打卡进度。",
                actionTitle: "去登录",
                action: onLoginRequired
            )
        case .profileIncomplete:
            navHeader(settingsPayload: nil)
            LMStateView(
                kind: .empty,
                title: "先完成档案",
                message: "生成目标后再展示我的计划和连续打卡。",
                actionTitle: "去填写档案",
                action: onProfileRequired
            )
        case .loaded(let snapshot):
            let payload = routePayload(from: snapshot)
            navHeader(settingsPayload: payload)
            loadedContent(snapshot, payload: payload)
        case .error(let message, let recovery):
            navHeader(settingsPayload: nil)
            LMStateView(
                kind: .error,
                title: "我的页加载失败",
                message: message,
                actionTitle: recovery == .login ? "重新登录" : "重试",
                action: recovery == .login ? onLoginRequired : retry
            )
        }

        #if DEBUG
        debugLocalDataResetCard
        #endif
    }

    @ViewBuilder
    func loadedContent(_ snapshot: ProfileSummarySnapshot, payload: ProfileRoutePayload) -> some View {
        profileCard(snapshot)
        weightGoalCard(snapshot)
        dataPlanCard(snapshot, payload: payload)
        profileActions(payload)
    }

    func navHeader(settingsPayload: ProfileRoutePayload?) -> some View {
        HStack {
            Text("我的")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Button {
                onOpenSettings(settingsPayload)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(LMColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(LMColors.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .id(settingsPayload)
            .accessibilityLabel("打开设置")
        }
        .frame(height: 52)
    }

    func profileCard(_ snapshot: ProfileSummarySnapshot) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(LMColors.primary)
                        .frame(width: 58, height: 58)

                    Text(profileInitial(snapshot.displayName))
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(snapshot.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("\(snapshot.profile.age) 岁 · \(snapshot.profile.gender.title) · \(snapshot.profile.activityLevel.title)")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    LMTag(
                        title: streakTagTitle(snapshot.streak),
                        systemImage: "flame",
                        style: .primary
                    )
                }

                Spacer()
            }
        }
    }

    func weightGoalCard(_ snapshot: ProfileSummarySnapshot) -> some View {
        let profile = snapshot.profile
        let currentWeightKg = snapshot.displayCurrentWeightKg

        return LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("体重目标")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Spacer()

                Button {
                    recordWeight(defaultWeightKg: currentWeightKg)
                } label: {
                    Text("记录体重")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.primaryDeep)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("记录体重")
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前体重")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(display(currentWeightKg))
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(LMColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text("kg")
                            .font(LMTypography.bodyStrong)
                            .foregroundStyle(LMColors.textSecondary)
                    }
                }

                Spacer()

                HStack(alignment: .bottom, spacing: 22) {
                    weightGoalInfo(title: "目标", value: display(profile.targetWeightKg), unit: "kg", color: LMColors.textBody)
                    weightGoalInfo(title: "差距", value: display(abs(currentWeightKg - profile.targetWeightKg)), unit: "kg", color: weightGapColor(currentWeightKg: currentWeightKg, targetWeightKg: profile.targetWeightKg))
                }
            }

            progressBar(progress: weightProgress(currentWeightKg: currentWeightKg, targetWeightKg: profile.targetWeightKg))
        }
    }

    func weightGoalInfo(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(color)

                Text(unit)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }
        }
    }

    func dataPlanCard(_ snapshot: ProfileSummarySnapshot, payload: ProfileRoutePayload) -> some View {
        Button {
            onOpenDataPlan(payload)
        } label: {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack {
                    Text("数据与计划")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)

                    Spacer()

                    Text("查看全部")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.primaryDeep)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("每日目标")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(snapshot.profile.dailyCalorieTargetKcal)")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(LMColors.textPrimary)

                            Text("kcal")
                                .font(LMTypography.bodyStrong)
                                .foregroundStyle(LMColors.textSecondary)
                        }
                    }

                    Spacer()

                    Text("低于日常消耗，可按状态调整")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.primaryDeep)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 160, alignment: .trailing)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(LMColors.primarySoft.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: LMSpacing.small) {
                    profileMetric(title: "BMI", value: display(snapshot.profile.bmi), unit: nil)
                    profileMetric(title: "基础代谢", value: "\(snapshot.profile.bmrKcal)", unit: "kcal")
                    profileMetric(
                        title: "本周变化",
                        value: weeklyChangeValue(snapshot.weeklyWeightChangeKg),
                        unit: weeklyChangeUnit(snapshot.weeklyWeightChangeKg),
                        accent: weeklyChangeColor(snapshot.weeklyWeightChangeKg)
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("查看数据与计划详情")
    }

    func profileMetric(title: String, value: String, unit: String?, accent: Color = LMColors.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if let unit {
                    Text(unit)
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }

    func profileActions(_ payload: ProfileRoutePayload) -> some View {
        HStack(spacing: LMSpacing.small) {
            profileActionButton(title: "档案", systemImage: "person.text.rectangle") {
                onOpenProfileEdit(payload)
            }
            profileActionButton(title: "趋势", systemImage: "chart.line.uptrend.xyaxis") {
                onOpenWeightTrend(payload)
            }
            profileActionButton(title: "同步", systemImage: "arrow.triangle.2.circlepath", action: onOpenDataSync)
        }
    }

    func profileActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LMColors.primarySoft)
                        .frame(width: 30, height: 30)

                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                }

                Text(title)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LMColors.border, lineWidth: 1)
            }
            .shadow(color: Color(hex: 0x143B23, alpha: 0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // TODO: 上线前删除这个 Debug 清空入口。
    @ViewBuilder
    var debugLocalDataResetCard: some View {
        if onDebugClearLocalData != nil {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LMColors.dangerSoft)
                            .frame(width: 38, height: 38)

                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LMColors.danger)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug 本地数据")
                            .font(LMTypography.bodyStrong)
                            .foregroundStyle(LMColors.textBody)

                        Text("清空游客会话、本地档案、饮食和体重记录。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        showsDebugResetConfirmation = true
                    } label: {
                        Group {
                            if isDebugResetting {
                                ProgressView()
                                    .tint(LMColors.danger)
                            } else {
                                Text("清空")
                                    .font(LMTypography.badge)
                            }
                        }
                        .foregroundStyle(LMColors.danger)
                        .frame(width: 62, height: 34)
                        .background(LMColors.dangerSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isDebugResetting)
                    .accessibilityLabel("清空本地数据")
                }
            }
        }
    }

    func milestoneOverlay(_ milestone: StreakMilestonePresentation) -> some View {
        LMMilestoneCelebrationOverlay(
            days: milestone.days,
            message: milestoneMessage(for: milestone),
            nextMilestoneDays: milestone.nextValue,
            onDismiss: viewModel.dismissMilestone
        )
    }

    func retry() {
        Task {
            await viewModel.refresh()
        }
    }

    func recordWeight(defaultWeightKg: Double) {
        weightViewModel.resetForNewEntry(defaultWeightKg: defaultWeightKg)
        showsWeightSheet = true
    }

    func refreshAfterWeightEntry() {
        Task {
            await viewModel.refresh()
        }
    }

    var debugResetErrorBinding: Binding<Bool> {
        Binding(
            get: { debugResetErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    debugResetErrorMessage = nil
                }
            }
        )
    }

    func debugClearLocalData() async {
        guard let onDebugClearLocalData else {
            return
        }

        isDebugResetting = true
        defer {
            isDebugResetting = false
        }

        do {
            try await onDebugClearLocalData()
        } catch {
            debugResetErrorMessage = AppError(error).errorDescription ?? "请稍后再试。"
        }
    }

    func milestoneMessage(for milestone: StreakMilestonePresentation) -> String {
        milestone.message ?? "你已经建立起稳定的记录节奏。系统会继续按后端返回的连续打卡状态展示进度。"
    }

    func lastActiveText(_ date: Date?) -> String {
        guard let date else {
            return "暂无"
        }
        return APICoding.dateString(from: date)
    }

    func profileInitial(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).first ?? "我")
    }

    func streakTagTitle(_ streak: Streak) -> String {
        streak.currentDays > 0 ? "连续打卡 \(streak.currentDays) 天" : "开始记录"
    }

    func weightGapColor(currentWeightKg: Double, targetWeightKg: Double) -> Color {
        currentWeightKg <= targetWeightKg ? LMColors.danger : LMColors.primaryDeep
    }

    func weightProgress(currentWeightKg: Double, targetWeightKg: Double) -> Double {
        guard currentWeightKg > 0, targetWeightKg > 0 else {
            return 0
        }
        let ratio: Double
        if currentWeightKg >= targetWeightKg {
            ratio = targetWeightKg / currentWeightKg
        } else {
            ratio = currentWeightKg / targetWeightKg
        }
        return min(max(ratio, 0.12), 1)
    }

    func progressBar(progress: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LMColors.primarySoft)

                Capsule()
                    .fill(LMColors.primary)
                    .frame(width: max(10, proxy.size.width * progress))
            }
        }
        .frame(height: 8)
    }

    func weeklyChangeValue(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(display(value))"
    }

    func weeklyChangeUnit(_ value: Double?) -> String? {
        "kg"
    }

    func weeklyChangeColor(_ value: Double?) -> Color {
        guard let value else {
            return LMColors.textSecondary
        }
        return value > 0 ? LMColors.danger : LMColors.primaryDeep
    }

    func routePayload(from snapshot: ProfileSummarySnapshot) -> ProfileRoutePayload {
        let profile = snapshot.profile
        let currentWeightKg = snapshot.displayCurrentWeightKg

        return ProfileRoutePayload(
            displayName: snapshot.displayName,
            summary: "\(profile.age) 岁 · \(profile.gender.title) · \(profile.activityLevel.title)",
            currentWeight: "\(display(currentWeightKg)) kg",
            targetWeight: "\(display(profile.targetWeightKg)) kg",
            currentWeightKg: currentWeightKg,
            targetWeightKg: profile.targetWeightKg,
            height: "\(display(profile.heightCm)) cm",
            bmi: display(profile.bmi),
            bmr: "\(profile.bmrKcal) kcal",
            dailyTarget: "\(profile.dailyCalorieTargetKcal) kcal",
            activityLevel: profile.activityLevel.title,
            weeklyWeightChangeKg: snapshot.weeklyWeightChangeKg
        )
    }

    func display(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private extension Gender {
    var title: String {
        switch self {
        case .male:
            "男"
        case .female:
            "女"
        case .unknown:
            "未指定"
        }
    }
}

private extension ActivityLevel {
    var title: String {
        switch self {
        case .sedentary:
            "久坐"
        case .light:
            "轻度活动"
        case .moderate:
            "中等活动"
        case .active:
            "高活动"
        case .veryActive:
            "高强度活动"
        }
    }
}

private struct ProfileSummaryPreviewContainer: View {
    @State private var selectedTab = AppTab.profile

    var body: some View {
        ProfileSummaryView(
            viewModel: ProfileSummaryViewModel(apiClient: MockAPIClient(delayNanoseconds: 0)),
            weightViewModel: WeightViewModel(apiClient: MockAPIClient(delayNanoseconds: 0)),
            selectedTab: $selectedTab,
            onLoginRequired: {},
            onProfileRequired: {}
        )
    }
}

struct ProfileSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSummaryPreviewContainer()
    }
}
