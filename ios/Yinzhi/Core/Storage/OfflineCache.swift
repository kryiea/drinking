import Foundation
import SwiftData

@Model
final class CachedDrinkLog {
    @Attribute(.unique) var id: String
    var userID: String
    var drinkDefinitionID: String
    var drinkName: String
    var category: String
    var consumedAt: Date
    var servingOptionID: String
    var servingLabel: String
    var ratio: Double
    var caffeineMG: Double
    var sugarG: Double
    var caloriesKcal: Double
    var hydrationML: Double
    var volumeML: Double
    var note: String?
    var source: String
    var version: Int
    var syncState: String

    init(
        id: String,
        userID: String,
        drinkDefinitionID: String,
        drinkName: String,
        category: String,
        consumedAt: Date,
        servingOptionID: String,
        servingLabel: String,
        ratio: Double,
        caffeineMG: Double,
        sugarG: Double,
        caloriesKcal: Double,
        hydrationML: Double,
        volumeML: Double,
        note: String? = nil,
        source: String,
        version: Int = 1,
        syncState: String = SyncState.synced.rawValue
    ) {
        self.id = id
        self.userID = userID
        self.drinkDefinitionID = drinkDefinitionID
        self.drinkName = drinkName
        self.category = category
        self.consumedAt = consumedAt
        self.servingOptionID = servingOptionID
        self.servingLabel = servingLabel
        self.ratio = ratio
        self.caffeineMG = caffeineMG
        self.sugarG = sugarG
        self.caloriesKcal = caloriesKcal
        self.hydrationML = hydrationML
        self.volumeML = volumeML
        self.note = note
        self.source = source
        self.version = version
        self.syncState = syncState
    }

    convenience init(entry: DrinkLogEntry) {
        self.init(
            id: entry.id,
            userID: entry.userID ?? "local-user",
            drinkDefinitionID: entry.drinkDefinitionID ?? "unknown-definition",
            drinkName: entry.drinkName,
            category: entry.category,
            consumedAt: entry.consumedAt,
            servingOptionID: "unknown-serving",
            servingLabel: entry.servingLabel,
            ratio: 1.0,
            caffeineMG: entry.metrics.caffeineMG,
            sugarG: entry.metrics.sugarG,
            caloriesKcal: entry.metrics.caloriesKcal,
            hydrationML: entry.metrics.hydrationML,
            volumeML: entry.metrics.volumeML,
            note: entry.note,
            source: entry.source.rawValue,
            version: entry.version,
            syncState: entry.syncStatus.rawValue
        )
    }

    var asEntry: DrinkLogEntry {
        DrinkLogEntry(
            id: id,
            userID: userID,
            drinkDefinitionID: drinkDefinitionID,
            drinkName: drinkName,
            category: category,
            consumedAt: consumedAt,
            servingLabel: servingLabel,
            metrics: IngredientMetrics(
                caffeineMG: caffeineMG,
                sugarG: sugarG,
                caloriesKcal: caloriesKcal,
                hydrationML: hydrationML,
                volumeML: volumeML
            ),
            note: note,
            source: DrinkLogSource(rawValue: source) ?? .catalog,
            version: version,
            syncStatus: SyncState(rawValue: syncState) ?? .pending
        )
    }

    var asCreateInput: CreateDrinkLogInput {
        CreateDrinkLogInput(
            drinkDefinitionID: drinkDefinitionID,
            servingOptionID: servingOptionID.isEmpty ? nil : servingOptionID,
            ratio: ratio,
            consumedAt: consumedAt,
            note: note,
            source: DrinkLogSource(rawValue: source) ?? .catalog
        )
    }

    func overwrite(with entry: DrinkLogEntry) {
        userID = entry.userID ?? userID
        drinkDefinitionID = entry.drinkDefinitionID ?? drinkDefinitionID
        drinkName = entry.drinkName
        category = entry.category
        consumedAt = entry.consumedAt
        servingLabel = entry.servingLabel
        caffeineMG = entry.metrics.caffeineMG
        sugarG = entry.metrics.sugarG
        caloriesKcal = entry.metrics.caloriesKcal
        hydrationML = entry.metrics.hydrationML
        volumeML = entry.metrics.volumeML
        note = entry.note
        source = entry.source.rawValue
        version = entry.version
        syncState = entry.syncStatus.rawValue
    }
}

struct PendingSyncLog: Sendable {
    let localID: String
    let input: CreateDrinkLogInput
}

