import SwiftUI

struct ProfileDataPlanDetailView: View {
    let payload: ProfileRoutePayload
    let onBack: () -> Void
    let onEditProfile: () -> Void

    var body: some View {
        ProfileSubpageScaffold(title: "数据与计划", onBack: onBack) {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("热量计划")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LMColors.textPrimary)

                    Spacer()

                    Text("按日常消耗估算")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("每日目标")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(calorieValue)
                                .font(.system(size: 31, weight: .bold))
                                .foregroundStyle(LMColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Text("kcal")
                                .font(LMTypography.bodyStrong)
                                .foregroundStyle(LMColors.textSecondary)
                        }
                    }

                    Spacer()

                    Text("可按状态调整")
                        .font(LMTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(LMColors.primaryDeep)
                }
                .padding(.horizontal, 14)
                .frame(height: 78)
                .frame(maxWidth: .infinity)
                .background(LMColors.primarySoft.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(LMColors.primary, lineWidth: 1)
                }

                HStack(spacing: LMSpacing.small) {
                    ProfileCompactMetricCard(title: "基础代谢", value: payload.bmr)
                    ProfileCompactMetricCard(title: "BMI", value: payload.bmi)
                    ProfileCompactMetricCard(title: "活动", value: payload.activityLevel)
                }
            }

            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("身体档案")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LMColors.textPrimary)

                    Spacer()

                    Button(action: onEditProfile) {
                        Text("编辑")
                            .font(LMTypography.badge)
                            .foregroundStyle(LMColors.primaryDeep)
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 0) {
                    ProfileIconInfoRow(title: "当前体重", value: payload.currentWeight, systemImage: LMWeightScaleIcon.symbolName)
                    ProfileIconInfoRow(title: "目标体重", value: payload.targetWeight, systemImage: "target")
                    ProfileIconInfoRow(title: "身高", value: payload.height, systemImage: "ruler")
                    ProfileIconInfoRow(title: "年龄与性别", value: ageGenderText, systemImage: "person")
                }
            }
        }
    }

    private var calorieValue: String {
        payload.dailyTarget.replacingOccurrences(of: " kcal", with: "")
    }

    private var ageGenderText: String {
        let parts = payload.summary.components(separatedBy: " · ")
        guard parts.count >= 2 else {
            return payload.summary
        }
        return "\(parts[0]) · \(parts[1])"
    }
}

struct ProfileWeightTrendView: View {
    let payload: ProfileRoutePayload
    let onBack: () -> Void
    @StateObject private var weightViewModel: WeightViewModel
    @State private var showsWeightSheet = false
    @State private var showsHistoryHint = false

    init(
        payload: ProfileRoutePayload,
        weightViewModel: WeightViewModel,
        onBack: @escaping () -> Void
    ) {
        self.payload = payload
        self.onBack = onBack
        _weightViewModel = StateObject(wrappedValue: weightViewModel)
    }

    var body: some View {
        ProfileSubpageScaffold(title: "体重趋势", onBack: onBack) {
            ProfileTrendSummaryCard(payload: payload)
            ProfileTrendChartCard(payload: payload)

            HStack(spacing: LMSpacing.small) {
                ProfileTrendActionButton(
                    title: "记录体重",
                    systemImage: "plus",
                    style: .primary,
                    action: openWeightSheet
                )

                ProfileTrendActionButton(
                    title: "历史记录",
                    systemImage: "list.bullet",
                    style: .secondary
                ) {
                    showsHistoryHint = true
                }
            }
        }
        .sheet(isPresented: $showsWeightSheet) {
            WeightEntrySheet(viewModel: weightViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(LMColors.background)
        }
        .alert("历史记录", isPresented: $showsHistoryHint) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("体重历史会在后续整理成列表，目前先按最近记录展示趋势。")
        }
    }

    private func openWeightSheet() {
        weightViewModel.resetForNewEntry(defaultWeightKg: payload.currentWeightKg)
        showsWeightSheet = true
    }
}

struct ProfileDataSyncView: View {
    let isVisitor: Bool
    let onBack: () -> Void
    let onLoginRequired: () -> Void

