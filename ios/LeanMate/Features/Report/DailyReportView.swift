import SwiftUI

struct DailyReportView: View {
    @StateObject private var viewModel: DailyReportViewModel
    @Binding private var selectedTab: AppTab

    let isVisitor: Bool
    let onLoginRequired: () -> Void

    init(
        viewModel: DailyReportViewModel,
        selectedTab: Binding<AppTab>,
        isVisitor: Bool = false,
        onLoginRequired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = selectedTab
        self.isVisitor = isVisitor
        self.onLoginRequired = onLoginRequired
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.regular) {
                    header

                    if isVisitor {
                        visitorContent
                    } else {
                        reportContent
                    }
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
        .task {
            await loadAndMarkViewed()
        }
        .onChange(of: viewModel.reportDate) { _, _ in
            Task {
                await loadAndMarkViewed()
            }
        }
    }
}

private extension DailyReportView {
    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("AI 日报")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("短建议，先记录再生成")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            Spacer()

            Button(action: reloadReport) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
                    .frame(width: 36, height: 36)
                    .background(LMColors.primarySoft)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(LMColors.primaryBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBusy || isVisitor)
            .accessibilityLabel("刷新日报")
        }
        .frame(height: 52)
    }

    var visitorContent: some View {
        LMStateView(
            kind: .empty,
            title: "登录后查看日报",
            message: "日报需要基于你的饮食和体重记录生成。",
            actionTitle: "去登录",
            action: onLoginRequired
        )
    }

    @ViewBuilder
    var reportContent: some View {
        DatePicker("业务日期", selection: $viewModel.reportDate, displayedComponents: .date)
            .font(LMTypography.caption)
            .foregroundStyle(LMColors.textBody)
            .padding(14)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LMColors.inputBorder, lineWidth: 1)
            }

        switch viewModel.state {
        case .idle, .loading:
            LMStateView(
                kind: .loading,
                title: "正在读取日报",
                message: "日报由后端按业务日期返回。"
            )
        case .empty:
            LMStateView(
                kind: .empty,
                title: "今天还没有日报",
                message: "饮食或体重记录不足时，先完成记录再生成日报。",
                actionTitle: "生成日报",
                action: generateReport
            )
        case .generating:
            LMStateView(
                kind: .loading,
                title: "日报生成中",
                message: "生成完成后会显示 3-5 句可执行建议。"
            )
        case .generated, .viewed:
            loadedReportContent
        case .failed(let message):
            LMStateView(
                kind: .error,
                title: "日报生成失败",
                message: message,
                actionTitle: "重试生成",
                action: generateReport
            )
        case .error(let message):
            LMStateView(
                kind: .error,
                title: "日报加载失败",
                message: message,
                actionTitle: "重新加载",
                action: reloadReport
            )
        }
    }

    var loadedReportContent: some View {
        VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        LMTag(title: viewModel.report?.status == .viewed ? "已查看" : "已生成", systemImage: "sparkles")
                        Text("今日评分")
                            .font(LMTypography.cardTitle)
                            .foregroundStyle(LMColors.textBody)
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.scoreText)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(LMColors.primary)
                        Text("分")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                    }
                }

                if let summary = viewModel.report?.summary {
                    Text(summary)
                        .font(LMTypography.body)
                        .foregroundStyle(LMColors.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            reportBlock(
                title: "关键问题",
                systemImage: "exclamationmark.circle",
                text: viewModel.report?.problem ?? "后端暂未返回问题摘要。"
            )

            reportBlock(
                title: "改进建议",
                systemImage: "checkmark.seal",
                text: viewModel.report?.suggestion ?? "后端暂未返回建议内容。"
            )
        }
    }

    func reportBlock(title: String, systemImage: String, text: String) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
                Text(title)
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)
                Spacer()
            }

            Text(text)
                .font(LMTypography.body)
                .foregroundStyle(LMColors.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func loadAndMarkViewed() async {
        guard !isVisitor else {
            return
        }

        await viewModel.load()
        await viewModel.markViewedIfNeeded()
    }

    func reloadReport() {
        Task {
            await loadAndMarkViewed()
        }
    }

    func generateReport() {
        Task {
            await viewModel.generate()
            await viewModel.markViewedIfNeeded()
        }
    }
}

private struct DailyReportPreviewContainer: View {
    @State private var selectedTab = AppTab.report

    var body: some View {
        DailyReportView(
            viewModel: DailyReportViewModel(apiClient: MockAPIClient(delayNanoseconds: 0), reportDate: MockData.today),
            selectedTab: $selectedTab,
            onLoginRequired: {}
        )
    }
}

struct DailyReportView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReportPreviewContainer()
    }
}