@MainActor
final class OfflineCacheStore {
    private let container: ModelContainer?

    init(inMemory: Bool = false) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: CachedDrinkLog.self, configurations: configuration)
        } catch {
            container = nil
        }
    }

    var isAvailable: Bool {
        container != nil
    }

    func loadLogs(for day: Date) -> [DrinkLogEntry] {
        guard let context = container?.mainContext else {
            return []
        }

        let range = dayRange(for: day)
        let start = range.start
        let end = range.end
        let descriptor = FetchDescriptor<CachedDrinkLog>(
            predicate: #Predicate<CachedDrinkLog> { item in
                item.consumedAt >= start && item.consumedAt < end
            },
            sortBy: [SortDescriptor(\.consumedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor).map(\.asEntry)) ?? []
    }

    func upsert(entries: [DrinkLogEntry]) {
        guard let context = container?.mainContext else {
            return
        }

        for entry in entries {
            upsert(entry: entry, in: context)
        }

        try? context.save()
    }

    func createPendingEntry(
        from definition: DrinkDefinitionSummary,
        input: CreateDrinkLogInput,
        userID: String?
    ) -> DrinkLogEntry {
        let serving = definition.servingOptions.first { $0.id == input.servingOptionID } ?? definition.preferredServing
        let scaledMetrics = definition.metrics.scaled(by: input.ratio * serving.multiplier)
        let pendingEntry = DrinkLogEntry(
            id: "pending-\(UUID().uuidString.lowercased())",
            userID: userID,
            drinkDefinitionID: definition.id,
            drinkName: definition.name,
            category: definition.category,
            consumedAt: input.consumedAt,
            servingLabel: serving.name,
            metrics: scaledMetrics,
            note: input.note,
            source: input.source,
            version: 1,
            syncStatus: .pending
        )

        guard let context = container?.mainContext else {
            return pendingEntry
        }

        let cached = CachedDrinkLog(
            id: pendingEntry.id,
            userID: userID ?? "local-user",
            drinkDefinitionID: definition.id,
            drinkName: definition.name,
            category: definition.category,
            consumedAt: input.consumedAt,
            servingOptionID: serving.id,
            servingLabel: serving.name,
            ratio: input.ratio,
            caffeineMG: scaledMetrics.caffeineMG,
            sugarG: scaledMetrics.sugarG,
            caloriesKcal: scaledMetrics.caloriesKcal,
            hydrationML: scaledMetrics.hydrationML,
            volumeML: scaledMetrics.volumeML,
            note: input.note,
            source: input.source.rawValue,
            version: pendingEntry.version,
            syncState: SyncState.pending.rawValue
        )
        context.insert(cached)
        try? context.save()
        return pendingEntry
    }

    func pendingSyncLogs() -> [PendingSyncLog] {
        guard let context = container?.mainContext else {
            return []
        }

        let pendingValue = SyncState.pending.rawValue
        let descriptor = FetchDescriptor<CachedDrinkLog>(
            predicate: #Predicate<CachedDrinkLog> { item in
                item.syncState == pendingValue
            },
            sortBy: [SortDescriptor(\.consumedAt, order: .forward)]
        )

        return (try? context.fetch(descriptor).map {
            PendingSyncLog(localID: $0.id, input: $0.asCreateInput)
        }) ?? []
    }

    func pendingEntryIDs() -> [String] {
        pendingSyncLogs().map(\.localID)
    }

    func replacePending(localID: String, with entry: DrinkLogEntry) {
        guard let context = container?.mainContext else {
            return
        }

        delete(id: localID, in: context)
        upsert(entry: entry, in: context)
        try? context.save()
    }

    private func upsert(entry: DrinkLogEntry, in context: ModelContext) {
        if let existing = fetch(id: entry.id, in: context) {
            existing.overwrite(with: entry)
        } else {
            context.insert(CachedDrinkLog(entry: entry))
        }
    }

    private func fetch(id: String, in context: ModelContext) -> CachedDrinkLog? {
        let lookupID = id
        let descriptor = FetchDescriptor<CachedDrinkLog>(
            predicate: #Predicate<CachedDrinkLog> { item in
                item.id == lookupID
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func delete(id: String, in context: ModelContext) {
        guard let entry = fetch(id: id, in: context) else {
            return
        }
        context.delete(entry)
    }

    private func dayRange(for day: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .day, for: day) ?? DateInterval(start: day, duration: 24 * 60 * 60)
    }
}
