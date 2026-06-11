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

                todayPreviewCard

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    if let failureMessage {
                        loginFailureBanner(message: failureMessage)
                    } else {
                        syncBenefitRow
                    }

                    appleSignInButton
                    visitorButton
                    agreementRow

                    if let agreementMessage = viewModel.agreementMessage {
                        Text(agreementMessage)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(LMColors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(12)
                .background(LMColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LMColors.border, lineWidth: 1)
                }
                .shadow(color: Color(hex: 0x143B23, alpha: 0.06), radius: 20, x: 0, y: 5)
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
        VStack(alignment: .center, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LMColors.primary)
                    .frame(width: 86, height: 86)

                Text("卡")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .center, spacing: 8) {
                Text("LeanMate")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("少点焦虑，多点好好吃饭")
                    .font(.system(size: 13))
                    .foregroundStyle(LMColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    var todayPreviewCard: some View {
        LMCard(cornerRadius: 18, padding: 16) {
            LMTag(title: "今天还能吃 863 千卡")

            Text("把记录变成生活节奏，而不是表格任务。")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: LMSpacing.small) {
                previewMetric(label: "已摄入", value: "637", unit: "kcal")
                previewMetric(label: "蛋白", value: "18", unit: "g")
                previewMetric(label: "碳水", value: "58", unit: "g")
            }
        }
    }

    var syncBenefitRow: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LMColors.primarySoft)
                    .frame(width: 34, height: 34)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("登录后自动保留记录")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("饮食、体重和日报会同步到账号")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(height: 42)
    }

    var appleSignInButton: some View {
        Button {
            Task {
                await handleAppleSignIn()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoggingIn {
                    ProgressView()
                        .tint(LMColors.textBody)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(appleButtonTitle)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(LMColors.textBody)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LMColors.textBody, lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoggingIn)
        .accessibilityLabel(appleButtonTitle)
    }

    var visitorButton: some View {
        Button {
            Task {
                await handleVisitorPreview()
            }
        } label: {
            Text("随便看看")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LMColors.primaryDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoggingIn)
        .accessibilityLabel("随便看看")
    }

    var agreementRow: some View {
        HStack(alignment: .center, spacing: 8) {
            agreementCheckboxButton

            HStack(spacing: 0) {
                Text("我已阅读并同意")
                    .foregroundStyle(LMColors.textSecondary)

                NavigationLink {
                    OnboardingLegalDocumentView(document: .userAgreement)
                } label: {
                    Text("《用户协议》")
                        .foregroundStyle(LMColors.primaryDeep)
                }

                Text("和")
                    .foregroundStyle(LMColors.textSecondary)

                NavigationLink {
                    OnboardingLegalDocumentView(document: .privacyPolicy)
                } label: {
                    Text("《隐私政策》")
                        .foregroundStyle(LMColors.primaryDeep)
                }
            }
            .font(.system(size: 10.5, weight: .semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.9)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 34)
    }

    var agreementCheckboxButton: some View {
        Button {
            viewModel.toggleAgreement()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(viewModel.hasAcceptedAgreement ? LMColors.primary : LMColors.card)
                    .frame(width: 18, height: 18)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                viewModel.hasAcceptedAgreement ? LMColors.primary : LMColors.primaryBorder,
                                lineWidth: 1.2
                            )
                    }

                if viewModel.hasAcceptedAgreement {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 28, height: 34, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("同意用户协议和隐私政策")
        .accessibilityValue(viewModel.hasAcceptedAgreement ? "已同意" : "未同意")
    }

    func loginFailureBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LMColors.danger)

            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: 0x9A3A2E))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(minHeight: 56)
        .background(LMColors.dangerSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0xF0B5A8), lineWidth: 1)
        }
    }

    func previewMetric(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: 0x7A746A))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x202820))

                Text(unit)
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.textSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var failureMessage: String? {
        if case .loginFailed(let message) = viewModel.state {
            return message
        }

        return nil
    }

    var appleButtonTitle: String {
        failureMessage == nil ? "通过 Apple 继续" : "重新通过 Apple 继续"
    }

    func topPadding(for height: CGFloat) -> CGFloat {
        min(max(height * 0.08, 54), 78)
    }

    func bottomPadding(for height: CGFloat) -> CGFloat {
        min(max(height * 0.036, 28), 34)
    }

    func handleAppleSignIn() async {
        guard let destination = await viewModel.signInWithApple() else {
            return
        }

        route(to: destination)
    }

    func handleVisitorPreview() async {
        guard let destination = await viewModel.startGuestSession() else {
            return
        }

        route(to: destination)
    }

    func route(to destination: OnboardingDestination) {
        switch destination {
        case .profileSetup:
            onProfileRequired()
        case .home:
            onCompleted()
        case .visitorHome:
            onVisitorPreview()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            viewModel: OnboardingViewModel(
                apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0),
                tokenStore: InMemoryTokenStore(),
                localStore: InMemoryLocalStore(),
                appleSignInAuthorizer: MockAppleSignInAuthorizer()
            ),
            onProfileRequired: {},
            onCompleted: {}
        )
    }
}
