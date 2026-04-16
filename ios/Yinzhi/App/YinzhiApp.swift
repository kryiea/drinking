import Observation
import SwiftUI

private enum AppPersistenceKeys {
    static let onboardingCompleted = "com.luca.yinzhi.onboarding.completed"
    static let userPreferences = "com.luca.yinzhi.preferences"
    static let userDrinkTemplates = "com.luca.yinzhi.user-drink-templates"
    static let localSnapshotUpdatedAt = "com.luca.yinzhi.local-snapshot-updated-at"
}

struct RecordCelebration: Identifiable, Equatable, Sendable {
    enum Style: Equatable, Sendable {
        case pending
        case success
    }

    let id: String
    let style: Style
    let title: String
    let subtitle: String
    let metricsLine: String
    let sleepLine: String
    let syncLine: String
}

@MainActor
@Observable
final class AppEnvironment {
    var selectedTab: AppTab = .home
    var hasCompletedOnboarding: Bool
    var session: AppSession?
    var dashboard = PreviewFixtures.dashboard
    var profile = PreviewFixtures.profile
    var catalog = PreviewFixtures.drinks
    var preferences = PreviewFixtures.userPreferences
    var userDrinkTemplates = PreviewFixtures.userDrinkTemplates
    var isBootstrapping = false
    var isAuthenticating = false
    var isSearchingCatalog = false
    var isRecordingDrink = false
    var isSyncing = false
    var isRefreshingAIBrief = false
    var isSyncingCloudSnapshot = false
    var statusMessage: String?
    var errorMessage: String?
    var recentRecordFeedback: RecordCelebration?

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let config: AppConfig
    @ObservationIgnored private let api: APIContainer
    @ObservationIgnored private let cache: OfflineCacheStore
    @ObservationIgnored private let syncProvider: any SyncProvider
    @ObservationIgnored private var recentRecordDismissTask: Task<Void, Never>?
    @ObservationIgnored private var syncObserver: NSObjectProtocol?

    init(
        config: AppConfig? = nil,
        api: APIContainer? = nil,
        cache: OfflineCacheStore = OfflineCacheStore(),
        syncProvider: (any SyncProvider)? = nil
    ) {
        let resolvedConfig = config ?? .current
        self.config = resolvedConfig
        self.api = api ?? APIContainer.make(config: resolvedConfig)
        self.cache = cache
        self.syncProvider = syncProvider ?? ICloudKeyValueSyncProvider()
        hasCompletedOnboarding = defaults.bool(forKey: AppPersistenceKeys.onboardingCompleted)
        preferences = loadPreferences()
        userDrinkTemplates = loadUserDrinkTemplates()
        registerSyncObserver()
    }

    var canUseRemoteAPI: Bool {
        config.hasRemoteAPI
    }

    var canUseAppleSignIn: Bool {
        config.hasRemoteAPI
    }

    var pendingSyncCount: Int {
        session?.sync.pendingCount ?? cache.pendingEntryIDs().count
    }

    var isSignedIntoRemoteSource: Bool {
        session != nil
    }

    var connectionTitle: String {
        if isSignedIntoRemoteSource {
            return "已连接本地后端"
        }
        if config.hasRemoteAPI {
            return "离线可记 / 待重连"
        }
        return "预览模式"
    }

    var connectionShortLabel: String {
        if isSignedIntoRemoteSource {
            return "已连接"
        }
        if config.hasRemoteAPI {
            return errorMessage?.contains("过期") == true ? "待重连" : "离线可记"
        }
        return "预览模式"
    }

    var connectionSystemImage: String {
        if isSignedIntoRemoteSource {
            return "server.rack"
        }
        if config.hasRemoteAPI {
            return errorMessage?.contains("过期") == true ? "key.slash" : "person.badge.key"
        }
        return "sparkles.rectangle.stack"
    }

    var connectionTint: Color {
        if isSignedIntoRemoteSource {
            return AppTheme.accent
        }
        if config.hasRemoteAPI {
            return errorMessage?.contains("过期") == true
                ? Color(red: 0.90, green: 0.53, blue: 0.18)
                : Color(red: 0.23, green: 0.47, blue: 0.82)
        }
        return Color(red: 0.56, green: 0.52, blue: 0.78)
    }

    var connectionSupportingText: String {
        if isSignedIntoRemoteSource {
            return "当前可以连本地后端，但记录、曲线和设置仍以本地即时可用为主。"
        }
        if config.hasRemoteAPI {
            return errorMessage?.contains("过期") == true
                ? "开发连接已过期，重新连一次就能恢复目录和导出能力。"
                : "现在先按本地优先体验，重连后端后目录和导出会更完整。"
        }
        return "当前未配置后端地址，先使用本地预览模式。"
    }