    var body: some View {
        ProfileSubpageScaffold(title: "数据同步", onBack: onBack) {
            LMCard(cornerRadius: 16, padding: 14) {
                Image(systemName: isVisitor ? "icloud.and.arrow.up" : "checkmark.icloud")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
                    .frame(width: 46, height: 46)
                    .background(LMColors.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("同步数据")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                Text(isVisitor ? "把本地记录保存到账号，之后可在其他设备继续使用。" : "当前记录已跟随账号保留，后续设备切换时会继续同步。")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LMCard(cornerRadius: 16, padding: 14) {
                Text("将同步这些内容")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                VStack(spacing: 0) {
                    ProfileIconInfoRow(title: "饮食记录", value: syncValue, systemImage: "fork.knife")
                    ProfileIconInfoRow(title: "体重记录", value: syncValue, systemImage: LMWeightScaleIcon.symbolName)
                    ProfileIconInfoRow(title: "身体档案", value: syncValue, systemImage: "person.text.rectangle")
                }
            }

            LMButton(
                title: isVisitor ? "登录同步" : "完成",
                systemImage: isVisitor ? "arrow.up.right.circle" : "checkmark",
                action: isVisitor ? onLoginRequired : onBack
            )

            Button(action: onBack) {
                Text("稍后再说")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: 0xF6FBF7))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var syncValue: String {
        isVisitor ? "本地已保存" : "账号已保存"
    }
}

struct ProfileSettingsView: View {
    let payload: ProfileRoutePayload?
    let isVisitor: Bool
    let onBack: () -> Void
    let onLoginRequired: () -> Void
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        ProfileSubpageScaffold(title: "设置", onBack: onBack) {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "iphone")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                        .frame(width: 38, height: 38)
                        .background(LMColors.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isVisitor ? "当前数据保存在本机" : "账号数据已开启")
                            .font(LMTypography.bodyStrong)
                            .foregroundStyle(LMColors.textBody)

                        Text(isVisitor ? "登录后可同步到账号，当前不影响本地使用。" : "饮食、体重和身体档案会跟随账号保留。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if isVisitor {
                        Button(action: onLoginRequired) {
                            Text("登录")
                                .font(LMTypography.badge)
                                .foregroundStyle(LMColors.primaryDeep)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(LMColors.primarySoft)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            settingsSection(
                title: "档案与目标",
                rows: [
                    ProfileSettingsRowData(title: "身体档案", subtitle: "年龄、身高、活动水平", systemImage: "person", destination: .profileEdit),
                    ProfileSettingsRowData(title: "目标计划", subtitle: "目标体重、每日热量", systemImage: "target", destination: .dataPlan),
                    ProfileSettingsRowData(title: "体重记录", subtitle: "记录入口与趋势偏好", systemImage: LMWeightScaleIcon.symbolName, destination: .weightTrend)
                ]
            )

            settingsSection(
                title: "数据",
                rows: [
                    ProfileSettingsRowData(title: "数据同步", subtitle: "登录后自动保留饮食和体重", systemImage: "arrow.triangle.2.circlepath", destination: .dataSync),
                    ProfileSettingsRowData(title: "隐私与本地数据", subtitle: "查看本机保存范围", systemImage: "shield")
                ]
            )

            settingsSection(
                title: "提醒",
                rows: [
                    ProfileSettingsRowData(title: "记录提醒", subtitle: "按你的节奏提醒补记录", systemImage: "bell"),
                    ProfileSettingsRowData(title: "里程碑提示", subtitle: "连续记录达成时轻提示", systemImage: "sparkles")
                ]
            )

            settingsSection(
                title: "关于",
                rows: [
                    ProfileSettingsRowData(title: "LeanMate", subtitle: "版本、协议与反馈", systemImage: "info.circle")
                ]
            )
        }
    }

    private func settingsSection(title: String, rows: [ProfileSettingsRowData]) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text(title)
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    ProfileSettingsRow(row: row, route: route(for: row.destination), onNavigate: onNavigate)
                }
            }
        }
    }

    private func route(for destination: ProfileSettingsDestination?) -> AppRoute? {
        switch destination {
        case .profileEdit:
            if let payload {
                .profileEdit(payload)
            } else {
                .profileSetup
            }
        case .dataPlan:
            if let payload {
                .profileDataPlan(payload)
            } else {
                .profileSetup
            }
        case .weightTrend:
            if let payload {
                .profileWeightTrend(payload)
            } else {
                .profileSetup
            }
        case .dataSync:
            .profileDataSync
        case nil:
            nil
        }
    }
}

struct ProfileEditView: View {
    @StateObject private var viewModel: ProfileSetupViewModel
    let onBack: () -> Void
    let onCompleted: () -> Void
    let onAuthExpired: () -> Void

    init(
        viewModel: ProfileSetupViewModel,
        onBack: @escaping () -> Void,
        onCompleted: @escaping () -> Void,
        onAuthExpired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBack = onBack
        self.onCompleted = onCompleted
        self.onAuthExpired = onAuthExpired
    }

