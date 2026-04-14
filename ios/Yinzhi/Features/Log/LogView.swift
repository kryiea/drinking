import Observation
import SwiftUI

struct LogView: View {
    @Bindable var environment: AppEnvironment
    @State private var query = ""

    var body: some View {
        List {
            Section("状态") {
                Label(environment.connectionTitle, systemImage: environment.session == nil ? "iphone.slash" : "server.rack")
                if environment.isSearchingCatalog {
                    Label("正在刷新饮品目录…", systemImage: "magnifyingglass.circle")
                }
                if environment.isRecordingDrink {
                    Label("正在提交记录…", systemImage: "drop.circle")
                }
                if let errorMessage = environment.errorMessage {
                    Text(errorMessage)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.orange)
                }
            }

            Section("饮品目录") {
                if environment.catalog.isEmpty {
                    Text("没有找到匹配的饮品，稍后会补上自定义模板入口。")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(environment.catalog) { drink in
                        Button {
                            Task {
                                await environment.record(drink: drink)
                            }
                        } label: {
                            DrinkCatalogRow(drink: drink)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if environment.dashboard.todayEntries.isEmpty == false {
                Section("今日已记录") {
                    ForEach(environment.dashboard.todayEntries) { entry in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.drinkName)
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                Text("\(entry.category) · \(entry.servingLabel)")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                if entry.isPendingSync {
                                    Text("待同步")
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("记录饮品")
        .searchable(text: $query, prompt: "搜索奶茶、咖啡、果汁…")
        .task(id: query) {
            try? await Task.sleep(for: .milliseconds(250))
            guard Task.isCancelled == false else {
                return
            }
            await environment.searchCatalog(query: query)
        }
    }
}

private struct DrinkCatalogRow: View {
    let drink: DrinkDefinitionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drink.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                    Text("\(drink.category) · \(drink.brand)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            HStack {
                Label("\(Int(drink.metrics.caffeineMG))mg", systemImage: "bolt.fill")
                Label("\(Int(drink.metrics.sugarG))g", systemImage: "drop.fill")
                Label("\(Int(drink.preferredServing.volumeML))ml", systemImage: "waterbottle")
            }
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