    var effectiveProfile: UserProfileSummary {
        UserProfileSummary(
            userID: profile.userID,
            displayName: profile.displayName,
            age: profile.age,
            sleepHourText: preferences.sleepHourText,
            caffeineSensitive: preferences.metabolismProfile == .sensitive,
            bloodSugarWatch: profile.bloodSugarWatch
        )
    }

    var allDrinkDefinitions: [DrinkDefinitionSummary] {
        let merged = userDrinkTemplates.map(\.asDrinkDefinition) + catalog
        return merged.sorted { lhs, rhs in
            if lhs.category == rhs.category {
                return lhs.name < rhs.name
            }
            return lhs.category < rhs.category
        }
    }

    var personalDrinkDefinitions: [DrinkDefinitionSummary] {
        userDrinkTemplates.map(\.asDrinkDefinition)
    }

    var mainstreamCoffeeCatalog: [DrinkDefinitionSummary] {
        coffeeCatalog.filter { $0.id.hasPrefix("user-") == false }
    }

    var mainstreamMilkTeaCatalog: [DrinkDefinitionSummary] {
        milkTeaCatalog.filter { $0.id.hasPrefix("user-") == false }
    }

    var recentDrinkDefinitions: [DrinkDefinitionSummary] {
        dashboard.todayEntries.compactMap { entry in
            if let id = entry.drinkDefinitionID, let match = allDrinkDefinitions.first(where: { $0.id == id }) {
                return match
            }
            return allDrinkDefinitions.first { $0.name == entry.drinkName && $0.brand == entry.brand }
        }
    }

    var frequentDrinkDefinitions: [DrinkDefinitionSummary] {
        let grouped = Dictionary(grouping: dashboard.todayEntries, by: \.drinkName)
        let sortedNames = grouped.keys.sorted { lhs, rhs in
            grouped[lhs, default: []].count > grouped[rhs, default: []].count
        }

        let preferred = sortedNames.compactMap { name in
            allDrinkDefinitions.first { $0.name == name }
        }
        let fallback = allDrinkDefinitions.filter { drink in
            drink.category.contains("咖啡") || drink.category.contains("奶茶") || drink.category.contains("果茶")
        }

        return Array((preferred + fallback).uniqued(on: \.id).prefix(4))
    }

    var coffeeCatalog: [DrinkDefinitionSummary] {
        allDrinkDefinitions.filter { $0.category.contains("咖啡") }
    }

    var milkTeaCatalog: [DrinkDefinitionSummary] {
        allDrinkDefinitions.filter { $0.category.contains("奶茶") || $0.category.contains("果茶") }
    }

    var syncStrategyLabel: String {
        if preferences.iCloudPlanEnabled == false {
            return "仅本地"
        }
        if isSyncingCloudSnapshot {
            return "iCloud 同步中"
        }
        return syncProvider.isCloudAvailable ? "iCloud 已启用" : "等待 iCloud"
    }

    var syncStrategyCaption: String {
        if preferences.iCloudPlanEnabled == false {
            return "当前只保留本地记录和设置。"
        }
        if syncProvider.isCloudAvailable {
            return "设置、个人饮品和本地记录会尝试通过 iCloud 保持一致。"
        }
        return "已打开 iCloud 路线，但当前环境还不能真正同步，仍会保留本地记录。"
    }

    var watchSurfaceCaption: String {
        preferences.watchPlanEnabled
            ? "Watch 将聚焦“快速记录 + 当前咖啡因”。"
            : "Watch 计划暂未启用。"
    }

    var sleepScheduleDate: Date {
        preferences.sleepDateToday
    }

    var primaryHomeActionLabel: String {
        if isSignedIntoRemoteSource == false, canUseRemoteAPI {
            return "连接后端"
        }
        return "快速记录"
    }

    var primaryHomeActionSystemImage: String {
        if isSignedIntoRemoteSource == false, canUseRemoteAPI {
            return "person.badge.key"
        }
        return "plus.viewfinder"
    }

    func handlePrimaryHomeAction() {
        if isSignedIntoRemoteSource == false, canUseRemoteAPI {
            selectedTab = .profile
        } else {
            selectedTab = .log
        }
    }

    var backendDisplayText: String {
        config.apiBaseURL?.absoluteString ?? "未配置后端地址"
    }

    func updateSleepSchedule(_ date: Date) {
        preferences = preferences.withSleepDate(date)
        persistPreferences()
        rebuildLocalForecast(reason: "已更新入睡时间。")
    }

