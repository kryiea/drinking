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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                recordHeader
                selectorSearchField
                quickActionStrip
                scopePicker

                if selectedDirectoryScope != .mine, scopedBrandOptions.isEmpty == false {
                    brandCircleRail
                }

                if hasQuery {
                    selectorDrinkSection(
                        title: "搜索结果",
                        subtitle: "直接点一行就能记录",
                        drinks: filteredCatalog,
                        showsManageAction: false
                    )
                } else {
                    if recentLoggedEntries.isEmpty == false {
                        recentSelectorSection
                    }

                    if selectedDirectoryScope != .mine, featuredPersonalDrinks.isEmpty == false {
                        selectorDrinkSection(
                            title: "我的饮品",
                            subtitle: "自己常喝的几杯放在前面",
                            drinks: featuredPersonalDrinks,
                            showsManageAction: true
                        )
                    }

                    selectorDrinkSection(
                        title: directoryTitle,
                        subtitle: directorySubtitle,
                        drinks: directoryDrinks,
                        showsManageAction: selectedDirectoryScope == .mine
                    )
                }

                if let brewDrink = activeBrewDrink, let recipe = brewDrink.brewRecipe {
                    brewLab(drink: brewDrink, recipe: recipe)
                }
            }
            .padding(16)
            .padding(.bottom, 112)
        }
        .background(recordPageBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isPresentingCalculator) {
            CaffeineCalculatorView(environment: environment)
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

    private var recordHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("记一杯")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("搜到就记，不先读说明。")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusChip(
                label: statusLabel,
                systemImage: statusSymbol,
                tint: statusTint.opacity(0.16)
            )
        }
    }

    private var selectorSearchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)

            TextField("搜索品牌、饮品或口味", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.headline, design: .rounded, weight: .semibold))

            if hasQuery {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.elevatedSurface, in: Capsule())
        .shadow(color: AppTheme.shadow, radius: 12, y: 6)
    }

    private var quickActionStrip: some View {
        let libraryTitle = isRecognizingQuickCapture ? "识别中" : "相册"

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickActionButton(
                    title: "语音",
                    systemImage: "waveform.circle.fill",
                    tint: AppTheme.accent
                ) {
                    isPresentingVoiceCapture = true
                }

                quickActionButton(
                    title: "拍照",
                    systemImage: "camera.viewfinder",
                    tint: Color(red: 0.38, green: 0.58, blue: 0.47)
                ) {
                    openCamera()
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    QuickActionPill(
                        title: libraryTitle,
                        systemImage: "photo.on.rectangle.angled",
                        tint: Color(red: 0.24, green: 0.50, blue: 0.82)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRecognizingQuickCapture || environment.isRecordingDrink)

                quickActionButton(
                    title: "计算器",
                    systemImage: "dial.medium",
                    tint: Color(red: 0.81, green: 0.49, blue: 0.20)
                ) {
                    isPresentingCalculator = true
                }

                if let recentQuickDrink {
                    Button {
                        record(recentQuickDrink)
                    } label: {
                        QuickActionPill(
                            title: "再来一杯",
                            systemImage: "arrow.clockwise.circle.fill",
                            tint: AppTheme.accent
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(environment.isRecordingDrink)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var scopePicker: some View {
        HStack(spacing: 10) {
            ForEach(DirectoryScope.allCases) { scope in
                FilterChip(label: scope.title, isSelected: selectedDirectoryScope == scope) {
                    selectedDirectoryScope = scope
                    reconcileSelection()
                }
            }
        }
    }

    private var brandCircleRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(scopedBrandOptions, id: \.self) { brand in
                    BrandCircleChip(
                        brand: brand,
                        isSelected: selectedBrand == brand
                    ) {
                        selectedBrand = brand
                        reconcileSelection()
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var recentSelectorSection: some View {
        SelectorSectionCard(title: "最近", subtitle: "从今天和最近常点里继续") {
            VStack(spacing: 0) {
                ForEach(Array(recentLoggedEntries.enumerated()), id: \.element.id) { index, entry in
                    Button {
                        if let drink = drinkDefinition(for: entry) {
                            record(drink)
                        }
                    } label: {
                        SelectorRecentRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .disabled(drinkDefinition(for: entry) == nil || environment.isRecordingDrink)

                    if index != recentLoggedEntries.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
        }
    }

    private func selectorDrinkSection(
        title: String,
        subtitle: String,
        drinks: [DrinkDefinitionSummary],
        showsManageAction: Bool
    ) -> some View {
        SelectorSectionCard(
            title: title,
            subtitle: drinks.isEmpty ? "当前还没有可选内容" : subtitle,
            actionTitle: showsManageAction ? "管理" : nil,
            action: showsManageAction ? { isPresentingManageTemplates = true } : nil
        ) {
            if drinks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedDirectoryScope == .mine ? "先新增 1 个自己的饮品，后面就能一直复用。" : "换个品牌、分类或关键词再试试。")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)

                    if selectedDirectoryScope == .mine {
                        Button("新增我的饮品") {
                            isPresentingAddTemplate = true
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(drinks.enumerated()), id: \.element.id) { index, drink in
                        SelectorDrinkRow(
                            drink: drink,
                            isRecording: environment.isRecordingDrink,
                            onRecord: { record(drink) },
                            onOpenBrew: drink.brewRecipe == nil ? nil : { openBrew(drink) }
                        )

                        if index != drinks.count - 1 {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
            }
        }
    }

    private var hasQuery: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var featuredPersonalDrinks: [DrinkDefinitionSummary] {
        Array(personalDrinks.prefix(4))
    }

    private var recordPageBackground: some View {
        ZStack {
            AppTheme.pageBackground

            Circle()
                .fill(AppTheme.ambientCloud.opacity(0.92))
                .frame(width: 280, height: 280)
                .blur(radius: 68)
                .offset(x: -130, y: -220)
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
        .sorted { lhs, rhs in
            let lhsRank = brandPriority(for: lhs.brand)
            let rhsRank = brandPriority(for: rhs.brand)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            if lhs.brand != rhs.brand {
                return lhs.brand.localizedCompare(rhs.brand) == .orderedAscending
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    private var scopedBrandOptions: [String] {
        let brands = scopedBrandSource
            .map(\.brand)
            .filter { $0.isEmpty == false }

        return ["全部"] + Array(Set(brands)).sorted { lhs, rhs in
            let lhsRank = brandPriority(for: lhs)
            let rhsRank = brandPriority(for: rhs)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.localizedCompare(rhs) == .orderedAscending
        }
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

    private func brandPriority(for brand: String) -> Int {
        let priorities: [String]
        switch selectedDirectoryScope {
        case .coffee:
            priorities = ["瑞幸", "星巴克", "库迪", "MANNER", "Blue Bottle", "Peet's", "M Stand", "Seesaw"]
        case .milkTea:
            priorities = ["喜茶", "霸王茶姬", "一点点", "奈雪", "茶百道", "古茗", "沪上阿姨"]
        case .mine:
            priorities = []
        }

        if let index = priorities.firstIndex(of: brand) {
            return index
        }
        return priorities.count + 20
    }
}

private struct QuickActionPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct BrandVisual {
    let fill: Color
    let foreground: Color
    let accent: Color
    let kind: Kind

    enum Kind {
        case all
        case luckin
        case starbucks
        case cotti
        case heytea
        case chagee
        case alittle
        case blueBottle
        case letter(String)
    }

    static func forBrand(_ brand: String) -> BrandVisual {
        switch brand {
        case "全部":
            return BrandVisual(
                fill: AppTheme.accent.opacity(0.16),
                foreground: AppTheme.accent,
                accent: AppTheme.accent,
                kind: .all
            )
        case "瑞幸":
            return BrandVisual(
                fill: Color(red: 0.16, green: 0.29, blue: 0.80),
                foreground: .white,
                accent: Color(red: 0.16, green: 0.29, blue: 0.80),
                kind: .luckin
            )
        case "星巴克":
            return BrandVisual(
                fill: Color(red: 0.05, green: 0.42, blue: 0.31),
                foreground: .white,
                accent: Color(red: 0.05, green: 0.42, blue: 0.31),
                kind: .starbucks
            )
        case "库迪":
            return BrandVisual(
                fill: Color(red: 0.10, green: 0.11, blue: 0.14),
                foreground: Color(red: 0.96, green: 0.60, blue: 0.20),
                accent: Color(red: 0.96, green: 0.60, blue: 0.20),
                kind: .cotti
            )
        case "喜茶":
            return BrandVisual(
                fill: Color(red: 0.09, green: 0.09, blue: 0.10),
                foreground: .white,
                accent: Color(red: 0.09, green: 0.09, blue: 0.10),
                kind: .heytea
            )
        case "霸王茶姬":
            return BrandVisual(
                fill: Color(red: 0.80, green: 0.23, blue: 0.18),
                foreground: .white,
                accent: Color(red: 0.80, green: 0.23, blue: 0.18),
                kind: .chagee
            )
        case "一点点":
            return BrandVisual(
                fill: Color(red: 0.89, green: 0.26, blue: 0.22),
                foreground: .white,
                accent: Color(red: 0.89, green: 0.26, blue: 0.22),
                kind: .alittle
            )
        case "Blue Bottle":
            return BrandVisual(
                fill: Color(red: 0.13, green: 0.44, blue: 0.93),
                foreground: .white,
                accent: Color(red: 0.13, green: 0.44, blue: 0.93),
                kind: .blueBottle
            )
        case "MANNER":
            return BrandVisual(
                fill: Color(red: 0.13, green: 0.13, blue: 0.15),
                foreground: .white,
                accent: Color(red: 0.13, green: 0.13, blue: 0.15),
                kind: .letter("M")
            )
        case "M Stand":
            return BrandVisual(
                fill: Color(red: 0.15, green: 0.15, blue: 0.17),
                foreground: .white,
                accent: Color(red: 0.15, green: 0.15, blue: 0.17),
                kind: .letter("M")
            )
        case "Peet's":
            return BrandVisual(
                fill: Color(red: 0.18, green: 0.12, blue: 0.10),
                foreground: .white,
                accent: Color(red: 0.18, green: 0.12, blue: 0.10),
                kind: .letter("P")
            )
        case "Seesaw":
            return BrandVisual(
                fill: Color(red: 0.21, green: 0.20, blue: 0.18),
                foreground: .white,
                accent: Color(red: 0.21, green: 0.20, blue: 0.18),
                kind: .letter("S")
            )
        default:
            let fallback = brand.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "?"
            return BrandVisual(
                fill: AppTheme.accent.opacity(0.16),
                foreground: AppTheme.accent,
                accent: AppTheme.accent,
                kind: .letter(fallback)
            )
        }
    }
}

private struct BrandLogoBadge: View {
    let brand: String
    var size: CGFloat = 44
    var isSelected: Bool = false
    var isFilled: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let visual = BrandVisual.forBrand(brand)
        ZStack {
            Circle()
                .fill(backgroundFill(for: visual))
                .overlay(
                    Circle()
                        .stroke(borderColor(for: visual), lineWidth: isSelected ? 2 : 1)
                )

            logoContent(for: visual)
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
        .shadow(color: shadowColor(for: visual), radius: isSelected ? 14 : 0, y: isSelected ? 8 : 0)
    }

    private func backgroundFill(for visual: BrandVisual) -> Color {
        if isFilled {
            return visual.fill
        }
        return visual.fill.opacity(colorScheme == .dark ? 0.24 : 0.14)
    }

    private func borderColor(for visual: BrandVisual) -> Color {
        if isSelected {
            return visual.accent.opacity(colorScheme == .dark ? 0.92 : 0.72)
        }
        return AppTheme.glassStroke
    }

    private func shadowColor(for visual: BrandVisual) -> Color {
        guard isSelected else {
            return .clear
        }
        return visual.accent.opacity(colorScheme == .dark ? 0.36 : 0.18)
    }

    @ViewBuilder
    private func logoContent(for visual: BrandVisual) -> some View {
        switch visual.kind {
        case .all:
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(visual.foreground)
        case .luckin:
            LuckinAntlerMark(color: visual.foreground)
        case .starbucks:
            ZStack {
                Circle()
                    .stroke(visual.foreground.opacity(0.9), lineWidth: size * 0.08)
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.18, weight: .black))
                    .foregroundStyle(visual.foreground)
            }
            .padding(size * 0.05)
        case .cotti:
            Text("C")
                .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                .foregroundStyle(visual.foreground)
        case .heytea:
            Text("喜")
                .font(.system(size: size * 0.30, weight: .black, design: .rounded))
                .foregroundStyle(visual.foreground)
        case .chagee:
            Text("茶")
                .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                .foregroundStyle(visual.foreground)
        case .alittle:
            OneDotMark(color: visual.foreground)
        case .blueBottle:
            BlueBottleMark(color: visual.foreground)
        case .letter(let glyph):
            Text(glyph)
                .font(.system(size: size * 0.30, weight: .black, design: .rounded))
                .foregroundStyle(visual.foreground)
        }
    }
}

private struct LuckinAntlerMark: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: width * 0.18, height: width * 0.18)
                    .offset(y: height * 0.18)

                HStack(spacing: width * 0.18) {
                    antler(left: true, width: width, height: height)
                    antler(left: false, width: width, height: height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func antler(left: Bool, width: CGFloat, height: CGFloat) -> some View {
        let direction: CGFloat = left ? -1 : 1

        return ZStack {
            Capsule()
                .fill(color)
                .frame(width: width * 0.11, height: height * 0.46)
                .rotationEffect(.degrees(Double(direction) * 28))
                .offset(y: -height * 0.04)

            Capsule()
                .fill(color)
                .frame(width: width * 0.08, height: height * 0.24)
                .rotationEffect(.degrees(Double(direction) * -30))
                .offset(x: direction * width * 0.12, y: -height * 0.18)

            Capsule()
                .fill(color)
                .frame(width: width * 0.07, height: height * 0.18)
                .rotationEffect(.degrees(Double(direction) * 12))
                .offset(x: -direction * width * 0.04, y: -height * 0.30)
        }
    }
}

private struct OneDotMark: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                Text("1")
                    .font(.system(size: width * 0.56, weight: .black, design: .rounded))
                    .foregroundStyle(color)

                Circle()
                    .fill(color)
                    .frame(width: width * 0.14, height: width * 0.14)
                    .offset(x: -width * 0.28, y: width * 0.18)

                Circle()
                    .fill(color)
                    .frame(width: width * 0.10, height: width * 0.10)
                    .offset(x: width * 0.28, y: width * 0.16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct BlueBottleMark: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            Capsule()
                .fill(color)
                .frame(width: width * 0.32, height: height * 0.72)
                .overlay(
                    Capsule()
                        .fill(Color.clear)
                        .stroke(color.opacity(0.9), lineWidth: 0)
                )
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(color)
                        .frame(width: width * 0.14, height: height * 0.12)
                        .offset(y: -height * 0.12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct BrandCircleChip: View {
    let brand: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BrandLogoBadge(
                brand: brand,
                size: 52,
                isSelected: isSelected,
                isFilled: isSelected
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SelectorSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.plain)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            content
        }
        .padding(18)
        .background(AppTheme.panelSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.outline, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 16, y: 10)
    }
}

private struct DrinkLeadingMark: View {
    let brand: String?
    let category: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BrandLogoBadge(
                brand: brand?.isEmpty == false ? brand! : category,
                size: 44,
                isFilled: true
            )

            Circle()
                .fill(AppTheme.elevatedSurface)
                .frame(width: 18, height: 18)
                .overlay(
                    Image(systemName: baseIcon)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                )
                .offset(x: 2, y: 2)
        }
    }

    private var baseIcon: String {
        if category.contains("奶茶") || category.contains("果茶") {
            return "takeoutbag.and.cup.and.straw.fill"
        }
        if category.contains("手冲") {
            return "drop.fill"
        }
        return "cup.and.saucer.fill"
    }
}

private struct SelectorDrinkRow: View {
    let drink: DrinkDefinitionSummary
    let isRecording: Bool
    let onRecord: () -> Void
    let onOpenBrew: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            DrinkLeadingMark(brand: drink.brand, category: drink.category)

            VStack(alignment: .leading, spacing: 6) {
                Text(drink.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text(metaLine)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                if let onOpenBrew {
                    Button {
                        onOpenBrew()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.softFill, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onRecord) {
                    Image(systemName: isRecording ? "hourglass" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRecording)
            }
        }
        .padding(.vertical, 12)
        .opacity(isRecording ? 0.82 : 1)
    }

    private var metaLine: String {
        "\(Int(drink.metrics.caffeineMG))mg · \(compactServingName(drink.preferredServing.name, volumeML: drink.preferredServing.volumeML))"
    }
}

private struct SelectorRecentRow: View {
    let entry: DrinkLogEntry

    var body: some View {
        HStack(spacing: 12) {
            DrinkLeadingMark(brand: entry.brand, category: entry.category)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.drinkName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text(metaLine)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(dateText)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var dateText: String {
        if Calendar.current.isDateInToday(entry.consumedAt) {
            return entry.consumedAt.formatted(date: .omitted, time: .shortened)
        }
        return entry.consumedAt.formatted(.dateTime.month().day())
    }

    private var metaLine: String {
        var parts = ["\(Int(entry.metrics.caffeineMG))mg"]
        let serving = compactServingName(entry.servingLabel, volumeML: Int(entry.metrics.volumeML.rounded()))
        if serving.isEmpty == false {
            parts.append(serving)
        }
        return parts.joined(separator: " · ")
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

    func quickActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            QuickActionPill(title: title, systemImage: systemImage, tint: tint)
        }
        .buttonStyle(.plain)
        .disabled(isRecognizingQuickCapture || environment.isRecordingDrink)
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
                        Capsule().fill(AppTheme.elevatedSurface)
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppTheme.accent.opacity(0.28) : AppTheme.glassStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private func compactServingName(_ label: String, volumeML: Int) -> String {
    let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return volumeML > 0 ? "\(volumeML)ml" : ""
    }
    if trimmed.contains("标准") || trimmed.contains("默认") {
        return volumeML > 0 ? "\(volumeML)ml" : trimmed
    }
    return trimmed
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
    @Bindable var environment: AppEnvironment

    @Environment(\.dismiss) private var dismiss

    @State private var input = CaffeineCalculatorInput.preset(for: .espresso)
    @State private var isPresentingSaveTemplate = false
    @State private var isPresentingInfo = false
    @State private var didCopyValue = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var estimatedCaffeineMG: Int {
        CaffeineCalculatorEstimator.estimateMG(for: input)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                calculatorHeader
                methodHero
                resultCard
                parameterGrid
            }
            .padding(16)
            .padding(.bottom, 136)
        }
        .background(calculatorBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, AppTheme.elevatedSurface.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 18)

                bottomActionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
                    .padding(.bottom, 6)
                    .background(AppTheme.elevatedSurface.opacity(0.82))
            }
        }
        .sheet(isPresented: $isPresentingSaveTemplate) {
            SaveCalculatorTemplateSheet(
                environment: environment,
                method: input.method,
                estimatedCaffeineMG: estimatedCaffeineMG,
                volumeML: Int(input.waterML.rounded())
            )
        }
        .sheet(isPresented: $isPresentingInfo) {
            calculatorInfoSheet
        }
    }

    private var calculatorHeader: some View {
        HStack {
            calculatorCircleButton(systemImage: "info") {
                isPresentingInfo = true
            }

            Spacer()

            Text("咖啡因计算器")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            Spacer()

            calculatorCircleButton(systemImage: "checkmark") {
                dismiss()
            }
        }
    }

    private var methodHero: some View {
        VStack(spacing: 8) {
            HStack {
                calculatorArrowButton(systemImage: "chevron.left") {
                    shiftMethod(by: -1)
                }

                Spacer()

                CalculatorMethodIllustration(method: input.method)

                Spacer()

                calculatorArrowButton(systemImage: "chevron.right") {
                    shiftMethod(by: 1)
                }
            }

            Text(input.method.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 10) {
                ForEach(CalculatorBrewMethod.allCases) { method in
                    Circle()
                        .fill(method == input.method ? AppTheme.ink : AppTheme.ink.opacity(0.18))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var parameterGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            CalculatorAdjustableCard(
                title: "阿拉比卡",
                value: "\(Int(input.beansGrams.rounded()))g",
                tint: Color(red: 0.54, green: 0.27, blue: 0.11),
                systemImage: "bean.fill",
                onDecrease: { input.beansGrams = max(4, input.beansGrams - 1) },
                onIncrease: { input.beansGrams = min(40, input.beansGrams + 1) }
            )

            CalculatorCyclingCard(
                title: "烘焙",
                value: input.roastLevel.label,
                tint: Color(red: 0.96, green: 0.58, blue: 0.22),
                systemImage: "flame.fill"
            ) {
                cycleRoast()
            }

            CalculatorCyclingCard(
                title: "研磨",
                value: input.grindLevel.label,
                tint: Color(red: 0.38, green: 0.80, blue: 0.73),
                systemImage: "dial.medium"
            ) {
                cycleGrind()
            }

            CalculatorStaticCard(
                title: "参数",
                value: input.method.parameterLine,
                tint: Color(red: 0.79, green: 0.40, blue: 0.95),
                systemImage: "thermometer.medium"
            )

            CalculatorAdjustableCard(
                title: "水量",
                value: "\(Int(input.waterML.rounded())) mL",
                tint: Color(red: 0.34, green: 0.71, blue: 0.91),
                systemImage: "drop.fill",
                onDecrease: { input.waterML = max(20, input.waterML - 10) },
                onIncrease: { input.waterML = min(600, input.waterML + 10) }
            )
        }
    }

    private var resultCard: some View {
        VStack(spacing: 12) {
            Text("估算咖啡因含量")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.20))

                Text("\(estimatedCaffeineMG)")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("mg")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Text("基于本地离线经验模型估算，适合快速比较不同冲煮方式。")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)

            if didCopyValue {
                Text("已复制到剪贴板")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                UIPasteboard.general.string = "\(estimatedCaffeineMG)"
                withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                    didCopyValue = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    await MainActor.run {
                        didCopyValue = false
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                    Text("拷贝咖啡因")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(CalculatorBottomButtonStyle())

            Button {
                isPresentingSaveTemplate = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("创建饮品")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(CalculatorBottomButtonStyle())
        }
        .padding(5)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private var calculatorBackground: some View {
        AppTheme.pageBackground
    }

    private var calculatorInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: "怎么估算", subtitle: "离线经验模型") {
                        Text("这页会根据冲煮方式、咖啡粉、烘焙、研磨和水量，给出一个本地估算值。它适合快速比较不同做法，不是实验室检测值。")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .navigationTitle("说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isPresentingInfo = false
                    }
                }
            }
        }
    }

    private func shiftMethod(by step: Int) {
        let methods = CalculatorBrewMethod.allCases
        guard let currentIndex = methods.firstIndex(of: input.method) else {
            input = .preset(for: .espresso)
            return
        }
        let nextIndex = (currentIndex + step + methods.count) % methods.count
        input = .preset(for: methods[nextIndex])
    }

    private func cycleRoast() {
        let all = RoastLevel.allCases
        guard let index = all.firstIndex(of: input.roastLevel) else {
            input.roastLevel = .medium
            return
        }
        input.roastLevel = all[(index + 1) % all.count]
    }

    private func cycleGrind() {
        let all = GrindLevel.allCases
        guard let index = all.firstIndex(of: input.grindLevel) else {
            input.grindLevel = .standard
            return
        }
        input.grindLevel = all[(index + 1) % all.count]
    }

    @ViewBuilder
    private func calculatorCircleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 54, height: 54)
                .background(AppTheme.elevatedSurface, in: Circle())
                .shadow(color: AppTheme.shadow, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func calculatorArrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(AppTheme.softFill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct CalculatorMethodIllustration: View {
    let method: CalculatorBrewMethod
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(AppTheme.elevatedSurface)
                .frame(width: 188, height: 188)
                .shadow(color: AppTheme.shadow, radius: 20, y: 12)

            switch method {
            case .espresso:
                espressoMachine
            case .pourOver:
                pourOverRig
            case .capsule:
                capsuleRig
            }
        }
    }

    private var espressoMachine: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.30, green: 0.32, blue: 0.35), Color(red: 0.16, green: 0.17, blue: 0.20)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 112, height: 136)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.08), lineWidth: 1)
                )

            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 42, height: 24)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 84, height: 16)

                Circle()
                    .fill(Color.black.opacity(0.42))
                    .frame(width: 26, height: 26)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color.black.opacity(0.44))
                        .frame(width: 34, height: 6)

                    Capsule()
                        .fill(Color.white.opacity(0.72))
                        .frame(width: 16, height: 6)
                }
            }

            Capsule()
                .fill(Color.white.opacity(0.72))
                .frame(width: 6, height: 50)
                .offset(x: 48, y: 14)

            VStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.94))

                Capsule()
                    .fill(Color(red: 0.56, green: 0.38, blue: 0.22))
                    .frame(width: 28, height: 5)
            }
            .offset(y: 34)
        }
    }

    private var pourOverRig: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(AppTheme.ink.opacity(0.18))
                .frame(width: 6, height: 92)
                .offset(x: -42, y: 12)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(AppTheme.ink.opacity(0.18))
                .frame(width: 92, height: 6)
                .offset(x: 4, y: 58)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.78, green: 0.80, blue: 0.83), Color(red: 0.56, green: 0.60, blue: 0.66)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 46)
                .offset(x: -20, y: -42)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 4)
                        .frame(width: 26, height: 26)
                        .offset(x: -34, y: -42)
                )

            Capsule()
                .fill(Color.white.opacity(0.76))
                .frame(width: 18, height: 6)
                .offset(x: -16, y: -58)

            Capsule()
                .fill(Color(red: 0.68, green: 0.72, blue: 0.77))
                .frame(width: 36, height: 6)
                .rotationEffect(.degrees(-24))
                .offset(x: 16, y: -26)

            VStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.38, green: 0.72, blue: 0.96))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(Color(red: 0.38, green: 0.72, blue: 0.96))
                    .frame(width: 5, height: 5)
                Circle()
                    .fill(Color(red: 0.38, green: 0.72, blue: 0.96))
                    .frame(width: 4, height: 4)
            }
            .offset(x: 20, y: -4)

            Triangle()
                .fill(Color.white.opacity(0.96))
                .frame(width: 50, height: 34)
                .overlay(
                    Triangle()
                        .stroke(Color.black.opacity(colorScheme == .dark ? 0.16 : 0.06), lineWidth: 1)
                )
                .offset(x: 8, y: 6)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.92))
                    .frame(width: 62, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.72), lineWidth: 1)
                    )

                Capsule()
                    .fill(Color(red: 0.56, green: 0.38, blue: 0.22))
                    .frame(width: 28, height: 10)
                    .offset(y: -8)
            }
            .offset(x: 8, y: 42)
        }
    }

    private var capsuleRig: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.27, green: 0.29, blue: 0.33), Color(red: 0.15, green: 0.17, blue: 0.19)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 96, height: 118)
                .offset(x: 22, y: -4)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(width: 46, height: 14)
                .offset(x: 22, y: -42)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.82, green: 0.56, blue: 0.24), Color(red: 0.55, green: 0.33, blue: 0.13)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 64, height: 34)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.42), lineWidth: 2)
                )
                .offset(x: -28, y: -6)

            Capsule()
                .fill(Color.white.opacity(0.72))
                .frame(width: 18, height: 6)
                .offset(x: 34, y: 10)

            VStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(red: 0.31, green: 0.31, blue: 0.36))
                Capsule()
                    .fill(Color(red: 0.56, green: 0.38, blue: 0.22))
                    .frame(width: 24, height: 5)
            }
            .offset(x: 18, y: 42)
        }
    }
}

