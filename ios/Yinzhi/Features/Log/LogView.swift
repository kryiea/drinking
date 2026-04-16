import Observation
import PhotosUI
import SwiftUI
import UIKit

private enum DirectoryScope: String, CaseIterable, Identifiable {
    case coffee
    case milkTea
    case mine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee:
            return "咖啡"
        case .milkTea:
            return "奶茶"
        case .mine:
            return "我的"
        }
    }
}

struct LogView: View {
    @Bindable var environment: AppEnvironment

    @State private var query = ""
    @State private var selectedBrand = "全部"
    @State private var selectedBrewDrinkID: String?
    @State private var brewStrength: BrewStrength = .balanced
    @State private var targetVolumeML = 320.0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isPresentingCamera = false
    @State private var isRecognizingQuickCapture = false
    @State private var isPresentingVoiceCapture = false
    @State private var isPresentingAddTemplate = false
    @State private var isPresentingManageTemplates = false
    @State private var isPresentingQuickCaptureHub = false
    @State private var isPresentingCalculator = false
    @State private var selectedDirectoryScope: DirectoryScope = .coffee
    @State private var quickCaptureResult: QuickCaptureRecognitionResult?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                commandDeck

                if let feedback = successFeedback {
                    nextStepRail(feedback: feedback)
                }

                if recentLoggedEntries.isEmpty == false {
                    recentLoggedStrip
                }

                directoryPicker

                if let brewDrink = activeBrewDrink, let recipe = brewDrink.brewRecipe {
                    brewLab(drink: brewDrink, recipe: recipe)
                }

