import Foundation

protocol AuthClient: Sendable {
    func exchangeAppleToken(identityToken: String, deviceName: String) async throws -> AppSession
}

protocol DrinkCatalogClient: Sendable {
    func search(query: String) async throws -> [DrinkDefinitionSummary]
}

protocol DrinkLogClient: Sendable {
    func listLogs(day: Date?) async throws -> [DrinkLogEntry]
    func createLog(_ input: CreateDrinkLogInput) async throws -> DrinkLogEntry
}

protocol InsightsClient: Sendable {
    func loadAggregate(for day: Date) async throws -> DailyAggregateSnapshot
    func loadRecommendations(for day: Date) async throws -> [RecommendationCard]
    func loadCaffeineForecast() async throws -> CaffeineForecastSummary
    func loadAIBrief() async throws -> DailyAIBriefSummary
}

protocol GoalsClient: Sendable {
    func loadGoals() async throws -> HealthGoalsSummary
}

protocol ProfileClient: Sendable {
    func loadProfile() async throws -> UserProfileSummary
}

protocol ExportClient: Sendable {
    func requestExport(format: String, startDate: Date, endDate: Date) async throws -> URL
}

enum APIClientError: LocalizedError, Sendable {
    case remoteDisabled
    case malformedBaseURL
    case missingSession
    case invalidResponse
    case decoding(message: String)
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .remoteDisabled:
            return "当前没有配置后端地址。"
        case .malformedBaseURL:
            return "后端地址格式无效，请检查 Info.plist 里的 API 配置。"
        case .missingSession:
            return "当前还没有可用登录会话，请先完成登录。"
        case .invalidResponse:
            return "服务端返回了无法识别的数据。"
        case let .decoding(message):
            return "服务端数据解码失败：\(message)"
        case let .server(statusCode, message):
            return "服务端错误（\(statusCode)）：\(message)"
        }
    }
}

struct APIContainer: Sendable {
    var config: AppConfig
    var sessionStore: SessionStore
    var auth: any AuthClient
    var catalog: any DrinkCatalogClient
    var logs: any DrinkLogClient
    var insights: any InsightsClient
    var goals: any GoalsClient
    var profile: any ProfileClient
    var exports: any ExportClient

    static let preview: APIContainer = {
        let config = AppConfig.preview
        let sessionStore = SessionStore()
        return APIContainer(
            config: config,
            sessionStore: sessionStore,
            auth: PreviewAuthClient(),
            catalog: PreviewDrinkCatalogClient(),
            logs: PreviewDrinkLogClient(),
            insights: PreviewInsightsClient(),
            goals: PreviewGoalsClient(),
            profile: PreviewProfileClient(),
            exports: PreviewExportClient()
        )
    }()

    @MainActor
    static func make(config: AppConfig? = nil) -> APIContainer {
        let config = config ?? .current
        guard config.apiBaseURL != nil else {
            return .preview
        }

        let sessionStore = SessionStore()
        let transport = HTTPTransport(config: config, sessionStore: sessionStore)
        return APIContainer(
            config: config,
            sessionStore: sessionStore,
            auth: LiveAuthClient(transport: transport),
            catalog: LiveDrinkCatalogClient(transport: transport),
            logs: LiveDrinkLogClient(transport: transport),
            insights: LiveInsightsClient(transport: transport),
            goals: LiveGoalsClient(transport: transport),
            profile: LiveProfileClient(transport: transport),
            exports: LiveExportClient(transport: transport)
        )
    }
}

private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

private struct HTTPTransport: Sendable {
    let config: AppConfig
    let sessionStore: SessionStore