    func updateMetabolismProfile(_ profile: CaffeineMetabolismProfile) {
        preferences.metabolismProfile = profile
        persistPreferences()
        rebuildLocalForecast(reason: "已切换咖啡因代谢档位。")
    }

    func updateICloudPlanEnabled(_ enabled: Bool) {
        preferences.iCloudPlanEnabled = enabled
        persistPreferences(syncToCloud: false)
        if enabled {
            Task {
                await reconcileCloudSnapshot(
                    preferRemoteWhenLocalEmpty: true,
                    statusOnPull: "已从 iCloud 对齐本地记录。",
                    statusOnPush: "已把当前记录推到 iCloud。"
                )
            }
        } else {
            statusMessage = "当前先按纯本地记录体验。"
        }
    }

    func updateWatchPlanEnabled(_ enabled: Bool) {
        preferences.watchPlanEnabled = enabled
        persistPreferences()
        statusMessage = enabled ? "已保留 Apple Watch 快速记录路线。" : "已关闭 Watch 规划提示。"
    }

    func addUserDrinkTemplate(
        brand: String,
        name: String,
        category: String,
        caffeineMG: Double,
        sugarG: Double,
        volumeML: Int,
        preparationMethod: BrewMethod?
    ) {
        let template = UserDrinkTemplate(
            id: "user-\(UUID().uuidString)",
            brand: brand,
            name: name,
            category: category,
            caffeineMG: caffeineMG,
            sugarG: sugarG,
            volumeML: volumeML,
            preparationMethod: preparationMethod
        )
        userDrinkTemplates.insert(template, at: 0)
        persistUserDrinkTemplates()
        statusMessage = "已添加 \(name)，现在会出现在“我添加的饮品”。"
    }

    func updateUserDrinkTemplate(
        id: String,
        brand: String,
        name: String,
        category: String,
        caffeineMG: Double,
        sugarG: Double,
        volumeML: Int,
        preparationMethod: BrewMethod?
    ) {
        guard let index = userDrinkTemplates.firstIndex(where: { $0.id == id }) else {
            return
        }

        userDrinkTemplates[index] = UserDrinkTemplate(
            id: id,
            brand: brand,
            name: name,
            category: category,
            caffeineMG: caffeineMG,
            sugarG: sugarG,
            volumeML: volumeML,
            preparationMethod: preparationMethod
        )
        persistUserDrinkTemplates()
        statusMessage = "已更新 \(name)。"
    }

    func deleteUserDrinkTemplate(id: String) {
        guard let index = userDrinkTemplates.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = userDrinkTemplates.remove(at: index)
        persistUserDrinkTemplates()
        statusMessage = "已删除 \(removed.name)。"
    }

    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        errorMessage = nil
        await reconcileCloudSnapshot(preferRemoteWhenLocalEmpty: true)
        session = await api.sessionStore.loadSession()
        refreshFromLocalCache(reason: nil)

        await searchCatalog(query: "")

        guard session != nil else {
            if config.hasRemoteAPI {
                statusMessage = statusMessage ?? "登录后会切到服务端真源，离线记录也会自动补同步。"
            } else {
                statusMessage = statusMessage ?? "当前没有配置后端地址，先使用本地预览和缓存模式。"
            }
            return
        }

        if session?.isExpired == true {
            await clearSession(resetOnboarding: false)
            errorMessage = "本地会话已过期，请重新登录。"
            return
        }