                directorySection
            }
            .padding(16)
            .padding(.bottom, 112)
        }
        .navigationTitle("记录")
        .searchable(text: $query, prompt: "搜品牌、饮品或口味")
        .navigationDestination(isPresented: $isPresentingCalculator) {
            CaffeineCalculatorView()
        }
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else {
                return
            }

            Task {
                await recognizePhotoItem(newItem)
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let data = newImage?.jpegData(compressionQuality: 0.88) else {
                return
            }

            Task {
                await recognizeImage(data: data, source: .camera)
            }
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraCaptureView(image: $capturedImage)
                .ignoresSafeArea()
        }
        .sheet(item: $quickCaptureResult) { result in
            QuickCaptureResultSheet(
                result: result,
                isRecording: environment.isRecordingDrink
            ) { drink in
                Task {
                    await environment.recordWithCelebration(drink)
                }
            } onUseSuggestedQuery: { suggestedQuery in
                query = suggestedQuery
            }
        }
        .sheet(isPresented: $isPresentingVoiceCapture) {
            VoiceCaptureSheet(catalog: environment.allDrinkDefinitions) { result in
                quickCaptureResult = result
            } onUseSuggestedQuery: { suggestedQuery in
                query = suggestedQuery
            }
        }
        .sheet(isPresented: $isPresentingQuickCaptureHub) {
            QuickCaptureHubSheet(
                selectedPhotoItem: $selectedPhotoItem,
                isRecognizingQuickCapture: isRecognizingQuickCapture,
                recentDrinkTitle: recentQuickDrink.map { "\($0.brand) · \($0.name)" }
            ) {
                isPresentingVoiceCapture = true
            } onUseCamera: {
                openCamera()
            } onUseRecent: {
                if let recentQuickDrink {
                    record(recentQuickDrink)
                } else {
                    isPresentingAddTemplate = true
                }
            } onAddCustom: {
                isPresentingAddTemplate = true
            }
        }
        .sheet(isPresented: $isPresentingAddTemplate) {
            AddDrinkTemplateSheet(environment: environment)
        }
        .sheet(isPresented: $isPresentingManageTemplates) {
            ManageDrinkTemplatesSheet(environment: environment)
        }
    }

    private var commandDeck: some View {
        let libraryTitle = isRecognizingQuickCapture ? "识别中" : "相册"

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("记录入口")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("先记下这一杯，目录放在下面慢慢找。")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusChip(
                    label: statusLabel,
                    systemImage: statusSymbol,
                    tint: statusTint.opacity(0.18)
                )
            }

            Button {
                isPresentingQuickCaptureHub = true
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("记一杯")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("语音、拍照、相册、最近复用都从这里开始")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.86))
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.white.opacity(0.18), in: Circle())
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .shadow(color: AppTheme.accent.opacity(0.22), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(environment.isRecordingDrink)
            .opacity(environment.isRecordingDrink ? 0.8 : 1)

            HStack(spacing: 10) {
                Button {
                    isPresentingVoiceCapture = true
                } label: {
                    CompactEntryButton(
                        title: "语音",
                        systemImage: "waveform.circle.fill",
                        tint: AppTheme.accent
                    )
                }
                .buttonStyle(.plain)
                .disabled(environment.isRecordingDrink)

                Button {
                    openCamera()
                } label: {
                    CompactEntryButton(
                        title: "拍照",
                        systemImage: "camera.viewfinder",
                        tint: Color(red: 0.35, green: 0.56, blue: 0.44)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRecognizingQuickCapture || environment.isRecordingDrink)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    CompactEntryButton(
                        title: libraryTitle,
                        systemImage: "photo.on.rectangle.angled",
                        tint: Color(red: 0.20, green: 0.47, blue: 0.74)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRecognizingQuickCapture || environment.isRecordingDrink)
            }

            Button {
                isPresentingCalculator = true
            } label: {
                QuickRepeatCard(
                    title: "咖啡因计算器",
                    subtitle: "估算一杯或一套配方的咖啡因",
                    caption: "进入二层页面计算",
                    tint: Color(red: 0.22, green: 0.47, blue: 0.82)
                )
            }
            .buttonStyle(.plain)

            if let recentQuickDrink {
                Button {
                    record(recentQuickDrink)
                } label: {
                    QuickRepeatCard(
                        title: "再来一杯",
                        subtitle: "\(recentQuickDrink.brand) · \(recentQuickDrink.name)",
                        caption: "直接复用最近喝过的那杯",
                        tint: AppTheme.accent
                    )
                }
                .buttonStyle(.plain)
                .disabled(environment.isRecordingDrink)
            }

            if environment.frequentDrinkDefinitions.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(environment.frequentDrinkDefinitions.prefix(4)) { drink in
                            Button(action: { record(drink) }) {
                                CompactDeckChip(label: "\(drink.brand) · \(drink.name)", tint: AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                            .disabled(environment.isRecordingDrink)
                        }
                    }
                }
            }
        }
        .adaptiveGlassCard(cornerRadius: 32, interactive: true)
    }

    private var directoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("品牌目录")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 10) {
                ForEach(DirectoryScope.allCases) { scope in
                    FilterChip(label: scope.title, isSelected: selectedDirectoryScope == scope) {
                        selectedDirectoryScope = scope
                        reconcileSelection()
                    }
                }
            }

            if scopedBrandOptions.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(scopedBrandOptions, id: \.self) { brand in
                            FilterChip(label: brand, isSelected: selectedBrand == brand) {
                                selectedBrand = brand
                                reconcileSelection()
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentLoggedStrip: some View {
        SectionCard(title: "刚记过", subtitle: "直接复用最近的几杯") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentLoggedEntries) { entry in
                        Button {
                            if let drink = drinkDefinition(for: entry) {
                                record(drink)
                            }
                        } label: {
                            RecentLogPill(entry: entry, isEnabled: drinkDefinition(for: entry) != nil)
                        }
                        .buttonStyle(.plain)
                        .disabled(drinkDefinition(for: entry) == nil || environment.isRecordingDrink)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var directorySection: some View {
        SectionCard(
            title: directoryTitle,
            subtitle: directorySubtitle
        ) {
            if directoryDrinks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedDirectoryScope == .mine ? "还没有自定义饮品。" : "当前没有命中的饮品。")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)

                    if selectedDirectoryScope == .mine {
                        Button("新增我的饮品") {
                            isPresentingAddTemplate = true
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())

                        Button("管理我的饮品") {
                            isPresentingManageTemplates = true
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }
                }
            } else {
                VStack(spacing: 10) {
                    if selectedDirectoryScope == .mine {
                        HStack {
                            Spacer()
                            Button("管理我的饮品") {
                                isPresentingManageTemplates = true
                            }
                            .buttonStyle(.plain)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        }
                    }

                    ForEach(directoryDrinks) { drink in
                        CompactDrinkRow(
                            drink: drink,
                            isRecording: environment.isRecordingDrink,
                            onRecord: { record(drink) },
                            onOpenBrew: { openBrew(drink) }
                        )
                    }
                }
            }
        }
    }

    private func nextStepRail(feedback: RecordCelebration) -> some View {
        SectionCard(title: "继续记录", subtitle: "这杯已经记好了，下一步直接点") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(feedback.title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(feedback.sleepLine)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    StatusChip(
                        label: "已写入",
                        systemImage: "checkmark.circle.fill",
                        tint: AppTheme.accent.opacity(0.14)
                    )
                }

                HStack(spacing: 10) {
                    railActionButton(
                        title: "再来同款",
                        systemImage: "arrow.clockwise.circle.fill"
                    ) {
                        guard let latestRecordedDrink else {
                            return
                        }
                        record(latestRecordedDrink)
                    }

                    railActionButton(
                        title: "看今晚影响",
                        systemImage: "moon.stars.fill"
                    ) {
                        environment.selectedTab = .insights
                    }

                    railActionButton(
                        title: "继续搜目录",
                        systemImage: "magnifyingglass"
                    ) {
                        resetSelectionContext()
                    }
                }
            }
        }
    }

    private func brewLab(drink: DrinkDefinitionSummary, recipe: BrewRecipeSummary) -> some View {
        let preview = recipe.scaled(targetVolumeML: Int(targetVolumeML), strength: brewStrength)

        return SectionCard(title: "手冲 / 咖啡机", subtitle: "\(drink.brand) · \(drink.name)") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(recipe.ratioText)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    Spacer()
                    Button("收起") {
                        selectedBrewDrinkID = nil
                    }
                    .buttonStyle(.plain)
                    .font(.system(.caption, design: .rounded, weight: .bold))
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
                        await environment.recordWithCelebration(drink)
                    }
                } label: {
                    Label(environment.isRecordingDrink ? "加入中" : "记录这杯", systemImage: environment.isRecordingDrink ? "hourglass" : "plus.circle.fill")
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(environment.isRecordingDrink)
            }
        }
    }

    private var filteredResultsSection: some View {
        let drinks = Array(filteredCatalog)

        return SectionCard(
            title: "筛选结果",
            subtitle: drinks.isEmpty ? "没有命中" : "共 \(drinks.count) 条"
        ) {
            if drinks.isEmpty {
                Text("试试换品牌、方式或关键词。")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(drinks) { drink in
                        CompactDrinkRow(
                            drink: drink,
                            isRecording: environment.isRecordingDrink,
                            onRecord: { record(drink) },
                            onOpenBrew: { openBrew(drink) }
                        )
                    }
                }
            }
        }
    }

    private func groupedSection(
        title: String,
        subtitle: String,
        drinks: [DrinkDefinitionSummary],
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        let visibleDrinks = Array(drinks.prefix(6))

        return SectionCard(title: "", subtitle: nil) {
            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(subtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(drinks.count)")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppTheme.accent.opacity(0.12), in: Capsule())

                    if let actionTitle, let action {
                        Button(action: action) {
                            Label(actionTitle, systemImage: "plus")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.72), in: Capsule())
                    }
                }

                ForEach(visibleDrinks) { drink in
                    CompactDrinkRow(
                        drink: drink,
                        isRecording: environment.isRecordingDrink,
                        onRecord: { record(drink) },
                        onOpenBrew: { openBrew(drink) }
                    )
                }
            }
        }
    }

    private var personalDrinks: [DrinkDefinitionSummary] {
        applyFilters(to: environment.personalDrinkDefinitions)
    }

    private var coffeeSectionDrinks: [DrinkDefinitionSummary] {
        applyFilters(to: environment.mainstreamCoffeeCatalog)
    }

    private var milkTeaSectionDrinks: [DrinkDefinitionSummary] {
        applyFilters(to: environment.mainstreamMilkTeaCatalog)
    }

    private var filteredCatalog: [DrinkDefinitionSummary] {
        applyFilters(to: environment.allDrinkDefinitions)
    }

    private var directoryDrinks: [DrinkDefinitionSummary] {
        switch selectedDirectoryScope {
        case .coffee:
            return coffeeSectionDrinks
        case .milkTea:
            return milkTeaSectionDrinks
        case .mine:
            return personalDrinks
        }
    }

    private var directoryTitle: String {
        switch selectedDirectoryScope {
        case .coffee:
            return "咖啡品牌"
        case .milkTea:
            return "奶茶品牌"
        case .mine:
            return "我的饮品"
        }
    }

    private var directorySubtitle: String {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "搜索“\(query.trimmingCharacters(in: .whitespacesAndNewlines))”"
        }
        return selectedBrand == "全部" ? "按品牌浏览并直接记录" : selectedBrand
    }

    private var recentLoggedEntries: [DrinkLogEntry] {
        Array(environment.dashboard.todayEntries.prefix(3))
    }

    private func applyFilters(to drinks: [DrinkDefinitionSummary]) -> [DrinkDefinitionSummary] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return drinks.filter { drink in
            let brandMatches = selectedBrand == "全部" || drink.brand == selectedBrand

            let queryMatches: Bool
            if trimmedQuery.isEmpty {
                queryMatches = true
            } else {
                queryMatches =
                    drink.name.localizedCaseInsensitiveContains(trimmedQuery)
                    || drink.brand.localizedCaseInsensitiveContains(trimmedQuery)
                    || drink.category.localizedCaseInsensitiveContains(trimmedQuery)
                    || drink.heroFlavor?.localizedCaseInsensitiveContains(trimmedQuery) == true
                    || drink.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmedQuery) })
            }

            return brandMatches && queryMatches
        }
    }

    private var scopedBrandOptions: [String] {
        let brands = scopedBrandSource
            .map(\.brand)
            .filter { $0.isEmpty == false }

        return ["全部"] + Array(Set(brands)).sorted()
    }

    private var scopedBrandSource: [DrinkDefinitionSummary] {
        let base: [DrinkDefinitionSummary]
        switch selectedDirectoryScope {
        case .coffee:
            base = environment.mainstreamCoffeeCatalog
        case .milkTea:
            base = environment.mainstreamMilkTeaCatalog
        case .mine:
            base = environment.personalDrinkDefinitions
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return base
        }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.brand.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.category.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private var activeBrewDrink: DrinkDefinitionSummary? {
        if let selectedBrewDrinkID {
            return filteredCatalog.first(where: { $0.id == selectedBrewDrinkID })
                ?? environment.allDrinkDefinitions.first(where: { $0.id == selectedBrewDrinkID })
        }
        return nil
    }

    private var recentQuickDrink: DrinkDefinitionSummary? {
        environment.recentDrinkDefinitions.first
    }

    private var latestRecordedDrink: DrinkDefinitionSummary? {
        environment.recentDrinkDefinitions.first
    }

    private var successFeedback: RecordCelebration? {
        guard let feedback = environment.recentRecordFeedback, feedback.style == .success else {
            return nil
        }
        return feedback
    }

    private var statusLabel: String {
        if isRecognizingQuickCapture {
            return "识别中"
        }
        if environment.isRecordingDrink {
            return "记录中"
        }
        return environment.connectionShortLabel
    }

    private var statusSymbol: String {
        if isRecognizingQuickCapture {
            return "viewfinder.circle"
        }
        if environment.isRecordingDrink {
            return "hourglass"
        }
        return environment.connectionSystemImage
    }

    private var statusTint: Color {
        if isRecognizingQuickCapture {
            return Color(red: 0.20, green: 0.47, blue: 0.74)
        }
        if environment.isRecordingDrink {
            return Color.orange
        }
        return environment.connectionTint
    }

    private func record(_ drink: DrinkDefinitionSummary) {
        Task {
            await environment.recordWithCelebration(drink)
        }
    }

    private func drinkDefinition(for entry: DrinkLogEntry) -> DrinkDefinitionSummary? {
        if let id = entry.drinkDefinitionID {
            return environment.allDrinkDefinitions.first(where: { $0.id == id })
        }
        return environment.allDrinkDefinitions.first {
            $0.name == entry.drinkName && $0.brand == entry.brand
        }
    }

    private func resetSelectionContext() {
        query = ""
        selectedBrand = "全部"
        selectedBrewDrinkID = nil
    }

    private func openBrew(_ drink: DrinkDefinitionSummary) {
        selectedBrewDrinkID = drink.id
        targetVolumeML = drink.brewRecipe?.outputML ?? Double(drink.preferredServing.volumeML)
    }

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            isPresentingCamera = true
        } else {
            errorToast("当前模拟器不支持相机，请改用相册识别。")
        }
    }

    private func recognizePhotoItem(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw QuickCaptureRecognizerError.unreadableImage
            }
            await MainActor.run {
                selectedPhotoItem = nil
            }
            await recognizeImage(data: data, source: .library)
        } catch {
            await MainActor.run {
                isRecognizingQuickCapture = false
                errorToast(error.localizedDescription)
            }
        }
    }

    private func recognizeImage(data: Data, source: QuickCaptureSource) async {
        await MainActor.run {
            isRecognizingQuickCapture = true
        }

        do {
            let result = try await QuickCaptureRecognizer.recognize(
                imageData: data,
                source: source,
                catalog: environment.allDrinkDefinitions
            )
            await MainActor.run {
                isRecognizingQuickCapture = false
                quickCaptureResult = result
            }
        } catch {
            await MainActor.run {
                isRecognizingQuickCapture = false
                errorToast(error.localizedDescription)
            }
        }
    }

    private func reconcileSelection() {
        if selectedBrand != "全部", scopedBrandOptions.contains(selectedBrand) == false {
            selectedBrand = "全部"
        }
        if let selectedBrewDrinkID, environment.allDrinkDefinitions.contains(where: { $0.id == selectedBrewDrinkID }) == false {
            self.selectedBrewDrinkID = nil
        }
    }

    private func errorToast(_ message: String) {
        environment.errorMessage = message
    }
}