    func send<Response: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> Response {
        let request = try await makeRequest(path: path, method: method, query: query, requiresAuth: requiresAuth)
        return try await execute(request)
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body,
        query: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> Response {
        let encoder = APICodingFactory.makeEncoder()
        let bodyData = try encoder.encode(body)
        let request = try await makeRequest(
            path: path,
            method: method,
            query: query,
            body: bodyData,
            requiresAuth: requiresAuth
        )
        return try await execute(request)
    }

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        query: [URLQueryItem],
        body: Data? = nil,
        requiresAuth: Bool
    ) async throws -> URLRequest {
        guard let baseURL = config.apiBaseURL else {
            throw APIClientError.remoteDisabled
        }

        let rootURL = baseURL.appendingPathComponent("v1", isDirectory: true)
        let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var components = URLComponents(
            url: rootURL.appendingPathComponent(sanitizedPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIClientError.malformedBaseURL
        }
        components.queryItems = query.isEmpty ? nil : query

        guard let url = components.url else {
            throw APIClientError.malformedBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if requiresAuth {
            guard let session = await sessionStore.loadSession() else {
                throw APIClientError.missingSession
            }

            request.setValue(session.userID, forHTTPHeaderField: "x-user-id")
            request.setValue("\(session.tokenType.capitalized) \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw APIClientError.server(
                statusCode: httpResponse.statusCode,
                message: serverMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        let decoder = APICodingFactory.makeDecoder()

        do {
            return try decoder.decode(Response.self, from: data)
        } catch let error as DecodingError {
            throw APIClientError.decoding(message: describe(error))
        }
    }

    private func serverMessage(from data: Data) -> String? {
        let decoder = JSONDecoder()

        if let payload = try? decoder.decode(ServerErrorPayload.self, from: data) {
            return payload.detail
        }

        return String(data: data, encoding: .utf8)
    }
}

private func describe(_ error: DecodingError) -> String {
    switch error {
    case let .keyNotFound(key, context):
        return "缺少字段 \(codingPathDescription(context.codingPath + [key]))"
    case let .typeMismatch(_, context):
        return "类型不匹配 \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
    case let .valueNotFound(_, context):
        return "字段为空 \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
    case let .dataCorrupted(context):
        return "数据损坏 \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
    @unknown default:
        return "未知解码错误"
    }
}

private func codingPathDescription(_ path: [CodingKey]) -> String {
    guard path.isEmpty == false else {
        return "<root>"
    }

    return path.map(\.stringValue).joined(separator: ".")
}

private struct LiveAuthClient: AuthClient {
    let transport: HTTPTransport

    func exchangeAppleToken(identityToken: String, deviceName: String) async throws -> AppSession {
        let payload = AppleAuthPayload(identityToken: identityToken, deviceName: deviceName)
        let response: SessionResponseDTO = try await transport.send(
            path: "auth/apple",
            method: .post,
            body: payload,
            requiresAuth: false
        )
        return response.asAppSession
    }
}

private struct LiveDrinkCatalogClient: DrinkCatalogClient {
    let transport: HTTPTransport

    func search(query: String) async throws -> [DrinkDefinitionSummary] {
        let response: [DrinkDefinitionSummary] = try await transport.send(
            path: "drink-definitions",
            query: [URLQueryItem(name: "q", value: query)],
            requiresAuth: false
        )
        return response
    }
}

private struct LiveDrinkLogClient: DrinkLogClient {
    let transport: HTTPTransport

    func listLogs(day: Date?) async throws -> [DrinkLogEntry] {
        let query = day.map { [URLQueryItem(name: "day", value: formatDay($0))] } ?? []
        let response: [DrinkLogEntry] = try await transport.send(path: "drink-logs", query: query)
        return response
    }

    func createLog(_ input: CreateDrinkLogInput) async throws -> DrinkLogEntry {
        let response: DrinkLogEntry = try await transport.send(
            path: "drink-logs",
            method: .post,
            body: input
        )
        return response
    }
}

private struct LiveInsightsClient: InsightsClient {
    let transport: HTTPTransport

    func loadAggregate(for day: Date) async throws -> DailyAggregateSnapshot {
        let response: DailyAggregateSnapshot = try await transport.send(
            path: "daily-insights",
            query: [URLQueryItem(name: "date", value: formatDay(day))]
        )
        return response
    }

    func loadRecommendations(for day: Date) async throws -> [RecommendationCard] {
        let response: [RecommendationDecisionDTO] = try await transport.send(
            path: "recommendations",
            query: [URLQueryItem(name: "date", value: formatDay(day))]
        )
        return response.map(\.asCard)
    }

    func loadCaffeineForecast() async throws -> CaffeineForecastSummary {
        let response: CaffeineForecastSummary = try await transport.send(path: "daily-insights/caffeine-forecast")
        return response
    }

    func loadAIBrief() async throws -> DailyAIBriefSummary {
        let response: DailyAIBriefSummary = try await transport.send(path: "daily-insights/ai-brief")
        return response
    }
}

private struct LiveGoalsClient: GoalsClient {
    let transport: HTTPTransport

    func loadGoals() async throws -> HealthGoalsSummary {
        let response: HealthGoalsSummary = try await transport.send(path: "goals")
        return response
    }
}

private struct LiveProfileClient: ProfileClient {
    let transport: HTTPTransport

    func loadProfile() async throws -> UserProfileSummary {
        let response: UserProfileDTO = try await transport.send(path: "profile")
        return response.asSummary
    }
}

private struct LiveExportClient: ExportClient {
    let transport: HTTPTransport

    func requestExport(format: String, startDate: Date, endDate: Date) async throws -> URL {
        let payload = ExportRequestPayload(format: format, startDate: formatDay(startDate), endDate: formatDay(endDate))
        let response: ExportTaskDTO = try await transport.send(
            path: "exports",
            method: .post,
            body: payload,
            requiresAuth: false
        )

        guard let downloadURL = response.downloadURL, let url = URL(string: downloadURL) else {
            throw APIClientError.invalidResponse
        }

        return url
    }
}

struct PreviewAuthClient: AuthClient {
    func exchangeAppleToken(identityToken: String, deviceName: String) async throws -> AppSession {
        AppSession(
            accessToken: "preview-session-\(identityToken.suffix(6))",
            tokenType: "bearer",
            expiresIn: 3600,
            userID: "preview-user",
            displayName: PreviewFixtures.profile.displayName,
            sync: SyncEnvelopeSummary(lastSyncedAt: .now, pendingEntryIDs: [], conflictCount: 0),
            issuedAt: .now
        )
    }
}

struct PreviewDrinkCatalogClient: DrinkCatalogClient {
    func search(query: String) async throws -> [DrinkDefinitionSummary] {
        PreviewFixtures.previewSearchResults(for: query)
    }
}

struct PreviewDrinkLogClient: DrinkLogClient {
    func listLogs(day: Date?) async throws -> [DrinkLogEntry] {
        PreviewFixtures.entries
    }

    func createLog(_ input: CreateDrinkLogInput) async throws -> DrinkLogEntry {
        let definition = PreviewFixtures.drinks.first { $0.id == input.drinkDefinitionID } ?? PreviewFixtures.drinks[0]
        let serving = definition.servingOptions.first { $0.id == input.servingOptionID } ?? definition.preferredServing
        let scaledMetrics = definition.metrics.scaled(by: input.ratio * serving.multiplier)
        return DrinkLogEntry(
            id: UUID().uuidString,
            userID: "preview-user",
            drinkDefinitionID: definition.id,
            drinkName: definition.name,
            category: definition.category,
            brand: definition.brand,
            preparationMethod: definition.preparationMethods?.first,
            consumedAt: input.consumedAt,
            servingLabel: serving.name,
            metrics: scaledMetrics,
            note: input.note,
            source: input.source,
            syncStatus: .synced
        )
    }
}

struct PreviewInsightsClient: InsightsClient {
    func loadAggregate(for day: Date) async throws -> DailyAggregateSnapshot {
        DailyAggregateSnapshot(
            date: day,
            totals: PreviewFixtures.dashboard.aggregate,
            entriesCount: PreviewFixtures.dashboard.todayEntries.count,
            categoryBreakdown: PreviewFixtures.dashboard.categoryBreakdown
        )
    }

    func loadRecommendations(for day: Date) async throws -> [RecommendationCard] {
        PreviewFixtures.dashboard.recommendations
    }

    func loadCaffeineForecast() async throws -> CaffeineForecastSummary {
        PreviewFixtures.caffeineForecast
    }

    func loadAIBrief() async throws -> DailyAIBriefSummary {
        PreviewFixtures.aiBrief
    }
}

struct PreviewGoalsClient: GoalsClient {
    func loadGoals() async throws -> HealthGoalsSummary {
        PreviewFixtures.goals
    }
}

struct PreviewProfileClient: ProfileClient {
    func loadProfile() async throws -> UserProfileSummary {
        PreviewFixtures.profile
    }
}

struct PreviewExportClient: ExportClient {
    func requestExport(format: String, startDate: Date, endDate: Date) async throws -> URL {
        URL(string: "https://example.invalid/export/\(format)")!
    }
}

private struct AppleAuthPayload: Encodable {
    let identityToken: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case deviceName = "device_name"
    }
}

private struct ExportRequestPayload: Encodable {
    let format: String
    let startDate: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case format
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

private struct ExportTaskDTO: Decodable {
    let id: String
    let status: String
    let format: String
    let downloadURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case format
        case downloadURL = "download_url"
    }
}

private struct SessionResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let userID: String
    let displayName: String
    let sync: SyncEnvelopeSummary

    var asAppSession: AppSession {
        AppSession(
            accessToken: accessToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            userID: userID,
            displayName: displayName,
            sync: sync,
            issuedAt: .now
        )
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case userID = "user_id"
        case displayName = "display_name"
        case sync
    }
}

private struct UserProfileDTO: Decodable {
    let userID: String
    let displayName: String
    let age: Int
    let sleepTime: String
    let caffeineSensitive: Bool
    let bloodSugarWatch: Bool

    var asSummary: UserProfileSummary {
        UserProfileSummary(
            userID: userID,
            displayName: displayName,
            age: age,
            sleepHourText: String(sleepTime.prefix(5)),
            caffeineSensitive: caffeineSensitive,
            bloodSugarWatch: bloodSugarWatch
        )
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case age
        case sleepTime = "sleep_time"
        case caffeineSensitive = "caffeine_sensitive"
        case bloodSugarWatch = "blood_sugar_watch"
    }
}

private struct RecommendationDecisionDTO: Decodable {
    let severity: String
    let title: String
    let summary: String
    let explanation: RecommendationExplanationDTO

    var asCard: RecommendationCard {
        RecommendationCard(
            ruleID: explanation.ruleID,
            severity: severity,
            title: title,
            summary: summary,
            explanation: explanation.asExplanation
        )
    }
}

private struct RecommendationExplanationDTO: Decodable {
    let ruleID: String
    let trigger: String
    let inputs: [String: RecommendationInputValue]
    let thresholdComparison: String
    let action: String
    let risk: String

    var asExplanation: RecommendationExplanation {
        RecommendationExplanation(
            ruleID: ruleID,
            trigger: trigger,
            inputs: inputs.mapValues(\.stringValue),
            thresholdComparison: thresholdComparison,
            action: action,
            risk: risk
        )
    }

    enum CodingKeys: String, CodingKey {
        case ruleID = "rule_id"
        case trigger
        case inputs
        case thresholdComparison = "threshold_comparison"
        case action
        case risk
    }
}

private enum RecommendationInputValue: Decodable {
    case number(Double)
    case text(String)

    var stringValue: String {
        switch self {
        case let .number(value):
            return value.formatted(.number.precision(.fractionLength(0 ... 2)))
        case let .text(value):
            return value
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self = .number(value)
            return
        }

        self = .text(try container.decode(String.self))
    }
}

private struct ServerErrorPayload: Decodable {
    let detail: String
}

enum APICodingFactory {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(makeISO8601Formatter().string(from: date))
        }
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = makeISO8601Formatter().date(from: value)
                ?? makeISO8601FractionalFormatter().date(from: value)
                ?? makeNaiveDateTimeFormatter().date(from: value)
                ?? makeNaiveFractionalDateTimeFormatter().date(from: value)
                ?? makePlainDateFormatter().date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date value: \(value)")
        }
        return decoder
    }
}

private func formatDay(_ date: Date) -> String {
    makePlainDateFormatter().string(from: date)
}

private func makeISO8601Formatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = .current
    return formatter
}

private func makeISO8601FractionalFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = .current
    return formatter
}

private func makeNaiveDateTimeFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter
}

private func makeNaiveFractionalDateTimeFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    return formatter
}

private func makePlainDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}
