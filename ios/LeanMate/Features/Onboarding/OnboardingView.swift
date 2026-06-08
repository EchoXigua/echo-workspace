import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    let onProfileRequired: () -> Void
    let onCompleted: () -> Void
    let onVisitorPreview: () -> Void

    init(
        viewModel: OnboardingViewModel,
        onProfileRequired: @escaping () -> Void,
        onCompleted: @escaping () -> Void,
        onVisitorPreview: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onProfileRequired = onProfileRequired
        self.onCompleted = onCompleted
        self.onVisitorPreview = onVisitorPreview
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                brandStack
                    .padding(.top, topPadding(for: geometry.size.height))

                Spacer(minLength: 0)

                VStack(spacing: LMSpacing.regular) {
                    todayPreviewCard

                    if case .loginFailed(let message) = viewModel.state {
                        LMStateView(
                            kind: .error,
                            title: "登录失败",
                            message: message
                        )
                    }
                }

                Spacer(minLength: 0)

                actionsStack
                    .padding(.bottom, bottomPadding(for: geometry.size.height))
            }
            .padding(.horizontal, 28)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .background(LMColors.background.ignoresSafeArea())
    }
}

private extension OnboardingView {
    var brandStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LMColors.primary)
                    .frame(width: 86, height: 86)

                Text("卡")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                Text("LeanMate")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("少点焦虑，多点好好吃饭")
                    .font(.system(size: 13))
                    .foregroundStyle(LMColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var actionsStack: some View {
        VStack(spacing: 12) {
            LMButton(
                title: "开始记录",
                isLoading: viewModel.isLoggingIn
            ) {
                Task {
                    await handleLogin()
                }
            }

            Button(action: onVisitorPreview) {
                Text("随便看看")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.primaryDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LMColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(LMColors.primaryBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("随便看看")
        }
    }

    var todayPreviewCard: some View {
        LMCard(cornerRadius: 18, padding: 16) {
            LMTag(title: "今天还能吃 863 千卡")

            Text("把记录变成生活节奏，而不是表格任务。")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: LMSpacing.small) {
                previewMetric(label: "早餐", value: "268")
                previewMetric(label: "喝水", value: "900ml")
                previewMetric(label: "蛋白", value: "42g")
            }
        }
    }

    func previewMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LMColors.textSecondary)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func topPadding(for height: CGFloat) -> CGFloat {
        min(max(height * 0.08, 54), 78)
    }

    func bottomPadding(for height: CGFloat) -> CGFloat {
        min(max(height * 0.04, 30), 42)
    }

    func handleLogin() async {
        guard let destination = await viewModel.mockLogin() else {
            return
        }

        switch destination {
        case .profileSetup:
            onProfileRequired()
        case .home:
            onCompleted()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            viewModel: OnboardingViewModel(
                apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0),
                tokenStore: InMemoryTokenStore()
            ),
            onProfileRequired: {},
            onCompleted: {}
        )
    }
}