private struct RailActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 68)
            .adaptiveGlassCard(tint: AppTheme.cardTint.opacity(0.08), cornerRadius: 22, interactive: true, padding: 12)
        }
        .buttonStyle(.plain)
    }
}

private struct CompactEntryButton: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct QuickRepeatCard: View {
    let title: String
    let subtitle: String
    let caption: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
                Text(subtitle)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text(caption)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tint)
        }
        .adaptiveGlassCard(tint: tint.opacity(0.08), cornerRadius: 24, interactive: true, padding: 16)
    }
}

private extension LogView {
    func railActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        RailActionButton(title: title, systemImage: systemImage, action: action)
    }
}

private struct FilterChip: View {
    let label: String
    var icon: String? = nil
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(AppTheme.accent)
                    } else {
                        Capsule().fill(Color.white.opacity(0.68))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactDeckChip: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct CompactDrinkRow: View {
    let drink: DrinkDefinitionSummary
    var isRecording: Bool
    let onRecord: () -> Void
    let onOpenBrew: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(drink.brand)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    if drink.id.hasPrefix("user-") {
                        Text("我的")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.72), in: Capsule())
                    }
                }

                Text(drink.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                if secondaryLine.isEmpty == false {
                    Text(secondaryLine)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    compactMetric("\(Int(drink.metrics.caffeineMG))mg")
                    compactMetric("\(drink.preferredServing.volumeML)ml")
                    if drink.metrics.sugarG > 0 {
                        compactMetric("\(Int(drink.metrics.sugarG))g 糖")
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                if drink.brewRecipe != nil {
                    Button("冲煮") {
                        onOpenBrew()
                    }
                    .buttonStyle(.plain)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.72), in: Capsule())
                }

                Button(action: onRecord) {
                    Image(systemName: isRecording ? "hourglass" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRecording)
            }
        }
        .adaptiveGlassCard(cornerRadius: 24, interactive: true, padding: 14)
        .opacity(isRecording ? 0.8 : 1)
    }

    private var secondaryLine: String {
        let methodText = drink.methodLabels.prefix(2).joined(separator: " · ")
        let flavorText = drink.heroFlavor ?? ""
        if methodText.isEmpty {
            return flavorText
        }
        if flavorText.isEmpty {
            return methodText
        }
        return "\(methodText) · \(flavorText)"
    }

    private func compactMetric(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.68), in: Capsule())
    }
}

