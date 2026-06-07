import SwiftUI

private enum ProfileSetupStep: Int, CaseIterable {
    case goal
    case profile
    case metrics

    var index: Int {
        rawValue
    }

    var title: String {
        switch self {
        case .goal:
            "先生成你的减脂目标"
        case .profile:
            "再确认基础信息"
        case .metrics:
            "最后确认体重目标"
        }
    }

    var subtitle: String {
        switch self {
        case .goal:
            "先选择日常活动水平，系统会结合档案计算每日推荐热量。"
        case .profile:
            "这些字段只用于 BMI、BMR 和目标热量计算。"
        case .metrics:
            "保存后以后端返回的 BMI、BMR 和每日热量目标为准。"
        }
    }

    var previous: ProfileSetupStep {
        ProfileSetupStep(rawValue: max(rawValue - 1, 0)) ?? .goal
    }

    var next: ProfileSetupStep {
        ProfileSetupStep(rawValue: min(rawValue + 1, Self.allCases.count - 1)) ?? .metrics
    }
}

struct ProfileSetupView: View {
    @StateObject private var viewModel: ProfileSetupViewModel
    @State private var setupStep: ProfileSetupStep = .goal

    let onCompleted: () -> Void
    let onAuthExpired: () -> Void

    init(
        viewModel: ProfileSetupViewModel,
        onCompleted: @escaping () -> Void,
        onAuthExpired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCompleted = onCompleted
        self.onAuthExpired = onAuthExpired
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LMSpacing.regular) {
                StepDots(activeIndex: setupStep.index)
                header
                stateContent
            }
            .padding(.horizontal, LMSpacing.large)
            .padding(.top, LMSpacing.small)
            .padding(.bottom, 28)
        }
        .background(LMColors.background.ignoresSafeArea())
        .task {
            await viewModel.loadProfile()
        }
    }
}