        await syncPendingLogs()
        await refreshRemoteState()
    }

    func continueWithPreviewMode() {
        defaults.set(true, forKey: AppPersistenceKeys.onboardingCompleted)
        hasCompletedOnboarding = true
        if config.hasRemoteAPI {
            statusMessage = "已进入体验模式，后续可以随时接入真实后端。"
        } else {
            statusMessage = "已进入预览模式。"
        }
    }

    func signInWithApple(identityToken: String) async {
        guard config.hasRemoteAPI else {
            errorMessage = "当前没有配置后端地址，无法发起登录。"
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let session = try await api.auth.exchangeAppleToken(
                identityToken: identityToken,
                deviceName: config.deviceName
            )
            errorMessage = nil
            self.session = session
            defaults.set(true, forKey: AppPersistenceKeys.onboardingCompleted)
            hasCompletedOnboarding = true
            statusMessage = "登录成功，正在同步今天的数据。"
            await api.sessionStore.saveSession(session)
            await syncPendingLogs()
            await refreshRemoteState()
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)"
        }
    }

    func signInWithDevelopmentToken() async {
        await signInWithApple(identityToken: config.makeDevelopmentIdentityToken())
    }

    func signOut() async {
        await clearSession(resetOnboarding: true)
        statusMessage = "已退出登录。"
    }

    func searchCatalog(query: String) async {
        if config.hasRemoteAPI {
            isSearchingCatalog = true
            defer { isSearchingCatalog = false }

            do {
                catalog = try await api.catalog.search(query: query)
                errorMessage = nil
                return
            } catch {
                errorMessage = "饮品目录暂时无法刷新：\(error.localizedDescription)"
            }
        }

        catalog = PreviewFixtures.previewSearchResults(for: query)
    }

    func record(drink: DrinkDefinitionSummary) async -> DrinkLogEntry? {
        isRecordingDrink = true
        defer { isRecordingDrink = false }

        let input = CreateDrinkLogInput(
            drinkDefinitionID: drink.id,
            servingOptionID: drink.preferredServing.id,
            ratio: 1.0,
            consumedAt: .now,
            note: nil,
            source: drink.id.hasPrefix("user-") ? .custom : .catalog
        )

        if session != nil, config.hasRemoteAPI {
            do {
                let entry = try await api.logs.createLog(input)
                cache.upsert(entries: [entry])
                queueSnapshotPush()
                statusMessage = "已记录 \(drink.name)。"
                await refreshRemoteState()
                return entry
            } catch {
                errorMessage = "网络暂不可用，已改为离线记录。"
            }
        }

        let pendingEntry = cache.createPendingEntry(from: drink, input: input, userID: session?.userID)
        queueSnapshotPush()
        await refreshLocalDashboard(
            reason: session != nil
                ? "已离线记录 \(drink.name)，稍后会自动补同步。"
                : "已先保存本地记录，登录后会自动补同步。"
        )
        return pendingEntry
    }

    func recordWithCelebration(_ drink: DrinkDefinitionSummary) async {
        let projectedTotal = dashboard.aggregate.caffeineMG + drink.metrics.caffeineMG
        let previousForecast = dashboard.caffeineForecast
        recentRecordDismissTask?.cancel()

        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            recentRecordFeedback = RecordCelebration(
                id: UUID().uuidString,
                style: .pending,
                title: "正在加入 \(drink.name)",
                subtitle: drink.brand,
                metricsLine: "预计咖啡因 +\(Int(drink.metrics.caffeineMG))mg · 累计约 \(Int(projectedTotal))mg",
                sleepLine: pendingSleepLine(for: drink, forecast: previousForecast),
                syncLine: session != nil ? "正在保存并刷新今日数据" : "先记在本地，稍后再补同步"
            )
        }

        guard let entry = await record(drink: drink) else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                recentRecordFeedback = nil
            }
            return
        }

        try? await Task.sleep(for: .milliseconds(180))

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            recentRecordFeedback = RecordCelebration(
                id: entry.id,
                style: .success,
                title: "已加入 \(drink.name)",
                subtitle: drink.brand,
                metricsLine: "咖啡因 +\(Int(entry.metrics.caffeineMG))mg · 当前累计 \(Int(dashboard.aggregate.caffeineMG))mg",
                sleepLine: resolvedSleepLine(previous: previousForecast, current: dashboard.caffeineForecast),
                syncLine: entry.isPendingSync ? "已离线保存，稍后会自动补同步" : "已保存，首页和分析已刷新"
            )
        }

        recentRecordDismissTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
                    recentRecordFeedback = nil
                }
            }
        }
    }

    func syncPendingLogs() async {
        guard session != nil else {
            return
        }

        let pending = cache.pendingSyncLogs()
        guard pending.isEmpty == false else {
            await updateSessionSyncState(lastSyncedAt: session?.sync.lastSyncedAt)
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        var syncedCount = 0
        for item in pending {
            do {
                let remoteEntry = try await api.logs.createLog(item.input)
                cache.replacePending(localID: item.localID, with: remoteEntry)
                syncedCount += 1
            } catch {
                errorMessage = "离线记录补同步中断：\(error.localizedDescription)"
                break
            }
        }

        await updateSessionSyncState(lastSyncedAt: syncedCount > 0 ? .now : session?.sync.lastSyncedAt)
        if syncedCount > 0 {
            queueSnapshotPush()
        }

        if syncedCount > 0 {
            statusMessage = "已补同步 \(syncedCount) 条离线记录。"
        }
    }

    func requestWeeklyExport() async {
        guard session != nil else {
            errorMessage = "请先登录后再请求导出。"
            return
        }

        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate) ?? endDate
            let url = try await api.exports.requestExport(format: "csv", startDate: startDate, endDate: endDate)
            statusMessage = "导出任务已创建：\(url.absoluteString)"
        } catch {
            errorMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    func refreshAIBrief(silently: Bool = false) async {
        guard isRefreshingAIBrief == false else {
            return
        }

        guard session != nil, config.hasRemoteAPI else {
            dashboard.aiBrief = PreviewFixtures.buildAIBrief(
                aggregate: dashboard.aggregate,
                goals: dashboard.goals,
                profile: profile,
                forecast: dashboard.caffeineForecast,
                recommendations: dashboard.recommendations
            )
            return
        }

        isRefreshingAIBrief = true
        defer { isRefreshingAIBrief = false }

        do {
            dashboard.aiBrief = try await api.insights.loadAIBrief()
            if silently == false {
                statusMessage = "AI 解读已更新。"
            }
        } catch {
            dashboard.aiBrief = PreviewFixtures.buildAIBrief(
                aggregate: dashboard.aggregate,
                goals: dashboard.goals,
                profile: profile,
                forecast: dashboard.caffeineForecast,
                recommendations: dashboard.recommendations
            )
            if silently == false {
                errorMessage = "AI 解读暂时不可用：\(error.localizedDescription)"
            }
        }
    }

    private func refreshRemoteState(for day: Date = .now) async {
        guard session != nil else {
            return
        }

        do {
            async let profileTask = api.profile.loadProfile()
            async let goalsTask = api.goals.loadGoals()
            async let entriesTask = api.logs.listLogs(day: day)
            async let aggregateTask = api.insights.loadAggregate(for: day)
            async let recommendationsTask = api.insights.loadRecommendations(for: day)
            async let forecastTask = api.insights.loadCaffeineForecast()

            let profile = try await profileTask
            let goals = try await goalsTask
            let entries = try await entriesTask
            let aggregate = try await aggregateTask
            let recommendations = try await recommendationsTask
            _ = try await forecastTask

            self.profile = profile
            cache.upsert(entries: entries)
            queueSnapshotPush()
            let entriesSorted = entries.sorted { $0.consumedAt > $1.consumedAt }
            let localForecast = PreviewFixtures.buildCaffeineForecast(
                entries: entriesSorted,
                profile: effectiveProfile,
                preferences: preferences
            )
            dashboard = DashboardState(
                date: aggregate.date,
                aggregate: aggregate.totals,
                goals: goals,
                recommendations: recommendations,
                todayEntries: entriesSorted,
                categoryBreakdown: aggregate.categoryBreakdown,
                caffeineForecast: localForecast,
                aiBrief: PreviewFixtures.buildAIBrief(
                    aggregate: aggregate.totals,
                    goals: goals,
                    profile: effectiveProfile,
                    forecast: localForecast,
                    recommendations: recommendations
                )
            )

            errorMessage = nil
            await updateSessionSyncState(lastSyncedAt: .now)
            statusMessage = pendingSyncCount == 0
                ? "已连接服务端真源，今日数据已刷新。"
                : "服务端已刷新，仍有 \(pendingSyncCount) 条待补同步。"
            Task {
                await self.refreshAIBrief(silently: true)
            }
        } catch {
            errorMessage = "服务端刷新失败：\(error.localizedDescription)"
            refreshFromLocalCache(reason: "已回退到本地缓存。")
        }
    }

    private func refreshLocalDashboard(reason: String?) async {
        refreshFromLocalCache(reason: reason)
        await updateSessionSyncState(lastSyncedAt: session?.sync.lastSyncedAt)
    }

    private func refreshFromLocalCache(reason: String?) {
        let cachedEntries = cache.loadLogs(for: .now)
        if cachedEntries.isEmpty {
            if shouldUsePreviewFallback {
                dashboard = PreviewFixtures.dashboard(
                    for: .now,
                    entries: PreviewFixtures.entries,
                    goals: dashboard.goals,
                    profile: effectiveProfile,
                    preferences: preferences
                )
            }
        } else {
            dashboard = PreviewFixtures.dashboard(
                for: .now,
                entries: cachedEntries,
                goals: dashboard.goals,
                profile: effectiveProfile,
                preferences: preferences
            )
        }

        rebuildLocalForecast(reason: nil)

        if let reason {
            statusMessage = reason
        }
    }

    private var shouldUsePreviewFallback: Bool {
        guard config.previewFallbackEnabled else {
            return false
        }

        let hasLocalData = cache.loadAllLogs().isEmpty == false || userDrinkTemplates.isEmpty == false
        if hasLocalData {
            return false
        }

        return session == nil && localSnapshotUpdatedAt == .distantPast
    }

    private func updateSessionSyncState(lastSyncedAt: Date?) async {
        guard var session else {
            return
        }

        session.sync.pendingEntryIDs = cache.pendingEntryIDs()
        if let lastSyncedAt {
            session.sync.lastSyncedAt = lastSyncedAt
        }
        self.session = session
        await api.sessionStore.saveSession(session)
    }

    private func clearSession(resetOnboarding: Bool) async {
        recentRecordDismissTask?.cancel()
        recentRecordFeedback = nil
        session = nil
        await api.sessionStore.saveSession(nil)
        if resetOnboarding {
            defaults.removeObject(forKey: AppPersistenceKeys.onboardingCompleted)
            hasCompletedOnboarding = false
        }
        profile = PreviewFixtures.profile
        catalog = PreviewFixtures.drinks
        preferences = loadPreferences()
        userDrinkTemplates = loadUserDrinkTemplates()
        refreshFromLocalCache(reason: nil)
    }

    private func persistPreferences(syncToCloud: Bool = true) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(preferences) else {
            return
        }
        defaults.set(data, forKey: AppPersistenceKeys.userPreferences)
        markLocalSnapshotUpdated()
        if syncToCloud {
            queueSnapshotPush()
        }
    }

    private func persistUserDrinkTemplates() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(userDrinkTemplates) else {
            return
        }
        defaults.set(data, forKey: AppPersistenceKeys.userDrinkTemplates)
        markLocalSnapshotUpdated()
        queueSnapshotPush()
    }

    private func loadPreferences() -> UserPreferenceSnapshot {
        guard
            let data = defaults.data(forKey: AppPersistenceKeys.userPreferences),
            let value = try? JSONDecoder().decode(UserPreferenceSnapshot.self, from: data)
        else {
            return PreviewFixtures.userPreferences
        }
        return value
    }

    private func loadUserDrinkTemplates() -> [UserDrinkTemplate] {
        guard
            let data = defaults.data(forKey: AppPersistenceKeys.userDrinkTemplates),
            let value = try? JSONDecoder().decode([UserDrinkTemplate].self, from: data)
        else {
            return PreviewFixtures.userDrinkTemplates
        }
        return value
    }

    private func rebuildLocalForecast(reason: String?) {
        dashboard.caffeineForecast = PreviewFixtures.buildCaffeineForecast(
            entries: dashboard.todayEntries,
            profile: effectiveProfile,
            preferences: preferences
        )
        profile.sleepHourText = preferences.sleepHourText
        profile.caffeineSensitive = preferences.metabolismProfile == .sensitive

        if let reason {
            statusMessage = reason
        }
    }

    private func registerSyncObserver() {
        syncObserver = NotificationCenter.default.addObserver(
            forName: syncProvider.externalChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.importCloudSnapshotIfNewer(statusMessage: "已从 iCloud 合并最新记录。")
            }
        }
    }

    private var localSnapshotUpdatedAt: Date {
        let raw = defaults.double(forKey: AppPersistenceKeys.localSnapshotUpdatedAt)
        guard raw > 0 else {
            return .distantPast
        }
        return Date(timeIntervalSince1970: raw)
    }

    private func markLocalSnapshotUpdated(_ date: Date = .now) {
        defaults.set(date.timeIntervalSince1970, forKey: AppPersistenceKeys.localSnapshotUpdatedAt)
    }

    private func buildLocalSnapshot(updatedAt: Date = .now) -> UserLocalSnapshot {
        UserLocalSnapshot(
            updatedAt: updatedAt,
            preferences: preferences,
            userDrinkTemplates: userDrinkTemplates,
            logs: cache.loadAllLogs()
        )
    }

    private func apply(snapshot: UserLocalSnapshot, statusMessage: String?) {
        var mergedPreferences = snapshot.preferences
        if preferences.iCloudPlanEnabled {
            mergedPreferences.iCloudPlanEnabled = true
        }
        preferences = mergedPreferences
        userDrinkTemplates = snapshot.userDrinkTemplates

        let encoder = JSONEncoder()
        if let preferencesData = try? encoder.encode(mergedPreferences) {
            defaults.set(preferencesData, forKey: AppPersistenceKeys.userPreferences)
        }
        if let templatesData = try? encoder.encode(snapshot.userDrinkTemplates) {
            defaults.set(templatesData, forKey: AppPersistenceKeys.userDrinkTemplates)
        }

        cache.replaceAllLogs(with: snapshot.logs)
        markLocalSnapshotUpdated(snapshot.updatedAt)
        refreshFromLocalCache(reason: nil)

        if let statusMessage {
            self.statusMessage = statusMessage
        }
    }

    private func queueSnapshotPush() {
        guard preferences.iCloudPlanEnabled else {
            return
        }

        let snapshot = buildLocalSnapshot()
        markLocalSnapshotUpdated(snapshot.updatedAt)

        Task { @MainActor [weak self] in
            await self?.pushCloudSnapshot(snapshot, statusMessage: nil)
        }
    }

    private func reconcileCloudSnapshot(
        preferRemoteWhenLocalEmpty: Bool,
        statusOnPull: String? = nil,
        statusOnPush: String? = nil
    ) async {
        guard preferences.iCloudPlanEnabled else {
            return
        }

        let remoteSnapshot = await syncProvider.loadSnapshot()
        let localSnapshot = buildLocalSnapshot(updatedAt: localSnapshotUpdatedAt == .distantPast ? .now : localSnapshotUpdatedAt)
        let localHasData = localSnapshot.logs.isEmpty == false || localSnapshot.userDrinkTemplates.isEmpty == false

        if let remoteSnapshot, shouldImport(snapshot: remoteSnapshot, preferRemoteWhenLocalEmpty: preferRemoteWhenLocalEmpty) {
            apply(snapshot: remoteSnapshot, statusMessage: statusOnPull)
            return
        }

        if remoteSnapshot == nil || localHasData {
            await pushCloudSnapshot(localSnapshot, statusMessage: statusOnPush)
        }
    }

    private func importCloudSnapshotIfNewer(statusMessage: String?) async {
        guard preferences.iCloudPlanEnabled else {
            return
        }

        guard let snapshot = await syncProvider.loadSnapshot() else {
            return
        }

        guard shouldImport(snapshot: snapshot, preferRemoteWhenLocalEmpty: true) else {
            return
        }

        apply(snapshot: snapshot, statusMessage: statusMessage)
    }

    private func shouldImport(snapshot: UserLocalSnapshot, preferRemoteWhenLocalEmpty: Bool) -> Bool {
        if snapshot.updatedAt > localSnapshotUpdatedAt.addingTimeInterval(1) {
            return true
        }

        if preferRemoteWhenLocalEmpty {
            let localHasData = cache.loadAllLogs().isEmpty == false || userDrinkTemplates.isEmpty == false
            let remoteHasData = snapshot.logs.isEmpty == false || snapshot.userDrinkTemplates.isEmpty == false
            return localHasData == false && remoteHasData
        }

        return false
    }

    private func pushCloudSnapshot(_ snapshot: UserLocalSnapshot, statusMessage: String?) async {
        guard preferences.iCloudPlanEnabled else {
            return
        }

        isSyncingCloudSnapshot = true
        defer { isSyncingCloudSnapshot = false }

        do {
            try await syncProvider.push(snapshot: snapshot)
            markLocalSnapshotUpdated(snapshot.updatedAt)
            if let statusMessage {
                self.statusMessage = statusMessage
            }
        } catch {
            if statusMessage != nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func pendingSleepLine(
        for drink: DrinkDefinitionSummary,
        forecast: CaffeineForecastSummary
    ) -> String {
        if drink.metrics.caffeineMG == 0 {
            return "这杯几乎不增加咖啡因负担，更适合守住今晚睡眠窗口。"
        }

        let referenceTime = (forecast.recommendedSleepTime ?? forecast.sleepAt)
            .formatted(date: .omitted, time: .shortened)

        switch forecast.sleepReadiness {
        case .sleepFriendly:
            return "预计会继续抬高今日咖啡因累计，先盯住 \(referenceTime) 这条入睡参考线。"
        case .watch:
            return "今晚睡眠窗口已经开始收紧，这杯之后更需要控制后续咖啡因。"
        case .likelyDisruptive:
            return "当前已在可能扰睡区间，再叠加会把更稳入睡时间继续往后推。"
        }
    }

    private func resolvedSleepLine(
        previous: CaffeineForecastSummary,
        current: CaffeineForecastSummary
    ) -> String {
        let previousReference = previous.recommendedSleepTime ?? previous.sleepAt
        let currentReference = current.recommendedSleepTime ?? current.sleepAt
        let deltaMinutes = Int(currentReference.timeIntervalSince(previousReference) / 60)
        let currentTimeText = currentReference.formatted(date: .omitted, time: .shortened)
        let readinessDelta = sleepRank(current.sleepReadiness) - sleepRank(previous.sleepReadiness)

        if readinessDelta > 0 {
            return "睡眠压力上升，更稳入睡参考已经推迟到 \(currentTimeText)。"
        }
        if readinessDelta < 0 {
            return "睡眠压力回落，当前入睡参考回到 \(currentTimeText)。"
        }
        if deltaMinutes >= 15 {
            return "这杯把更稳入睡时间又往后推了约 \(deltaMinutes) 分钟。"
        }
        if deltaMinutes <= -15 {
            return "这次新增没有继续拉晚睡眠窗口，参考时间回收了约 \(abs(deltaMinutes)) 分钟。"
        }

        switch current.sleepReadiness {
        case .sleepFriendly:
            return "按现在的节奏，仍然比较适合按计划时间入睡。"
        case .watch:
            return "睡眠窗口还在观察区，接下来更适合换低因或无因饮品。"
        case .likelyDisruptive:
            return "今晚仍可能扰睡，后续尽量不要继续叠加高咖啡因。"
        }
    }

    private func sleepRank(_ readiness: SleepReadinessState) -> Int {
        switch readiness {
        case .sleepFriendly:
            return 0
        case .watch:
            return 1
        case .likelyDisruptive:
            return 2
        }
    }
}

private extension Array {
    func uniqued<Value: Hashable>(on keyPath: KeyPath<Element, Value>) -> [Element] {
        var seen: Set<Value> = []
        var result: [Element] = []

        for item in self {
            let value = item[keyPath: keyPath]
            if seen.insert(value).inserted {
                result.append(item)
            }
        }

        return result
    }
}

@main
struct YinzhiApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}