private struct CatalogMiniCard: View {
    let drink: DrinkDefinitionSummary
    var isRecording: Bool
    let onRecord: () -> Void
    let onOpenBrew: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(drink.brand)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .lineLimit(1)

                Spacer(minLength: 6)

                if drink.brewRecipe != nil {
                    Button(action: onOpenBrew) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.72), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(drink.name)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(alignment: .lastTextBaseline) {
                Text("\(Int(drink.metrics.caffeineMG))mg")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onRecord) {
                    Image(systemName: isRecording ? "hourglass" : "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRecording)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .adaptiveGlassCard(cornerRadius: 22, interactive: true, padding: 14)
        .opacity(isRecording ? 0.8 : 1)
    }
}

private struct RecentLogPill: View {
    let entry: DrinkLogEntry
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.brand ?? "最近一杯")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.accent)
            Text(entry.drinkName)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
            Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 132, alignment: .leading)
        .adaptiveGlassCard(tint: AppTheme.cardTint.opacity(0.08), cornerRadius: 22, interactive: true, padding: 14)
        .opacity(isEnabled ? 1 : 0.58)
    }
}

private struct QuickCaptureHubSheet: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?

    @Environment(\.dismiss) private var dismiss

    let isRecognizingQuickCapture: Bool
    let recentDrinkTitle: String?
    let onUseVoice: () -> Void
    let onUseCamera: () -> Void
    let onUseRecent: () -> Void
    let onAddCustom: () -> Void

    var body: some View {
        let libraryTitle = isRecognizingQuickCapture ? "相册识别中" : "相册识别"

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: "记一杯", subtitle: "先选最顺手的入口") {
                        VStack(spacing: 12) {
                            actionButton(
                                title: "语音输入",
                                subtitle: "说一句品牌和饮品",
                                systemImage: "waveform.circle.fill",
                                tint: AppTheme.accent
                            ) {
                                dismiss()
                                onUseVoice()
                            }

                            actionButton(
                                title: "拍照识别",
                                subtitle: "拍包装、杯贴或菜单",
                                systemImage: "camera.viewfinder",
                                tint: Color(red: 0.35, green: 0.56, blue: 0.44)
                            ) {
                                dismiss()
                                onUseCamera()
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                QuickCaptureHubRow(
                                    title: libraryTitle,
                                    subtitle: "从相册挑一张继续识别",
                                    systemImage: "photo.on.rectangle.angled",
                                    tint: Color(red: 0.20, green: 0.47, blue: 0.74)
                                )
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                dismiss()
                            })

                            actionButton(
                                title: recentDrinkTitle == nil ? "新增饮品" : "再来一杯",
                                subtitle: recentDrinkTitle ?? "把你的常喝加进个人分区",
                                systemImage: recentDrinkTitle == nil ? "plus.circle" : "clock.arrow.trianglehead.counterclockwise.rotate.90",
                                tint: recentDrinkTitle == nil ? Color(red: 0.90, green: 0.53, blue: 0.18) : AppTheme.accent
                            ) {
                                dismiss()
                                onUseRecent()
                            }
                        }
                    }

                    SectionCard(title: "记录原则", subtitle: "先记下，再慢慢细化目录") {
                        Text("把主流动作集中在这里，避免每次都先浏览大目录。")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("快速记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("新增饮品") {
                        dismiss()
                        onAddCustom()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            QuickCaptureHubRow(title: title, subtitle: subtitle, systemImage: systemImage, tint: tint)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickCaptureHubRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .adaptiveGlassCard(tint: tint.opacity(0.08), cornerRadius: 24, interactive: true, padding: 14)
    }
}

