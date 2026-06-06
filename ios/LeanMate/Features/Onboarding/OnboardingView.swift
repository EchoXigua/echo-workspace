import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    let onProfileRequired: () -> Void
    let onCompleted: () -> Void

    init(
        viewModel: OnboardingViewModel,
        onProfileRequired: @escaping () -> Void,
        onCompleted: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onProfileRequired = onProfileRequired
        self.onCompleted = onCompleted
    }

    var body: some View {
        VStack(spacing: 0) {
            brandStack

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

            LMButton(
                title: "开始记录",
                systemImage: "arrow.right",
                isLoading: viewModel.isLoggingIn
            ) {
                Task {
                    await handleLogin()
                }
            }
        }
        .padding(.top, 78)
        .padding(.horizontal, 28)
        .padding(.bottom, 42)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    func handleLogin() async {
        guard let destination = await viewModel.mockLogin() else {
            return
        }

        switch destination {
        case .profileSetup:
            onProfileRequired()
        case .homePlaceholder:
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