struct AppRootView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.pageBackground
                .ignoresSafeArea()

            if environment.hasCompletedOnboarding {
                RootTabView(environment: environment)
            } else {
                OnboardingView(environment: environment)
            }

            if let feedback = environment.recentRecordFeedback, environment.hasCompletedOnboarding {
                GlobalRecordToast(feedback: feedback)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 104)
                    .allowsHitTesting(false)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: environment.recentRecordFeedback?.id)
        .task {
            await environment.bootstrap()
        }
    }
}

struct RootTabView: View {
    @Bindable var environment: AppEnvironment

    var body: some View {
        TabView(selection: $environment.selectedTab) {
            NavigationStack {
                HomeView(environment: environment)
            }
            .tabItem {
                Label(AppTab.home.rawValue, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            NavigationStack {
                LogView(environment: environment)
            }
            .tabItem {
                Label(AppTab.log.rawValue, systemImage: AppTab.log.systemImage)
            }
            .tag(AppTab.log)

            NavigationStack {
                InsightsView(environment: environment)
            }
            .tabItem {
                Label(AppTab.insights.rawValue, systemImage: AppTab.insights.systemImage)
            }
            .tag(AppTab.insights)

            NavigationStack {
                ProfileView(environment: environment)
            }
            .tabItem {
                Label(AppTab.profile.rawValue, systemImage: AppTab.profile.systemImage)
            }
            .tag(AppTab.profile)
        }
        .tint(AppTheme.accent)
    }
}

private struct GlobalRecordToast: View {
    let feedback: RecordCelebration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconTint.opacity(0.16))
                        .frame(width: 44, height: 44)
                    if feedback.style == .pending {
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(iconTint)
                            .symbolEffect(.pulse, value: feedback.id)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(iconTint)
                            .symbolEffect(.bounce, value: feedback.id)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(feedback.title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Text(statusLabel)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(iconTint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(iconTint.opacity(0.12), in: Capsule())
                    }

                    Text(feedback.subtitle)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(iconTint)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            toastLine(feedback.metricsLine, icon: "bolt.fill", tint: iconTint)
            toastLine(feedback.sleepLine, icon: "moon.stars.fill", tint: Color(red: 0.20, green: 0.47, blue: 0.74))
            toastLine(feedback.syncLine, icon: "arrow.triangle.2.circlepath", tint: .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(tint: iconTint.opacity(0.10), cornerRadius: 28, interactive: true, padding: 18)
        .shadow(color: iconTint.opacity(0.18), radius: 18, y: 10)
    }

    private func toastLine(_ text: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 18, height: 18)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(icon == "arrow.triangle.2.circlepath" ? .secondary : AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var iconName: String {
        switch feedback.style {
        case .pending:
            return "hourglass.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }

    private var statusLabel: String {
        switch feedback.style {
        case .pending:
            return "写入中"
        case .success:
            return "已完成"
        }
    }

    private var iconTint: Color {
        switch feedback.style {
        case .pending:
            return Color(red: 0.90, green: 0.53, blue: 0.18)
        case .success:
            return AppTheme.accent
        }
    }
}