    var body: some View {
        ProfileSubpageScaffold(title: "身体档案", onBack: onBack) {
            switch viewModel.state {
            case .idle, .loadingProfile:
                LMStateView(kind: .loading, title: "正在读取档案", message: "读取后可直接修改。")
            case .authExpired:
                LMStateView(kind: .error, title: "登录已失效", message: "请重新登录后修改档案。", actionTitle: "重新登录", action: onAuthExpired)
            default:
                editContent
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

private extension ProfileEditView {
    var editContent: some View {
        VStack(alignment: .leading, spacing: LMSpacing.large) {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("基础信息")
                        .font(LMTypography.cardTitle)
                        .foregroundStyle(LMColors.textBody)

                    Spacer()

                    Text("用于估算热量，可随时修改")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.textSecondary)
                }

                HStack(spacing: LMSpacing.small) {
                    genderButton(.female)
                    genderButton(.male)
                    genderButton(.unknown)
                }

                HStack(spacing: LMSpacing.small) {
                    ProfileEditInputField(
                        title: "年龄",
                        unit: "岁",
                        text: $viewModel.ageText,
                        error: viewModel.fieldErrors[.age],
                        keyboardType: .numberPad
                    )
                    ProfileEditInputField(
                        title: "身高",
                        unit: "cm",
                        text: $viewModel.heightText,
                        error: viewModel.fieldErrors[.height],
                        keyboardType: .decimalPad
                    )
                }

                HStack(spacing: LMSpacing.small) {
                    ProfileEditInputField(
                        title: "当前体重",
                        unit: "kg",
                        text: $viewModel.currentWeightText,
                        error: viewModel.fieldErrors[.currentWeight],
                        keyboardType: .decimalPad
                    )
                    ProfileEditInputField(
                        title: "目标体重",
                        unit: "kg",
                        text: $viewModel.targetWeightText,
                        error: viewModel.fieldErrors[.targetWeight],
                        keyboardType: .decimalPad
                    )
                }

                ProfileEditActivityField(selection: $viewModel.activityLevel)
            }

            stateMessage

            LMButton(
                title: "保存修改",
                systemImage: viewModel.isSaving ? nil : "checkmark",
                isLoading: viewModel.isSaving,
                action: save
            )
        }
    }

    @ViewBuilder
    var stateMessage: some View {
        switch viewModel.state {
        case .localValidationFailed:
            LMStateView(kind: .error, title: "请检查信息", message: "红色标注的内容需要调整后再保存。")
        case .saveFailed(let message):
            LMStateView(kind: .error, title: "保存失败", message: message)
        default:
            EmptyView()
        }
    }

    func genderButton(_ gender: Gender) -> some View {
        Button {
            viewModel.gender = gender
        } label: {
            Text(gender.editTitle)
                .font(LMTypography.bodyStrong)
                .foregroundStyle(viewModel.gender == gender ? LMColors.primaryDeep : LMColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(viewModel.gender == gender ? LMColors.primarySoft : LMColors.warmSurface)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(viewModel.gender == gender ? LMColors.primary : LMColors.inputBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    func save() {
        Task {
            if await viewModel.save() {
                onCompleted()
            }
        }
    }
}

private struct ProfileSettingsRowData: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let systemImage: String
    var destination: ProfileSettingsDestination?
}

private enum ProfileSettingsDestination {
    case profileEdit
    case dataPlan
    case weightTrend
    case dataSync
}

private struct ProfileSettingsRow: View {
    let row: ProfileSettingsRowData
    let route: AppRoute?
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        if let route {
            Button {
                onNavigate(route)
            } label: {
                rowContent(showsChevron: true)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(row.title)
        } else {
            rowContent(showsChevron: false)
                .accessibilityElement(children: .combine)
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            icon(systemImage: row.systemImage)

            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)

                Text(row.subtitle)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LMColors.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 54)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func icon(systemImage: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LMColors.primarySoft)
                .frame(width: 34, height: 34)

            if systemImage == LMWeightScaleIcon.symbolName {
                LMWeightScaleIcon(size: 15, color: LMColors.primary)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }
        }
    }
}

private struct ProfileEditInputField: View {
    let title: String
    let unit: String
    @Binding var text: String
    let error: String?
    let keyboardType: UIKeyboardType
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)

                HStack(spacing: LMSpacing.small) {
                    TextField(title, text: $text)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)
                        .lineLimit(1)
                        .toolbar {
                            if isFocused {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("完成") {
                                        isFocused = false
                                    }
                                }
                            }
                        }