private struct BrewNumber: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Text("\(Int(value.rounded()))\(unit)")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassCard(cornerRadius: 20, padding: 12)
    }
}

private struct CaffeineCalculatorView: View {
    @State private var beansGrams = 18.0
    @State private var extractionRatio = 1.35
    @State private var cups = 1.0

    private var estimatedCaffeineMG: Int {
        Int((beansGrams * 12 * extractionRatio * cups).rounded())
    }

    var body: some View {
        List {
            Section("估算参数") {
                sliderRow(title: "咖啡粉", value: $beansGrams, range: 8 ... 40, unit: "g")
                sliderRow(title: "萃取系数", value: $extractionRatio, range: 0.8 ... 1.8, unit: "")
                sliderRow(title: "杯数", value: $cups, range: 1 ... 4, unit: "杯", step: 1)
            }

            Section("结果") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(estimatedCaffeineMG) mg")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                    Text("按咖啡豆约每克 12mg 咖啡因的经验值估算，适合离线快速估一杯或一套配方。")
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("咖啡因计算器")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String,
        step: Double = 0.1
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(unit.isEmpty ? value.wrappedValue.formatted(.number.precision(.fractionLength(1))) : "\(Int(value.wrappedValue.rounded()))\(unit)")
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
                .tint(AppTheme.accent)
        }
        .padding(.vertical, 4)
    }
}

