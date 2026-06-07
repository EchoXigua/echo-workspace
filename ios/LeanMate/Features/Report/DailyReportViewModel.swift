import Foundation

@MainActor
final class DailyReportViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case generating
        case generated
        case viewed
        case failed(String)
        case error(String)
    }

    @Published var reportDate: Date
    @Published private(set) var state: State = .idle
    @Published private(set) var report: DailyReport?

    private let apiClient: APIClient

    init(apiClient: APIClient, reportDate: Date = Date()) {
        self.apiClient = apiClient
        self.reportDate = reportDate
    }

    var isBusy: Bool {
        state == .loading || state == .generating
    }

    var scoreText: String {
        guard let score = report?.score else {
            return "--"
        }
        return String(score)
    }

    func load() async {
        guard !isBusy else {
            return
        }

        state = .loading

        do {
            apply(report: try await apiClient.dailyReport(date: reportDate))
        } catch {
            state = .error(AppError(error).localizedDescription)
        }
    }

    func generate() async {
        guard !isBusy else {
            return
        }

        state = .generating

        do {
            apply(report: try await apiClient.generateDailyReport(GenerateDailyReportRequest(date: reportDate)))
        } catch {
            state = .failed(AppError(error).localizedDescription)
        }
    }

    func markViewedIfNeeded() async {
        guard !isBusy, let report, report.status == .generated else {
            return
        }

        do {
            apply(report: try await apiClient.markDailyReportViewed(reportId: report.id))
        } catch {
            state = .error(AppError(error).localizedDescription)
        }
    }
}

private extension DailyReportViewModel {
    func apply(report: DailyReport?) {
        self.report = report

        guard let report else {
            state = .empty
            return
        }

        switch report.status {
        case .pending:
            state = .generating
        case .generated:
            state = .generated
        case .viewed:
            state = .viewed
        case .failed:
            state = .failed(report.problem ?? "日报生成失败，可以稍后重试。")
        }
    }
}
