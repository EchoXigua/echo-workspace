import SwiftUI

struct ProfileSummaryView: View {
    @StateObject private var viewModel: ProfileSummaryViewModel
    @Binding private var selectedTab: AppTab

    let onLoginRequired: () -> Void
    let onProfileRequired: () -> Void

    init(
        viewModel: ProfileSummaryViewModel,
        selectedTab: Binding<AppTab>,
        onLoginRequired: @escaping () -> Void,
        onProfileRequired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = selectedTab
        self.onLoginRequired = onLoginRequired
        self.onProfileRequired = onProfileRequired
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: LMSpacing.regular) {
                        content
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

            if let milestone = viewModel.milestoneToPresent {
                milestoneOverlay(milestone)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

private extension ProfileSummaryView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            navHeader
            LMStateView(
                kind: .loading,
                title: "正在读取我的计划",
                message: "档案、目标和连续打卡会以后端返回为准。"
            )
        case .visitor:
            navHeader
            LMStateView(
                kind: .empty,
                title: "登录后查看我的计划",
                message: "同步档案、目标热量和连续打卡进度。",
                actionTitle: "去登录",
                action: onLoginRequired
            )
        case .profileIncomplete:
            navHeader
            LMStateView(
                kind: .empty,
                title: "先完成档案",
                message: "生成目标后再展示我的计划和连续打卡。",
                actionTitle: "去填写档案",
                action: onProfileRequired
            )
        case .loaded(let snapshot):
            navHeader
            profileCard(snapshot)
            bodyStats(snapshot.profile)
            streakCard(snapshot.streak)
            planDetails(snapshot.profile)
        case .error(let message, let recovery):
            navHeader
            LMStateView(
                kind: .error,
                title: "我的页加载失败",
                message: message,
                actionTitle: recovery == .login ? "重新登录" : "重试",
                action: recovery == .login ? onLoginRequired : retry
            )
        }
    }

    var navHeader: some View {
        HStack {
            Text("我的")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Button(action: retry) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(LMColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("刷新我的页")
        }
        .frame(height: 52)
    }

    func profileCard(_ snapshot: ProfileSummarySnapshot) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LMColors.primarySoft)
                        .frame(width: 54, height: 54)

                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
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
                }

                Spacer()
            }

            LMTag(
                title: "每日目标 \(snapshot.profile.dailyCalorieTargetKcal) kcal",
                systemImage: "leaf.fill"
            )
        }
    }

    func bodyStats(_ profile: UserProfile) -> some View {
        HStack(spacing: LMSpacing.small) {
            LMMetricTile(title: "当前体重", value: display(profile.currentWeightKg), unit: "kg")
            LMMetricTile(title: "目标体重", value: display(profile.targetWeightKg), unit: "kg", accent: LMColors.primaryDeep)
            LMMetricTile(title: "每日目标", value: "\(profile.dailyCalorieTargetKcal)", unit: "kcal", accent: LMColors.danger)
        }
    }

    func streakCard(_ streak: Streak) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续打卡")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)

                    Text(streakSubtitle(streak))
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak.currentDays)")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(LMColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("天")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }

            HStack(spacing: LMSpacing.small) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("历史最长")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                    Text("\(streak.longestDays) 天")
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textBody)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("最近打卡")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                    Text(lastActiveText(streak.lastActiveDate))
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textBody)
                }
            }

            HStack(spacing: LMSpacing.small) {
                ForEach(streak.milestones) { milestone in
                    LMTag(
                        title: "\(milestone.days)天",
                        systemImage: milestone.achieved ? "checkmark" : nil,
                        style: milestone.achieved ? .primary : .neutral
                    )
                }
            }
        }
    }

    func planDetails(_ profile: UserProfile) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text("数据与计划")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMColors.textBody)

            profileRow(title: "BMI", value: display(profile.bmi), systemImage: "figure")
            profileRow(title: "基础代谢", value: "\(profile.bmrKcal) kcal", systemImage: "flame")
            profileRow(title: "身高", value: "\(display(profile.heightCm)) cm", systemImage: "ruler")
            profileRow(title: "时区", value: profile.timezone, systemImage: "clock")
        }
    }

    func profileRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 34, height: 34)

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }

            Text(title)
                .font(LMTypography.bodyStrong)
                .foregroundStyle(LMColors.textBody)

            Spacer()

            Text(value)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }

    func milestoneOverlay(_ milestone: StreakMilestone) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LMColors.primarySoft)
                        .frame(width: 68, height: 68)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(LMColors.primaryBorder, lineWidth: 1)
                        }

                    Image(systemName: "award")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                }

                Text("连续记录 \(milestone.days) 天")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(milestoneMessage(for: milestone))
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LMButton(title: "知道了", height: 50) {
                    viewModel.dismissMilestone()
                }
            }
            .padding(22)
            .frame(maxWidth: 342)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    func retry() {
        Task {
            await viewModel.refresh()
        }
    }

    func streakSubtitle(_ streak: Streak) -> String {
        if let next = streak.milestones.sorted(by: { $0.days < $1.days }).first(where: { !$0.achieved }) {
            return "下一次里程碑是连续 \(next.days) 天。"
        }
        return "已达成当前全部连续打卡里程碑。"
    }

    func milestoneMessage(for milestone: StreakMilestone) -> String {
        "你已经建立起稳定的记录节奏。系统会继续按后端返回的连续打卡状态展示进度。"
    }

    func lastActiveText(_ date: Date?) -> String {
        guard let date else {
            return "暂无"
        }
        return APICoding.dateString(from: date)
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