private struct CalculatorAdjustableCard: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 8) {
                calculatorMiniButton(systemImage: "minus", action: onDecrease)
                calculatorMiniButton(systemImage: "plus", action: onIncrease)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private func calculatorMiniButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(AppTheme.softFill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct CalculatorCyclingCard: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(tint)
                    Spacer()
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(tint)
                }

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("点击切换")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CalculatorStaticCard: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct CalculatorBottomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.vertical, 14)
            .background(AppTheme.softFill.opacity(configuration.isPressed ? 1 : 0.88), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SaveCalculatorTemplateSheet: View {
    @Bindable var environment: AppEnvironment

    @Environment(\.dismiss) private var dismiss

    let method: CalculatorBrewMethod
    let estimatedCaffeineMG: Int
    let volumeML: Int

    @State private var brand = "我的器具"
    @State private var name = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: "存成我的饮品", subtitle: "以后可以直接在个人分区复用") {
                        VStack(spacing: 14) {
                            TextField("品牌，例如 家里 / 公司 / 常用器具", text: $brand)
                                .textFieldStyle(.roundedBorder)

                            TextField("饮品名，例如 意式双份", text: $name)
                                .textFieldStyle(.roundedBorder)

                            HStack(spacing: 10) {
                                MetricPill(label: "方式", value: method.title)
                                MetricPill(label: "咖啡因", value: "\(estimatedCaffeineMG)mg")
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("创建饮品")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if name.isEmpty {
                    name = method.title
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        environment.addUserDrinkTemplate(
                            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: "咖啡",
                            caffeineMG: Double(estimatedCaffeineMG),
                            sugarG: 0,
                            volumeML: volumeML,
                            preparationMethod: brewMethod
                        )
                        dismiss()
                    }
                    .disabled(canSave == false)
                }
            }
        }
    }

    private var brewMethod: BrewMethod {
        switch method {
        case .espresso:
            return .espressoMachine
        case .pourOver:
            return .handBrew
        case .capsule:
            return .readyToDrink
        }
    }

    private var canSave: Bool {
        brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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
