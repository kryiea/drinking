import Observation
import SwiftUI

private enum AppPersistenceKeys {
    static let onboardingCompleted = "com.luca.yinzhi.onboarding.completed"
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
    var isBootstrapping = false
    var isAuthenticating = false
    var isSearchingCatalog = false
    var isRecordingDrink = false
    var isSyncing = false
    var statusMessage: String?
    var errorMessage: String?

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let config: AppConfig
    @ObservationIgnored private let api: APIContainer
    @ObservationIgnored private let cache: OfflineCacheStore

    init(
        config: AppConfig = .current,
        api: APIContainer? = nil,
        cache: OfflineCacheStore = OfflineCacheStore()
    ) {
        self.config = config
        self.api = api ?? APIContainer.make(config: config)
        self.cache = cache
        hasCompletedOnboarding = defaults.bool(forKey: AppPersistenceKeys.onboardingCompleted)
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

    var connectionTitle: String {
        if session != nil {
            return "服务端真源已连接"
        }
        if config.hasRemoteAPI {
            return "本地缓存 / 待登录"
        }
        return "预览模式"
    }

    var backendDisplayText: String {
        config.apiBaseURL?.absoluteString ?? "未配置后端地址"
    }

    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        errorMessage = nil
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
                return
            } catch {
                errorMessage = "饮品目录暂时无法刷新：\(error.localizedDescription)"
            }
        }

        catalog = PreviewFixtures.previewSearchResults(for: query)
    }

    func record(drink: DrinkDefinitionSummary) async {
        isRecordingDrink = true
        defer { isRecordingDrink = false }

        let input = CreateDrinkLogInput(
            drinkDefinitionID: drink.id,
            servingOptionID: drink.preferredServing.id,
            ratio: 1.0,
            consumedAt: .now,
            note: nil,
            source: .catalog
        )

        if session != nil, config.hasRemoteAPI {
            do {
                let entry = try await api.logs.createLog(input)
                cache.upsert(entries: [entry])
                statusMessage = "已记录 \(drink.name)。"
                await refreshRemoteState()
                return
            } catch {
                errorMessage = "网络暂不可用，已改为离线记录。"
            }
        }

        _ = cache.createPendingEntry(from: drink, input: input, userID: session?.userID)
        await refreshLocalDashboard(
            reason: session != nil
                ? "已离线记录 \(drink.name)，稍后会自动补同步。"
                : "已先保存本地记录，登录后会自动补同步。"
        )
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

            let profile = try await profileTask
            let goals = try await goalsTask
            let entries = try await entriesTask
            let aggregate = try await aggregateTask
            let recommendations = try await recommendationsTask

            self.profile = profile
            cache.upsert(entries: entries)
            dashboard = DashboardState(
                date: aggregate.date,
                aggregate: aggregate.totals,
                goals: goals,
                recommendations: recommendations,
                todayEntries: entries.sorted { $0.consumedAt > $1.consumedAt },
                categoryBreakdown: aggregate.categoryBreakdown
            )

            await updateSessionSyncState(lastSyncedAt: .now)
            statusMessage = pendingSyncCount == 0
                ? "已连接服务端真源，今日数据已刷新。"
                : "服务端已刷新，仍有 \(pendingSyncCount) 条待补同步。"
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
            if session == nil || config.previewFallbackEnabled {
                dashboard = PreviewFixtures.dashboard
            }
        } else {
            dashboard = PreviewFixtures.dashboard(
                for: .now,
                entries: cachedEntries,
                goals: dashboard.goals,
                profile: profile
            )
        }

        if let reason {
            statusMessage = reason
        }
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
        session = nil
        await api.sessionStore.saveSession(nil)
        if resetOnboarding {
            defaults.removeObject(forKey: AppPersistenceKeys.onboardingCompleted)
            hasCompletedOnboarding = false
        }
        dashboard = PreviewFixtures.dashboard
        profile = PreviewFixtures.profile
        catalog = PreviewFixtures.drinks
    }
}

@main
struct YinzhiApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppTheme.pageBackground
                    .ignoresSafeArea()

                if environment.hasCompletedOnboarding {
                    RootTabView(environment: environment)
                } else {
                    OnboardingView(environment: environment)
                }
            }
            .task {
                await environment.bootstrap()
            }
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
