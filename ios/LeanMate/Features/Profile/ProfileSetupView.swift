import SwiftUI

private enum ProfileSetupStep: Int, CaseIterable {
    case basics
    case target
    case review

    var index: Int {
        rawValue
    }

    var title: String {
        switch self {
        case .basics:
            "让目标更贴近你"
        case .target:
            "确认你的目标"
        case .review:
            "生成目标前确认"
        }
    }

    var subtitle: String {
        switch self {
        case .basics:
            "这些信息只用于估算热量目标，之后可以随时改。"
        case .target:
            "目标体重会影响每日推荐热量，后面也可以随时调整。"
        case .review:
            "确认无误后保存，首页会按新的目标展示。"
        }
    }

    var previous: ProfileSetupStep {
        ProfileSetupStep(rawValue: max(rawValue - 1, 0)) ?? .basics
    }

    var next: ProfileSetupStep {
        ProfileSetupStep(rawValue: min(rawValue + 1, Self.allCases.count - 1)) ?? .review
    }
}

struct ProfileSetupView: View {
    @StateObject private var viewModel: ProfileSetupViewModel
    @State private var setupStep: ProfileSetupStep = .basics

    let onCompleted: () -> Void
    let onAuthExpired: () -> Void
    let onSkipped: () -> Void
    let usesBackButtonIcon: Bool

    init(
        viewModel: ProfileSetupViewModel,
        onCompleted: @escaping () -> Void,
        onAuthExpired: @escaping () -> Void,
        onSkipped: @escaping () -> Void = {},
        usesBackButtonIcon: Bool = false
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCompleted = onCompleted
        self.onAuthExpired = onAuthExpired
        self.onSkipped = onSkipped
        self.usesBackButtonIcon = usesBackButtonIcon
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.regular) {
                    topBar
                    header
                    stepProgress
                    stateContent
                }
                .padding(.horizontal, LMSpacing.large)
                .padding(.top, LMSpacing.small)
                .padding(.bottom, LMSpacing.regular)
            }
            .scrollIndicators(.hidden)

            if isSaveSucceeded {
                successBottomAction
                    .padding(.horizontal, LMSpacing.large)
                    .padding(.bottom, LMSpacing.large)
                    .background(LMColors.background)
            } else if showsBottomControls {
                stepControls
                    .padding(.horizontal, LMSpacing.large)
                    .padding(.bottom, LMSpacing.large)
                    .background(LMColors.background)
            }
        }
        .background(LMColors.background.ignoresSafeArea())
        .task {
            await viewModel.loadProfile()
        }
    }
}

