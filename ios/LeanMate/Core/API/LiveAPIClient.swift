import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class LiveAPIClient: APIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: any TokenStore
    private let decoder = APICoding.makeDecoder()
    private let encoder = APICoding.makeEncoder()

    init(baseURL: URL, session: URLSession = .shared, tokenStore: any TokenStore) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
    }

    func oauthLogin(_ request: OAuthLoginRequest) async throws -> AuthToken {
        let token: AuthToken = try await send(
            path: "/v1/auth/oauth-login",
            method: .post,
            body: request,
            requiresAuth: false
        )
        try await tokenStore.saveTokens(AuthTokens(accessToken: token.accessToken, refreshToken: token.refreshToken))
        return token
    }

    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthToken {
        let token: AuthToken = try await send(
            path: "/v1/auth/refresh",
            method: .post,
            body: request,
            requiresAuth: false
        )
        try await tokenStore.saveTokens(AuthTokens(accessToken: token.accessToken, refreshToken: token.refreshToken))
        return token
    }

    func logout(_ request: LogoutRequest?) async throws {
        if let request {
            try await sendEmpty(path: "/v1/auth/logout", method: .post, body: request)
        } else {
            try await sendEmpty(path: "/v1/auth/logout", method: .post)
        }
        try await tokenStore.clearTokens()
    }

    func currentUser() async throws -> CurrentUser {
        try await send(path: "/v1/me")
    }

    func profile() async throws -> ProfilePayload {
        try await send(path: "/v1/profile")
    }

    func saveProfile(_ request: SaveUserProfileRequest) async throws -> ProfilePayload {
        try await send(path: "/v1/profile", method: .put, body: request)
    }

    func todayHome(date: Date?) async throws -> TodayHome {
        try await send(
            path: "/v1/home/today",
            queryItems: date.map { [URLQueryItem(name: "date", value: APICoding.dateString(from: $0))] } ?? []
        )
    }

    func createPhotoRecognition(
        imageData: Data,
        fileName: String,
        mimeType: String,
        mealType: MealType,
        mealDate: Date?,
        note: String?
    ) async throws -> RecognitionTask {
        let fields = [
            "mealType": mealType.rawValue,
            "mealDate": mealDate.map(APICoding.dateString(from:)),
            "note": note
        ].compactMapValues { $0 }

        return try await sendMultipart(
            path: "/v1/diet/recognitions/photo",
            fields: fields,
            fileFieldName: "image",
            fileName: fileName,
            mimeType: mimeType,
            fileData: imageData,
            retryingAfterRefresh: false
        )
    }

    func createTextRecognition(_ request: TextRecognitionRequest) async throws -> RecognitionTask {
        try await send(path: "/v1/diet/recognitions/text", method: .post, body: request)
    }

    func recognitionTask(id: UUID) async throws -> RecognitionTask {
        try await send(path: "/v1/diet/recognitions/\(id.uuidString)")
    }

    func dietEntries(date: Date) async throws -> [FoodEntry] {
        try await send(
            path: "/v1/diet/entries",
            queryItems: [URLQueryItem(name: "date", value: APICoding.dateString(from: date))]
        )
    }

    func saveDietEntry(_ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        try await send(path: "/v1/diet/entries", method: .post, body: request)
    }

    func updateDietEntry(id: UUID, _ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        try await send(path: "/v1/diet/entries/\(id.uuidString)", method: .put, body: request)
    }

    func deleteDietEntry(id: UUID) async throws {
        try await sendEmpty(path: "/v1/diet/entries/\(id.uuidString)", method: .delete)
    }

    func weightEntries(startDate: Date, endDate: Date) async throws -> [WeightEntry] {
        try await send(
            path: "/v1/weights",
            queryItems: [
                URLQueryItem(name: "startDate", value: APICoding.dateString(from: startDate)),
                URLQueryItem(name: "endDate", value: APICoding.dateString(from: endDate))
            ]
        )
    }

    func saveWeight(_ request: SaveWeightEntryRequest) async throws -> WeightEntrySaveResult {
        try await send(path: "/v1/weights", method: .post, body: request)
    }

    func dailyReport(date: Date) async throws -> DailyReport? {
        try await sendOptional(
            path: "/v1/reports/daily",
            queryItems: [URLQueryItem(name: "date", value: APICoding.dateString(from: date))]
        )
    }

    func generateDailyReport(_ request: GenerateDailyReportRequest?) async throws -> DailyReport? {
        if let request {
            try await sendOptional(path: "/v1/reports/daily", method: .post, body: request)
        } else {
            try await sendOptional(path: "/v1/reports/daily", method: .post)
        }
    }

    func markDailyReportViewed(reportId: UUID) async throws -> DailyReport? {
        try await sendOptional(path: "/v1/reports/daily/\(reportId.uuidString)/view", method: .post)
    }

    func streak() async throws -> Streak {
        try await send(path: "/v1/retention/streak")
    }
}