private struct AddDrinkTemplateSheet: View {
    @Bindable var environment: AppEnvironment

    @Environment(\.dismiss) private var dismiss

    var editingTemplate: UserDrinkTemplate?

    @State private var brand = ""
    @State private var name = ""
    @State private var category = "咖啡"
    @State private var caffeineMG = 95.0
    @State private var sugarG = 0.0
    @State private var volumeML = 320.0
    @State private var preparationMethod: BrewMethod = .espressoMachine

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: "新增我的饮品", subtitle: "以后会固定出现在个人分区") {
                        VStack(spacing: 14) {
                            TextField("品牌，例如 家里 / 公司楼下", text: $brand)
                                .textFieldStyle(.roundedBorder)
                            TextField("饮品名，例如 自制冷萃", text: $name)
                                .textFieldStyle(.roundedBorder)

                            Picker("分类", selection: $category) {
                                Text("咖啡").tag("咖啡")
                                Text("奶茶").tag("奶茶")
                                Text("其他").tag("其他")
                            }
                            .pickerStyle(.segmented)

                            Picker("方式", selection: $preparationMethod) {
                                ForEach(BrewMethod.allCases, id: \.self) { method in
                                    Text(method.label).tag(method)
                                }
                            }
                            .pickerStyle(.menu)

                            sliderRow(title: "咖啡因", value: $caffeineMG, range: 0 ... 240, unit: "mg")
                            sliderRow(title: "糖分", value: $sugarG, range: 0 ... 45, unit: "g")
                            sliderRow(title: "杯量", value: $volumeML, range: 120 ... 700, unit: "ml")
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("我的饮品")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard let editingTemplate else {
                    return
                }
                brand = editingTemplate.brand
                name = editingTemplate.name
                category = editingTemplate.category
                caffeineMG = editingTemplate.caffeineMG
                sugarG = editingTemplate.sugarG
                volumeML = Double(editingTemplate.volumeML)
                preparationMethod = editingTemplate.preparationMethod ?? .espressoMachine
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingTemplate == nil ? "保存" : "更新") {
                        save()
                    }
                    .disabled(canSave == false)
                }
            }
        }
    }

    private var canSave: Bool {
        brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @ViewBuilder
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))\(unit)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            Slider(value: value, in: range, step: 1)
                .tint(AppTheme.accent)
        }
    }

    private func save() {
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let roundedVolume = Int(volumeML.rounded())

        if let editingTemplate {
            environment.updateUserDrinkTemplate(
                id: editingTemplate.id,
                brand: trimmedBrand,
                name: trimmedName,
                category: category,
                caffeineMG: caffeineMG,
                sugarG: sugarG,
                volumeML: roundedVolume,
                preparationMethod: preparationMethod
            )
        } else {
            environment.addUserDrinkTemplate(
                brand: trimmedBrand,
                name: trimmedName,
                category: category,
                caffeineMG: caffeineMG,
                sugarG: sugarG,
                volumeML: roundedVolume,
                preparationMethod: preparationMethod
            )
        }
        dismiss()
    }
}

