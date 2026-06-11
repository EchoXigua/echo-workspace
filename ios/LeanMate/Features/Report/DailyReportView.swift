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
        LMTabScreen(
            items: AppTab.allCases.map {
                LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
            },
            selection: $selectedTab
        ) {
            header

            if isVisitor {
                visitorContent
            } else {
                reportContent
            }
        }
        .task {
            await loadAndMarkViewed()
        }
    }
}

private extension DailyReportView {
    var header: some View {
        HStack {
            Text("AI 日报")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            LMTag(title: isLoadingReport ? "生成中" : "今天")
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

    var isLoadingReport: Bool {
        switch viewModel.state {
        case .idle, .loading, .generating:
            return true
        case .empty, .generated, .viewed, .failed, .error:
            return false
        }
    }

    @ViewBuilder
    var reportContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingReportContent
        case .empty:
            emptyReportContent
        case .generating:
            loadingReportContent
        case .generated, .viewed:
            loadedReportContent
        case .failed(let message):
            reportFailureContent(message: message)
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

    @ViewBuilder
    func reportFailureContent(message: String) -> some View {
        if isMissingReportInputMessage(message) {
            missingInputReportFailureContent(message: message)
        } else {
            genericReportFailureContent(message: message)
        }
    }

    func missingInputReportFailureContent(message: String) -> some View {
        VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                LMTag(title: "需要记录", systemImage: "doc.text", style: .neutral)

                HStack(alignment: .top, spacing: 12) {
                    reportIconBox(systemImage: "fork.knife")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("先补一条记录")
                            .font(LMTypography.cardTitle)
                            .foregroundStyle(LMColors.textBody)

                        Text("AI 日报需要基于今天的饮食或体重记录生成。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("原因：\(message)")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LMColors.warmMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 10) {
                    LMButton(title: "去记录", systemImage: "plus", height: 44) {
                        selectedTab = .record
                    }

                    LMButton(title: "重试", role: .secondary, height: 44, action: generateReport)
                }
            }

            LMCard(cornerRadius: 16, padding: 14) {
                Text("生成前需要")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)

                referenceRow(
                    title: "饮食记录",
                    systemImage: "fork.knife",
                    text: "记录并保存今天任意一餐。"
                )
                referenceRow(
                    title: "体重记录",
                    systemImage: LMWeightScaleIcon.symbolName,
                    text: "或者先记录一次今天的体重。"
                )
            }
        }
    }

    func genericReportFailureContent(message: String) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            LMTag(title: "需要重试", systemImage: "exclamationmark.triangle", style: .danger)

            HStack(alignment: .top, spacing: 12) {
                reportIconBox(systemImage: "exclamationmark.triangle", tone: .warning)

                VStack(alignment: .leading, spacing: 5) {
                    Text("日报生成失败")
                        .font(LMTypography.cardTitle)
                        .foregroundStyle(LMColors.textBody)

                    Text(message)
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LMButton(title: "重试生成", height: 44, action: generateReport)
        }
    }