private extension ProfileSetupView {
    var header: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text(setupStep.title)
                .font(LMTypography.title)
                .foregroundStyle(LMColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(setupStep.subtitle)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    var stateContent: some View {
        switch viewModel.state {
        case .loadingProfile:
            LMStateView(
                kind: .loading,
                title: "正在读取档案",
                message: "如果已经填写过，会自动带入已有内容。"
            )
        case .authExpired:
            LMStateView(
                kind: .error,
                title: "登录状态已失效",
                message: "请重新登录后再保存档案。",
                actionTitle: "返回登录",
                action: onAuthExpired
            )
        case .saveSucceeded:
            successContent
        default:
            formContent
        }
    }

    var formContent: some View {
        VStack(alignment: .leading, spacing: LMSpacing.regular) {
            switch setupStep {
            case .goal:
                activitySection
            case .profile:
                genderSection
                ProfileInputField(
                    title: "年龄",
                    unit: "岁",
                    text: $viewModel.ageText,
                    error: viewModel.fieldErrors[.age],
                    keyboardType: .numberPad
                )
                ProfileInputField(
                    title: "身高",
                    unit: "cm",
                    text: $viewModel.heightText,
                    error: viewModel.fieldErrors[.height],
                    keyboardType: .decimalPad
                )
            case .metrics:
                ProfileInputField(
                    title: "当前体重",
                    unit: "kg",
                    text: $viewModel.currentWeightText,
                    error: viewModel.fieldErrors[.currentWeight],
                    keyboardType: .decimalPad
                )
                ProfileInputField(
                    title: "目标体重",
                    unit: "kg",
                    text: $viewModel.targetWeightText,
                    error: viewModel.fieldErrors[.targetWeight],
                    keyboardType: .decimalPad
                )
                timezoneSection
            }

            if case .saveFailed(let message) = viewModel.state {
                LMStateView(
                    kind: .error,
                    title: "保存失败",
                    message: message
                )
            }

            stepControls
        }
    }

    var genderSection: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text("性别")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(spacing: LMSpacing.small) {
                ForEach(Gender.allCases) { gender in
                    SelectPill(
                        title: gender.title,
                        isSelected: viewModel.gender == gender
                    ) {
                        viewModel.gender = gender
                    }
                }
            }
        }
    }

    var activitySection: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text("活动水平")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            VStack(spacing: LMSpacing.medium) {
                ForEach(ActivityLevel.allCases) { level in
                    ActivityLevelRow(
                        title: level.title,
                        subtitle: level.subtitle,
                        isSelected: viewModel.activityLevel == level
                    ) {
                        viewModel.activityLevel = level
                    }
                }
            }
        }
    }

    var stepControls: some View {
        HStack(spacing: LMSpacing.small) {
            if setupStep != .goal {
                LMButton(
                    title: "上一步",
                    systemImage: "chevron.left",
                    role: .secondary,
                    height: 48
                ) {
                    setupStep = setupStep.previous
                }
            }

            LMButton(
                title: setupStep == .metrics ? "生成目标" : "下一步",
                systemImage: setupStep == .metrics ? "checkmark.circle" : "arrow.right",
                height: setupStep == .metrics ? 54 : 48,
                isLoading: viewModel.isSaving
            ) {
                if setupStep == .metrics {
                    Task {
                        let didSave = await viewModel.save()
                        if !didSave {
                            focusFirstInvalidField()
                        }
                    }
                } else {
                    setupStep = setupStep.next
                }
            }
        }
    }

    func focusFirstInvalidField() {
        if viewModel.fieldErrors.keys.contains(where: { $0 == .age || $0 == .height }) {
            setupStep = .profile
        } else if !viewModel.fieldErrors.isEmpty {
            setupStep = .metrics
        }
    }

    var timezoneSection: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text("时区")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(spacing: LMSpacing.small) {
                Image(systemName: "clock")
                    .foregroundStyle(LMColors.primary)

                Text(viewModel.timezoneIdentifier)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()
            }
            .padding(14)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        viewModel.fieldErrors[.timezone] == nil ? LMColors.inputBorder : LMColors.danger,
                        lineWidth: 1
                    )
            }

            if let error = viewModel.fieldErrors[.timezone] {
                Text(error)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.danger)
            }
        }
    }

    var successContent: some View {
        VStack(alignment: .leading, spacing: LMSpacing.regular) {
            LMTag(title: "目标已生成")

            Text("这是后端返回的本次目标结果。")
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            if let profile = viewModel.savedProfile {
                HStack(spacing: LMSpacing.small) {
                    LMMetricTile(title: "BMI", value: display(profile.bmi))
                    LMMetricTile(title: "BMR", value: "\(profile.bmrKcal)", unit: "kcal")
                }

                LMMetricTile(
                    title: "每日推荐热量",
                    value: "\(profile.dailyCalorieTargetKcal)",
                    unit: "kcal"
                )
            }

            LMButton(
                title: "进入首页",
                systemImage: "house"
            ) {
                onCompleted()
            }
        }
    }

    func display(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct StepDots: View {
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index == activeIndex ? LMColors.primary : LMColors.inputBorder)
                    .frame(width: index == activeIndex ? 22 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SelectPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LMTypography.bodyStrong)
                .foregroundStyle(isSelected ? LMColors.primaryDeep : LMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? LMColors.primarySoft : LMColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? LMColors.primary : LMColors.inputBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct ProfileInputField: View {
    let title: String
    let unit: String
    @Binding var text: String
    let error: String?
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(spacing: LMSpacing.small) {
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Text(unit)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textSecondary)
            }
            .padding(14)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(error == nil ? LMColors.inputBorder : LMColors.danger, lineWidth: 1)
            }

            if let error {
                Text(error)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ActivityLevelRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? LMColors.primary : LMColors.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textBody)

                    Text(subtitle)
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? LMColors.primarySoft : LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? LMColors.primary : LMColors.inputBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
            "暂不选择"
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
            "非常活跃"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary:
            "大多时间坐着，很少运动"
        case .light:
            "日常走动，偶尔轻运动"
        case .moderate:
            "每周有规律运动"
        case .active:
            "运动频率高或体力活动多"
        case .veryActive:
            "高强度训练或体力工作"
        }
    }
}

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView(
            viewModel: ProfileSetupViewModel(
                apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0),
                timezoneIdentifier: "Asia/Shanghai"
            ),
            onCompleted: {},
            onAuthExpired: {}
        )
    }
}