private extension LiveAPIClient {
    func send<Response: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true,
        retryingAfterRefresh: Bool = false
    ) async throws -> Response {
        let data = try await responseData(
            path: path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth,
            retryingAfterRefresh: retryingAfterRefresh
        )
        let envelope = try decoder.decode(APIEnvelope<Response>.self, from: data)
        try validateEnvelope(envelope)

        guard let payload = envelope.data else {
            throw AppError.decoding
        }
        return payload
    }

    func sendOptional<Response: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil
    ) async throws -> Response? {
        let data = try await responseData(path: path, method: method, queryItems: queryItems, body: body)
        let envelope = try decoder.decode(APIEnvelope<Response>.self, from: data)
        try validateEnvelope(envelope)
        return envelope.data
    }

    func sendEmpty(path: String, method: HTTPMethod, body: (any Encodable)? = nil) async throws {
        let data = try await responseData(path: path, method: method, body: body)
        let envelope = try decoder.decode(APIEnvelope<EmptyResponseData>.self, from: data)
        try validateEnvelope(envelope)
    }

    func responseData(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true,
        retryingAfterRefresh: Bool = false
    ) async throws -> Data {
        var request = try await makeRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.networkUnavailable
            }

            if httpResponse.statusCode == 401, requiresAuth, !retryingAfterRefresh {
                if try await refreshAccessToken() {
                    return try await responseData(
                        path: path,
                        method: method,
                        queryItems: queryItems,
                        body: body,
                        requiresAuth: requiresAuth,
                        retryingAfterRefresh: true
                    )
                }
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw mapError(data: data, statusCode: httpResponse.statusCode)
            }

            return data
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.networkUnavailable
        }
    }

    func sendMultipart<Response: Decodable>(
        path: String,
        fields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        retryingAfterRefresh: Bool
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try await makeRequest(path: path, method: .post, requiresAuth: true)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            fields: fields,
            fileFieldName: fileFieldName,
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }

        if httpResponse.statusCode == 401, !retryingAfterRefresh {
            if try await refreshAccessToken() {
                return try await sendMultipart(
                    path: path,
                    fields: fields,
                    fileFieldName: fileFieldName,
                    fileName: fileName,
                    mimeType: mimeType,
                    fileData: fileData,
                    retryingAfterRefresh: true
                )
            }
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw mapError(data: data, statusCode: httpResponse.statusCode)
        }

        let envelope = try decoder.decode(APIEnvelope<Response>.self, from: data)
        try validateEnvelope(envelope)

        guard let payload = envelope.data else {
            throw AppError.decoding
        }
        return payload
    }

    func makeRequest(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool
    ) async throws -> URLRequest {
        guard var components = URLComponents(url: url(for: path), resolvingAgainstBaseURL: false) else {
            throw AppError.networkUnavailable
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw AppError.networkUnavailable
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            let tokens = try await tokenStore.loadTokens()
            if let accessToken = tokens?.accessToken {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
        }

        return request
    }

    func url(for path: String) -> URL {
        path
            .split(separator: "/")
            .reduce(baseURL) { partialURL, component in
                partialURL.appendingPathComponent(String(component))
            }
    }

    func refreshAccessToken() async throws -> Bool {
        guard let tokens = try await tokenStore.loadTokens() else {
            return false
        }

        var request = try await makeRequest(path: "/v1/auth/refresh", method: .post, requiresAuth: false)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(RefreshTokenRequest(refreshToken: tokens.refreshToken))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            try await tokenStore.clearTokens()
            return false
        }

        let envelope = try decoder.decode(APIEnvelope<AuthToken>.self, from: data)
        try validateEnvelope(envelope)
        guard let token = envelope.data else {
            throw AppError.decoding
        }
        try await tokenStore.saveTokens(AuthTokens(accessToken: token.accessToken, refreshToken: token.refreshToken))
        return true
    }

    func validateEnvelope<Payload: Decodable>(_ envelope: APIEnvelope<Payload>) throws {
        guard envelope.code == 0 else {
            throw mapError(code: envelope.code, message: envelope.message)
        }
    }

    func mapError(data: Data, statusCode: Int) -> AppError {
        if let response = try? decoder.decode(APIErrorResponse.self, from: data) {
            return mapError(code: response.code, message: response.message)
        }

        switch statusCode {
        case 400:
            return .validation(message: "请求参数错误")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict
        default:
            return .server(message: "服务端错误")
        }
    }

    func mapError(code: Int, message: String) -> AppError {
        switch code {
        case 40001:
            return .validation(message: message)
        case 40101:
            return .unauthorized
        case 40301:
            return .forbidden
        case 40401:
            return .notFound
        case 40901:
            return .conflict
        case 50010:
            return .aiServiceUnavailable
        case 50001:
            return .server(message: message)
        default:
            return .server(message: message)
        }
    }

    func makeMultipartBody(
        boundary: String,
        fields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var data = Data()

        for (key, value) in fields {
            data.appendString("--\(boundary)\r\n")
            data.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            data.appendString("\(value)\r\n")
        }

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        data.appendString("\r\n--\(boundary)--\r\n")

        return data
    }
}

private extension Data {
    mutating func appendString(_ value: String) {
        append(contentsOf: value.data(using: .utf8) ?? Data())
    }
}