                    Text(unit)
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textSecondary)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 74)
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .onTapGesture {
                isFocused = true
            }
            .background(LMColors.warmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(error == nil ? LMColors.inputBorder : LMColors.danger, lineWidth: 1)
            }

            if let error {
                Text(error)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.danger)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileEditActivityField: View {
    @Binding var selection: ActivityLevel

    var body: some View {
        Menu {
            ForEach(ActivityLevel.allCases) { level in
                Button(level.editTitle) {
                    selection = level
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
                    .frame(width: 34, height: 34)
                    .background(LMColors.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("活动水平")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)

                    Text(selection.editTitle)
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textBody)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }
            .padding(12)
            .background(LMColors.warmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(LMColors.inputBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileSubpageScaffold<Content: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ProfileSubpageHeader(title: title, onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.large) {
                    content
                }
                .padding(.horizontal, LMSpacing.large)
                .padding(.top, LMSpacing.medium)
                .padding(.bottom, 28)
            }
        }
        .background(LMColors.background.ignoresSafeArea())
    }
}

private struct ProfileSubpageHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(LMColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LMColors.border, lineWidth: 1)
                    }
            }
            .accessibilityHidden(true)

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, LMSpacing.large)
        .padding(.bottom, LMSpacing.small)
        .background(LMColors.background)
        .overlay(alignment: .topLeading) {
            Button(action: onBack) {
                Color.clear
                    .frame(width: 82, height: 82)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回")
            .offset(x: 0, y: -24)
        }
    }
}

private struct ProfileCompactMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(LMTypography.badge)
                .foregroundStyle(LMColors.textSecondary)

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(Color(hex: 0xF6FBF7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }
}

private struct ProfileIconInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            icon

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(height: 42)
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LMColors.primarySoft)
                .frame(width: 28, height: 28)

            if systemImage == LMWeightScaleIcon.symbolName {
                LMWeightScaleIcon(size: 13, color: LMColors.primary)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }
        }
    }
}

private struct ProfileTrendSummaryCard: View {
    let payload: ProfileRoutePayload

    var body: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("近 30 天变化")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                Spacer()

                Text("30天")
                    .font(LMTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(LMColors.primaryDeep)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(changeValue)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(changeColor)

                Text("kg")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(changeColor)

                Text("本周变化")
                    .font(LMTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(changeColor)
            }

            Text("目标 \(payload.targetWeight) · 当前 \(payload.currentWeight)")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
    }

    private var changeValue: String {
        guard let value = payload.weeklyWeightChangeKg else {
            return "--"
        }
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(display(value))"
    }

    private var changeColor: Color {
        guard let value = payload.weeklyWeightChangeKg else {
            return LMColors.textSecondary
        }
        return value > 0 ? LMColors.danger : LMColors.primaryDeep
    }

    private func display(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct ProfileTrendChartCard: View {
    let payload: ProfileRoutePayload

    private let bars: [(label: String, height: CGFloat, isRecent: Bool)] = [
        ("6/3", 104, false),
        ("6/4", 98, false),
        ("6/5", 94, false),
        ("6/6", 88, false),
        ("6/7", 84, true),
        ("6/8", 80, true),
        ("今天", 76, true)
    ]

    var body: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("体重记录")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                Spacer()

                Text("按记录时间展示")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            HStack(alignment: .bottom, spacing: 9) {
                ForEach(bars, id: \.label) { item in
                    VStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(item.isRecent ? LMColors.primary : LMColors.border)
                            .frame(width: 22, height: item.height)

                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(LMColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 130, alignment: .bottom)
                }
            }
            .frame(height: 154)

            HStack(spacing: 8) {
                Capsule()
                    .fill(LMColors.primary)
                    .frame(width: 26, height: 4)

                Text("目标体重 \(payload.targetWeight)")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }
        }
    }
}

private enum ProfileTrendActionStyle {
    case primary
    case secondary
}

private struct ProfileTrendActionButton: View {
    let title: String
    let systemImage: String
    let style: ProfileTrendActionStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        style == .primary ? .white : LMColors.primary
    }

    private var backgroundColor: Color {
        style == .primary ? LMColors.primary : LMColors.card
    }

    private var borderColor: Color {
        style == .primary ? .clear : LMColors.border
    }
}

private extension Gender {
    var editTitle: String {
        switch self {
        case .male:
            "男"
        case .female:
            "女"
        case .unknown:
            "暂不选"
        }
    }
}

private extension ActivityLevel {
    var editTitle: String {
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
