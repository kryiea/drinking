import Observation
import SwiftUI

struct LogView: View {
    @Bindable var environment: AppEnvironment
    @State private var query = ""
    @State private var selectedBrand = "全部"
    @State private var selectedMethod: BrewMethod?
    @State private var selectedBrewDrinkID: String?
    @State private var brewStrength: BrewStrength = .balanced
    @State private var targetVolumeML = 320.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                commandDeck
                brandFilterRow
                if let brewDrink = activeBrewDrink, let recipe = brewDrink.brewRecipe {
                    brewLab(drink: brewDrink, recipe: recipe)
                }
                catalogSection
                recentSection
            }
            .padding(16)
        }
        .navigationTitle("记录饮品")
        .searchable(text: $query, prompt: "搜索品牌、品类、口味或设备…")
        .task(id: query) {
            try? await Task.sleep(for: .milliseconds(250))
            guard Task.isCancelled == false else {
                return
            }
            await environment.searchCatalog(query: query)
            reconcileSelection()
        }
        .task {
            reconcileSelection()
        }
        .onChange(of: environment.catalog) { _, _ in
            reconcileSelection()
        }
    }

    private var commandDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今天准备怎么喝")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("先选品牌和冲煮方式，再一键记录。首页只保留结果，这里负责细节。")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusChip(
                    label: environment.isRecordingDrink ? "记录中" : environment.connectionTitle,
                    systemImage: environment.isRecordingDrink ? "hourglass" : "server.rack"
                )
            }

            HStack(spacing: 10) {
                QuickStatCard(title: "品牌", value: "\(brandOptions.count - 1)")
                QuickStatCard(title: "冲煮", value: "\(methodOptions.count)")
                QuickStatCard(title: "目录", value: "\(filteredCatalog.count)")
            }
        }
        .adaptiveGlassCard(cornerRadius: 32, interactive: true)
    }

    private var brandFilterRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("品牌与方式")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(brandOptions, id: \.self) { brand in
                        FilterChip(
                            label: brand,
                            isSelected: selectedBrand == brand
                        ) {
                            selectedBrand = brand
                            reconcileSelection()
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(label: "全部方式", isSelected: selectedMethod == nil) {
                        selectedMethod = nil
                        reconcileSelection()
                    }

                    ForEach(methodOptions, id: \.self) { method in
                        FilterChip(
                            label: method.label,
                            icon: method.systemImage,
                            isSelected: selectedMethod == method
                        ) {
                            selectedMethod = method
                            reconcileSelection()
                        }
                    }
                }
            }
        }
    }

    private func brewLab(drink: DrinkDefinitionSummary, recipe: BrewRecipeSummary) -> some View {
        let preview = recipe.scaled(targetVolumeML: Int(targetVolumeML), strength: brewStrength)

        return SectionCard(title: "Brew Lab", subtitle: "\(drink.brand) · \(drink.name)") {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(brewCandidates) { item in
                            BrewChoiceCard(
                                drink: item,
                                isSelected: item.id == drink.id
                            ) {
                                selectedBrewDrinkID = item.id
                                targetVolumeML = Double(item.brewRecipe?.outputML ?? 320)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(recipe.title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                        Text(recipe.ratioText)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    Text(recipe.tastingNote ?? "用一个稳定的冲煮建议，把计算负担从首页拿开。")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Picker("浓度", selection: $brewStrength) {
                    ForEach(BrewStrength.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("目标杯量")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        Spacer()
                        Text("\(Int(targetVolumeML))ml")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    Slider(value: $targetVolumeML, in: 180 ... 560, step: 10)
                        .tint(AppTheme.accent)
                }

                HStack(spacing: 12) {
                    BrewNumber(title: "咖啡粉", value: preview.coffeeG, unit: "g")
                    BrewNumber(title: "热水", value: preview.waterML, unit: "ml")
                    BrewNumber(title: "奶 / 浓缩", value: max(preview.milkML, preview.concentrateML), unit: "ml")
                }

                Button {
                    Task {
                        await environment.record(drink: drink)
                    }
                } label: {
                    Label("记录这杯 \(drink.name)", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryCTAStyle())
            }
        }
    }

    private var catalogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("品牌目录")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                if environment.isSearchingCatalog {
                    Text("刷新中")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            if filteredCatalog.isEmpty {
                SectionCard(title: "还没有命中结果", subtitle: "可以改搜品牌、风味、设备或品类") {
                    Text("例如输入“Blue Bottle”“奶茶”“手冲”或“燕麦”。")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredCatalog) { drink in
                        DrinkCatalogCard(drink: drink) {
                            selectedBrewDrinkID = drink.id
                            Task {
                                await environment.record(drink: drink)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        Group {
            if environment.dashboard.todayEntries.isEmpty == false {
                SectionCard(title: "今日已记录", subtitle: "让最近输入留在这里，而不是挤到首页") {
                    VStack(spacing: 12) {
                        ForEach(environment.dashboard.todayEntries.prefix(5)) { entry in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(entry.drinkName)
                                            .font(.system(.headline, design: .rounded, weight: .semibold))
                                        if let brand = entry.brand {
                                            Text(brand)
                                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                                .foregroundStyle(AppTheme.accent)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(AppTheme.accentSoft.opacity(0.22), in: Capsule())
                                        }
                                    }
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
        }
    }

    private var filteredCatalog: [DrinkDefinitionSummary] {
        environment.catalog.filter { drink in
            let brandMatches = selectedBrand == "全部" || drink.brand == selectedBrand
            let methodMatches = selectedMethod == nil || (drink.preparationMethods ?? []).contains(selectedMethod!)
            return brandMatches && methodMatches
        }
    }

    private var brandOptions: [String] {
        ["全部"] + Array(Set(environment.catalog.map(\.brand))).sorted()
    }

    private var methodOptions: [BrewMethod] {
        Array(Set(environment.catalog.flatMap { $0.preparationMethods ?? [] })).sorted { $0.rawValue < $1.rawValue }
    }

    private var brewCandidates: [DrinkDefinitionSummary] {
        filteredCatalog.filter { $0.brewRecipe != nil }
    }

    private var activeBrewDrink: DrinkDefinitionSummary? {
        if let selectedBrewDrinkID {
            return brewCandidates.first(where: { $0.id == selectedBrewDrinkID })
        }
        return brewCandidates.first
    }

    private func reconcileSelection() {
        if selectedBrand != "全部", brandOptions.contains(selectedBrand) == false {
            selectedBrand = "全部"
        }
        if let selectedMethod, methodOptions.contains(selectedMethod) == false {
            self.selectedMethod = nil
        }
        if let selectedBrewDrinkID, brewCandidates.contains(where: { $0.id == selectedBrewDrinkID }) == false {
            self.selectedBrewDrinkID = brewCandidates.first?.id
        }
        if selectedBrewDrinkID == nil {
            selectedBrewDrinkID = brewCandidates.first?.id
        }
    }
}

private struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(label)
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(isSelected ? .white : AppTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.accent : Color.white.opacity(0.75), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct QuickStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(cornerRadius: 22, padding: 14)
    }
}

private struct BrewChoiceCard: View {
    let drink: DrinkDefinitionSummary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(drink.brand)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(isSelected ? .white.opacity(0.88) : AppTheme.accent)
                Text(drink.name)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(isSelected ? .white : AppTheme.ink)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .background(isSelected ? AppTheme.accent : Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct BrewNumber: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text("\(value.formatted(.number.precision(.fractionLength(0 ... 1))))\(unit)")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(cornerRadius: 22, padding: 14)
    }
}

private struct DrinkCatalogCard: View {
    let drink: DrinkDefinitionSummary
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(drink.brand)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    Text(drink.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(drink.heroFlavor ?? "\(drink.category) · \(drink.brandCollection ?? "目录款")")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: action) {
                    Label("记录", systemImage: "plus.circle.fill")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                }
                .buttonStyle(CatalogRecordButtonStyle())
            }

            if let methods = drink.preparationMethods, methods.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(methods, id: \.self) { method in
                            Label(method.label, systemImage: method.systemImage)
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.72), in: Capsule())
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                BrewNumber(title: "咖啡因", value: drink.metrics.caffeineMG, unit: "mg")
                BrewNumber(title: "糖分", value: drink.metrics.sugarG, unit: "g")
                BrewNumber(title: "容量", value: Double(drink.preferredServing.volumeML), unit: "ml")
            }
        }
        .adaptiveGlassCard(cornerRadius: 30, interactive: true)
    }
}

private struct CatalogRecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular.tint(AppTheme.accent).interactive(), in: .rect(cornerRadius: 999))
                .opacity(configuration.isPressed ? 0.84 : 1)
        } else {
            configuration.label
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.accent.opacity(configuration.isPressed ? 0.82 : 1), in: Capsule())
        }
    }
}