private struct ManageDrinkTemplatesSheet: View {
    @Bindable var environment: AppEnvironment

    @Environment(\.dismiss) private var dismiss

    @State private var editingTemplate: UserDrinkTemplate?
    @State private var isPresentingAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if environment.userDrinkTemplates.isEmpty {
                        SectionCard(title: "还没有个人饮品", subtitle: "先加 1 个，后面就能一直复用") {
                            Button("新增我的饮品") {
                                isPresentingAdd = true
                            }
                            .buttonStyle(PrimaryCTAStyle())
                        }
                    } else {
                        SectionCard(title: "管理我的饮品", subtitle: "可以编辑参数，也可以删掉不用的") {
                            VStack(spacing: 10) {
                                ForEach(environment.userDrinkTemplates) { template in
                                    templateRow(template)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("管理饮品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("新增") {
                        isPresentingAdd = true
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddDrinkTemplateSheet(environment: environment)
        }
        .sheet(item: $editingTemplate) { template in
            AddDrinkTemplateSheet(environment: environment, editingTemplate: template)
        }
    }

    private func templateRow(_ template: UserDrinkTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(template.brand)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    Text(template.name)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(template.detailLine)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button("编辑") {
                    editingTemplate = template
                }
                .buttonStyle(SecondaryGlassButtonStyle())

                Button("删除") {
                    environment.deleteUserDrinkTemplate(id: template.id)
                }
                .buttonStyle(SecondaryGlassButtonStyle())
            }
        }
        .adaptiveGlassCard(cornerRadius: 24, padding: 14)
    }
}
