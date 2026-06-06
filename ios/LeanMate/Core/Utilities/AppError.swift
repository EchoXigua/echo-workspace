import Foundation

enum AppError: Error, Sendable {
    case unauthorized
    case validation(message: String)
    case forbidden
    case notFound
    case conflict
    case networkUnavailable
    case aiServiceUnavailable
    case server(message: String)
    case decoding
    case unknown

    init(_ error: Error) {
        if let appError = error as? AppError {
            self = appError
        } else {
            self = .unknown
        }
    }
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "登录状态已失效"
        case .validation(let message):
            message
        case .forbidden:
            "没有权限执行该操作"
        case .notFound:
            "内容不存在"
        case .conflict:
            "当前状态暂时不能操作"
        case .networkUnavailable:
            "网络不可用，请稍后重试"
        case .aiServiceUnavailable:
            "AI 服务暂时不可用"
        case .server(let message):
            message
        case .decoding:
            "数据解析失败"
        case .unknown:
            "发生未知错误"
        }
    }
}