    var loadedReportContent: some View {
        let scoreTone = reportScoreTone

        return VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                LMTag(title: scoreTone.tagTitle, style: scoreTone.tagStyle)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.scoreText)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(scoreTone.scoreColor)
                    Text("分")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }

                if let summary = viewModel.report?.summary {
                    Text(summary)
                        .font(LMTypography.body)
                        .foregroundStyle(LMColors.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            keyFindingsCard
        }
    }

    var emptyReportContent: some View {
        VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                LMTag(title: "未生成", style: .neutral)

                HStack(alignment: .top, spacing: 12) {
                    reportIconBox(systemImage: "sparkles")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("今天还没有日报")
                            .font(LMTypography.cardTitle)
                            .foregroundStyle(LMColors.textBody)

                        Text("完成今天的饮食记录后，可以生成一份简短、可执行的建议。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LMButton(title: "生成 AI 日报", height: 44, action: generateReport)
            }

            LMCard(cornerRadius: 16, padding: 14) {
                Text("生成会参考")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)

                referenceRow(
                    title: "热量完成度",
                    systemImage: "flame",
                    text: "今天摄入和目标之间的差距。"
                )
                referenceRow(
                    title: "营养结构",
                    systemImage: "chart.pie",
                    text: "蛋白、脂肪、碳水是否均衡。"
                )
                referenceRow(
                    title: "体重记录",
                    systemImage: LMWeightScaleIcon.symbolName,
                    text: "近期体重变化作为辅助判断。"
                )
            }
        }
    }

    var loadingReportContent: some View {
        VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .top, spacing: 12) {
                    reportIconBox(systemImage: "sparkles")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("正在生成今天的饮食分析")
                            .font(LMTypography.cardTitle)
                            .foregroundStyle(LMColors.textBody)

                        Text("会基于热量、蛋白、脂肪、碳水和体重记录生成短建议。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                progressBar(progress: viewModel.state == .generating ? 0.64 : 0.32)
            }

            LMCard(cornerRadius: 16, padding: 14) {
                Text("生成进度")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)

                progressRow(title: "热量与目标", status: "已完成", style: .done)
                progressRow(title: "营养结构", status: "分析中", style: .active)
                progressRow(title: "明日建议", status: "等待中", style: .waiting)
            }

            Text("生成完成后会自动刷新为今日评分、结论和今日要点。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LMColors.card.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LMColors.border, lineWidth: 1)
                }
        }
    }

    var keyFindingsCard: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text("今日要点")
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            findingRow(
                title: "关键问题",
                systemImage: "exclamationmark.triangle",
                tone: .warning,
                text: viewModel.report?.problem ?? "后端暂未返回问题摘要。"
            )

            findingRow(
                title: "改进建议",
                systemImage: "lightbulb",
                tone: .success,
                text: viewModel.report?.suggestion ?? "后端暂未返回建议内容。"
            )
        }
    }

    func referenceRow(title: String, systemImage: String, text: String) -> some View {
        findingRow(title: title, systemImage: systemImage, tone: .success, text: text)
    }

    func isMissingReportInputMessage(_ message: String) -> Bool {
        message.contains("没有可用于生成日报的记录")
    }

    var reportScoreTone: ReportScoreTone {
        ReportScoreTone(score: viewModel.report?.score)
    }

    func findingRow(title: String, systemImage: String, tone: ReportIconTone, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            reportIconBox(systemImage: systemImage, tone: tone)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)

                Text(text)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func reportIconBox(systemImage: String, tone: ReportIconTone = .success) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tone.backgroundColor)
                .frame(width: 34, height: 34)

            if systemImage == LMWeightScaleIcon.symbolName {
                LMWeightScaleIcon(size: 14, color: tone.foregroundColor)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tone.foregroundColor)
            }
        }
    }

    func progressRow(title: String, status: String, style: ProgressPillStyle) -> some View {
        HStack {
            Text(title)
                .font(LMTypography.bodyStrong)
                .foregroundStyle(LMColors.textBody)

            Spacer()

            Text(status)
                .font(LMTypography.badge)
                .foregroundStyle(style.foregroundColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(style.backgroundColor)
                .clipShape(Capsule())
        }
        .frame(height: 36)
    }

    func progressBar(progress: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LMColors.primarySoft)

                Capsule()
                    .fill(LMColors.primary)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
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

private enum ReportScoreTone {
    case ready
    case warning
    case low
    case unknown

    init(score: Int?) {
        guard let score else {
            self = .unknown
            return
        }

        switch score {
        case ..<40:
            self = .low
        case 40..<60:
            self = .warning
        default:
            self = .ready
        }
    }

    var tagTitle: String {
        switch self {
        case .ready:
            return "已生成"
        case .warning:
            return "记录不足"
        case .low:
            return "分数偏低"
        case .unknown:
            return "已生成"
        }
    }

    var tagStyle: LMTagStyle {
        switch self {
        case .ready:
            return .primary
        case .warning:
            return .warning
        case .low:
            return .danger
        case .unknown:
            return .neutral
        }
    }

    var scoreColor: Color {
        switch self {
        case .ready:
            return LMColors.primary
        case .warning:
            return Color(hex: 0xD48A19)
        case .low:
            return LMColors.danger
        case .unknown:
            return LMColors.textSecondary
        }
    }
}

private enum ReportIconTone {
    case success
    case warning

    var foregroundColor: Color {
        switch self {
        case .success:
            LMColors.primary
        case .warning:
            Color(hex: 0xD48A19)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success:
            LMColors.primarySoft
        case .warning:
            Color(hex: 0xFFF7E8)
        }
    }
}

private enum ProgressPillStyle {
    case done
    case active
    case waiting

    var foregroundColor: Color {
        switch self {
        case .done:
            LMColors.primaryDeep
        case .active:
            Color(hex: 0xD48A19)
        case .waiting:
            LMColors.textSecondary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .done:
            LMColors.primarySoft
        case .active:
            Color(hex: 0xFFF7E8)
        case .waiting:
            LMColors.warmMuted
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