private extension ProfileSetupView {
    var topBar: some View {
        ZStack {
            HStack {
                Button(action: onSkipped) {
                    Image(systemName: usesBackButtonIcon ? "chevron.left" : "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x33483A))
                        .frame(width: 42, height: 42)
                        .background(LMColors.card)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(LMColors.border, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(usesBackButtonIcon ? "返回" : "稍后再说")

                Spacer()

                LMTag(title: "\(activeStepIndex + 1)/\(ProfileSetupStep.allCases.count)")
            }

            Text("目标校准")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 52)
    }

    var showsBottomControls: Bool {
        switch viewModel.state {
        case .loadingProfile, .authExpired, .saveSucceeded:
            false
        default:
            true
        }
    }

    var isSaveSucceeded: Bool {
        if case .saveSucceeded = viewModel.state {
            return true
        }
        return false
    }

    var headerTitle: String {
        isSaveSucceeded ? "你的目标已生成" : setupStep.title
    }

    var headerSubtitle: String? {
        isSaveSucceeded ? nil : setupStep.subtitle
    }

    var activeStepIndex: Int {
        isSaveSucceeded ? ProfileSetupStep.allCases.count - 1 : setupStep.index
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headerTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(LMColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let headerSubtitle {
                Text(headerSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var stepProgress: some View {
        HStack(spacing: 6) {
            ForEach(ProfileSetupStep.allCases.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= activeStepIndex ? LMColors.primary : LMColors.primarySoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)
            }
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
            case .basics:
                basicsSection
                calibrationNote
            case .target:
                targetSection
                calibrationNote
            case .review:
                reviewSection
            }

            if case .saveFailed(let message) = viewModel.state {
                LMStateView(
                    kind: .error,
                    title: "保存失败",
                    message: message
                )
            }
        }
    }

    var basicsSection: some View {
        CalibrationCard {
            Text("先填这几项")
                .font(LMTypography.cardTitle)
                .foregroundStyle(Color(hex: 0x33483A))

            genderSection

            HStack(alignment: .top, spacing: LMSpacing.medium) {
                ProfileInputField(
                    title: "年龄",
                    unit: "岁",
                    text: $viewModel.ageText,
                    error: viewModel.fieldErrors[.age],
                    keyboardType: .numberPad
                )
                .frame(maxWidth: .infinity)

                ProfileInputField(
                    title: "身高",
                    unit: "cm",
                    text: $viewModel.heightText,
                    error: viewModel.fieldErrors[.height],
                    keyboardType: .decimalPad
                )
                .frame(maxWidth: .infinity)
            }

            HStack(alignment: .top, spacing: LMSpacing.medium) {
                ProfileInputField(
                    title: "当前体重",
                    unit: "kg",
                    text: $viewModel.currentWeightText,
                    error: viewModel.fieldErrors[.currentWeight],
                    keyboardType: .decimalPad
                )
                .frame(maxWidth: .infinity)

                ActivityPickerField(selection: $viewModel.activityLevel)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var targetSection: some View {
        CalibrationCard {
            Text("目标设置")
                .font(LMTypography.cardTitle)
                .foregroundStyle(Color(hex: 0x33483A))

            ProfileInputField(
                title: "目标体重",
                unit: "kg",
                text: $viewModel.targetWeightText,
                error: viewModel.fieldErrors[.targetWeight],
                keyboardType: .decimalPad
            )
        }
    }

    var reviewSection: some View {
        CalibrationCard {
            Text("确认后生成目标")
                .font(LMTypography.cardTitle)
                .foregroundStyle(Color(hex: 0x33483A))

            HStack(spacing: LMSpacing.small) {
                reviewTile(title: "年龄", value: valueOrPlaceholder(viewModel.ageText), unit: "岁")
                reviewTile(title: "身高", value: valueOrPlaceholder(viewModel.heightText), unit: "cm")
            }

            HStack(spacing: LMSpacing.small) {
                reviewTile(title: "当前体重", value: valueOrPlaceholder(viewModel.currentWeightText), unit: "kg")
                reviewTile(title: "目标体重", value: valueOrPlaceholder(viewModel.targetWeightText), unit: "kg")
            }

            HStack(spacing: LMSpacing.small) {
                reviewTile(title: "性别", value: viewModel.gender.title, unit: nil)
                reviewTile(title: "活动水平", value: viewModel.activityLevel.title, unit: nil)
            }
        }
    }

    var calibrationNote: some View {
        HStack(alignment: .center, spacing: LMSpacing.small) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LMColors.primary)

            Text("可以先填大概值，后面在我的页面随时微调。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 41, alignment: .leading)
        .background(LMColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var genderSection: some View {
        VStack(alignment: .leading, spacing: LMSpacing.small) {
            Text("性别")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(spacing: LMSpacing.small) {
                ForEach(calibrationGenderOptions) { gender in
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

    var calibrationGenderOptions: [Gender] {
        [.female, .male, .unknown]
    }

    var stepControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: LMSpacing.small) {
                if setupStep != .basics {
                    LMButton(
                        title: "上一步",
                        systemImage: "chevron.left",
                        role: .secondary,
                        height: 48
                    ) {
                        setupStep = setupStep.previous
                    }
                }

                CalibrationPrimaryButton(
                    title: setupStep == .review ? "生成目标" : "下一步",
                    isLoading: viewModel.isSaving
                ) {
                    if setupStep == .review {
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

            Button(action: onSkipped) {
                Text("稍后再说")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            .buttonStyle(.plain)
        }
    }

    func focusFirstInvalidField() {
        if viewModel.fieldErrors.keys.contains(where: { $0 == .age || $0 == .height || $0 == .currentWeight }) {
            setupStep = .basics
        } else if !viewModel.fieldErrors.isEmpty {
            setupStep = .target
        }
    }

    func reviewTile(title: String, value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let unit {
                    Text(unit)
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(LMColors.inputBorder, lineWidth: 1)
        }
    }

    var successContent: some View {
        VStack(alignment: .leading, spacing: LMSpacing.regular) {
            if let profile = viewModel.savedProfile {
                successResultCard(profile)
            } else {
                successFallbackCard
            }
        }
    }

    var successBottomAction: some View {
        CalibrationPrimaryButton(
            title: "进入首页",
            systemImage: "house"
        ) {
            onCompleted()
        }
    }

    func successResultCard(_ profile: UserProfile) -> some View {
        let bmiPresentation = bmiStatusPresentation(profile.bmi)

        return CalibrationCard {
            successCardHeader
            dailyCalorieHero(profile.dailyCalorieTargetKcal)

            HStack(spacing: LMSpacing.small) {
                SuccessMetricCard(
                    title: "BMI",
                    value: display(profile.bmi),
                    unit: bmiPresentation.label,
                    unitColor: bmiPresentation.accent
                )

                SuccessMetricCard(
                    title: "BMR",
                    value: "\(profile.bmrKcal)",
                    unit: "kcal"
                )
            }

            successNote(bmiPresentation)
        }
    }

    var successFallbackCard: some View {
        CalibrationCard {
            successCardHeader

            Text("目标已保存，首页将按新的热量目标展示。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var successCardHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LMColors.primary)
                .frame(width: 38, height: 38)
                .background(LMColors.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("今日目标已准备好")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("保存后会同步到首页热量目标和饮食记录计算。")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func dailyCalorieHero(_ calorieTarget: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("每日推荐热量")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(calorieTarget)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("kcal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            Text("先按这个目标执行，后续体重变化后可以再微调。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xF4FBF6))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(LMColors.primaryBorder, lineWidth: 1)
        }
    }

    func successNote(_ presentation: BMIStatusPresentation) -> some View {
        HStack(alignment: .center, spacing: LMSpacing.small) {
            BMIStatusIconView(kind: presentation.icon, color: presentation.accent)
                .frame(width: 16, height: 16)

            Text(presentation.message)
                .font(LMTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(presentation.textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(presentation.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(presentation.border, lineWidth: 1)
        }
    }

    func bmiStatusPresentation(_ value: Double) -> BMIStatusPresentation {
        switch value {
        case ..<18.5:
            BMIStatusPresentation(
                label: "偏低",
                icon: .system("info.circle"),
                message: "当前/目标体重偏低，建议关注营养摄入，必要时咨询专业人士。",
                accent: Color(hex: 0x247F9E),
                textColor: Color(hex: 0x2D6171),
                background: Color(hex: 0xEAF8FF),
                border: Color(hex: 0xBDE5F3)
            )
        case ..<24:
            BMIStatusPresentation(
                label: "健康",
                icon: .system("checkmark.circle"),
                message: "当前范围较健康，继续保持稳定记录。",
                accent: LMColors.primary,
                textColor: Color(hex: 0x248A58),
                background: LMColors.primarySoft,
                border: LMColors.primaryBorder
            )
        case ..<28:
            BMIStatusPresentation(
                label: "偏高",
                icon: .system("exclamationmark.circle"),
                message: "当前体重偏高，建议用温和节奏调整，不建议极端节食。",
                accent: Color(hex: 0xA86B00),
                textColor: Color(hex: 0x805514),
                background: Color(hex: 0xFFF8E8),
                border: Color(hex: 0xF1D27D)
            )
        default:
            BMIStatusPresentation(
                label: "较高",
                icon: .heartPulse,
                message: "当前体重较高，建议以长期可持续方式调整；如有基础疾病建议咨询医生。",
                accent: Color(hex: 0xB85C20),
                textColor: Color(hex: 0x81452C),
                background: Color(hex: 0xFFF0E8),
                border: Color(hex: 0xF0B58D)
            )
        }
    }

    func display(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    func valueOrPlaceholder(_ text: String) -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "未填" : value
    }
}

private enum BMIStatusIconKind {
    case system(String)
    case heartPulse
}

private struct BMIStatusPresentation {
    let label: String
    let icon: BMIStatusIconKind
    let message: String
    let accent: Color
    let textColor: Color
    let background: Color
    let border: Color
}

private struct BMIStatusIconView: View {
    let kind: BMIStatusIconKind
    let color: Color

    var body: some View {
        switch kind {
        case let .system(systemName):
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
        case .heartPulse:
            HeartPulseIcon(color: color)
        }
    }
}

private struct HeartPulseIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            heartPath
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )

            pulsePath
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(width: 16, height: 16)
    }

    private var heartPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 8, y: 13.2))
            path.addCurve(
                to: CGPoint(x: 1.9, y: 6.9),
                control1: CGPoint(x: 4.1, y: 10.3),
                control2: CGPoint(x: 1.9, y: 8.8)
            )
            path.addCurve(
                to: CGPoint(x: 5.0, y: 3.7),
                control1: CGPoint(x: 1.9, y: 5.1),
                control2: CGPoint(x: 3.2, y: 3.7)
            )
            path.addCurve(
                to: CGPoint(x: 8, y: 5.2),
                control1: CGPoint(x: 6.2, y: 3.7),
                control2: CGPoint(x: 7.1, y: 4.3)
            )
            path.addCurve(
                to: CGPoint(x: 11.0, y: 3.7),
                control1: CGPoint(x: 8.9, y: 4.3),
                control2: CGPoint(x: 9.8, y: 3.7)
            )
            path.addCurve(
                to: CGPoint(x: 14.1, y: 6.9),
                control1: CGPoint(x: 12.8, y: 3.7),
                control2: CGPoint(x: 14.1, y: 5.1)
            )
            path.addCurve(
                to: CGPoint(x: 8, y: 13.2),
                control1: CGPoint(x: 14.1, y: 8.8),
                control2: CGPoint(x: 11.9, y: 10.3)
            )
        }
    }

    private var pulsePath: Path {
        Path { path in
            path.move(to: CGPoint(x: 3.0, y: 8.1))
            path.addLine(to: CGPoint(x: 5.3, y: 8.1))
            path.addLine(to: CGPoint(x: 6.5, y: 6.2))
            path.addLine(to: CGPoint(x: 8.1, y: 10.3))
            path.addLine(to: CGPoint(x: 9.5, y: 8.1))
            path.addLine(to: CGPoint(x: 13.0, y: 8.1))
        }
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
                .frame(height: 42)
                .background(isSelected ? LMColors.primarySoft : LMColors.warmSurface)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(isSelected ? LMColors.primary : Color(hex: 0xE9DCC8), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct CalibrationCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: LMSpacing.regular) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
        .shadow(color: Color(hex: 0x143B23, alpha: 0.04), radius: 8, x: 0, y: 2)
    }
}

private struct CalibrationPrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LMSpacing.small) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(LMColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

private struct SuccessMetricCard: View {
    let title: String
    let value: String
    var unit: String?
    var unitColor: Color = LMColors.textSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let unit {
                    Text(unit)
                        .font(LMTypography.badge)
                        .foregroundStyle(unitColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color(hex: 0xE9DCC8), lineWidth: 1)
        }
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
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)

                HStack(spacing: LMSpacing.small) {
                    TextField(title, text: $text)
                        .keyboardType(keyboardType)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)
                        .lineLimit(1)
                        .frame(height: 25)

                    Text(unit)
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 71)
            .background(LMColors.warmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(error == nil ? Color(hex: 0xE9DCC8) : LMColors.danger, lineWidth: 1)
            }

            if let error {
                Text(error)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.danger)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 16, alignment: .topLeading)
            }
        }
    }
}

private struct ActivityPickerField: View {
    @Binding var selection: ActivityLevel

    var body: some View {
        Menu {
            ForEach(ActivityLevel.allCases) { level in
                Button(level.title) {
                    selection = level
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text("活动水平")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)

                HStack(spacing: LMSpacing.small) {
                    Text(selection.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.textBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LMColors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 71)
            .background(LMColors.warmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color(hex: 0xE9DCC8), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
            "暂不选"
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
