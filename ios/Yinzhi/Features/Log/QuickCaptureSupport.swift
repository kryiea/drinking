import AVFoundation
import PhotosUI
import Speech
import SwiftUI
import UIKit
@preconcurrency import Vision

enum QuickCaptureSource: String, Identifiable, Sendable {
    case camera
    case library
    case voice

    var id: String { rawValue }

    var label: String {
        switch self {
        case .camera:
            return "拍照识别"
        case .library:
            return "相册识别"
        case .voice:
            return "语音输入"
        }
    }

    var systemImage: String {
        switch self {
        case .camera:
            return "camera.viewfinder"
        case .library:
            return "photo.on.rectangle.angled"
        case .voice:
            return "waveform.circle.fill"
        }
    }
}

struct QuickCaptureMatch: Identifiable, Hashable, Sendable {
    let drink: DrinkDefinitionSummary
    let score: Double
    let matchedTerms: [String]

    var id: String { drink.id }

    var confidenceLabel: String {
        switch score {
        case 10...:
            return "高匹配"
        case 7...:
            return "可直记"
        default:
            return "建议确认"
        }
    }

    var confidenceTint: Color {
        switch score {
        case 10...:
            return AppTheme.accent
        case 7...:
            return Color(red: 0.20, green: 0.47, blue: 0.74)
        default:
            return Color(red: 0.90, green: 0.53, blue: 0.18)
        }
    }
}

struct QuickCaptureRecognitionResult: Identifiable, Hashable, Sendable {
    let id: String
    let source: QuickCaptureSource
    let recognizedText: String
    let matches: [QuickCaptureMatch]
    let suggestedQuery: String

    var title: String {
        matches.isEmpty ? "先帮你缩小搜索范围" : "识别到这些候选饮品"
    }

    var subtitle: String {
        if source == .voice {
            if let first = matches.first {
                return "从语音里先猜到 \(first.drink.brand) · \(first.drink.name)，确认一下就能记。"
            }
            return "我先把语音里提到的关键词留给你继续搜索。"
        }
        if let first = matches.first {
            return "优先猜到 \(first.drink.brand) · \(first.drink.name)，点一下就能直接记。"
        }
        return "这张图里的文字还不够明确，我先把关键词留给你继续搜索。"
    }

    var previewText: String {
        recognizedText
            .replacingOccurrences(of: "\n", with: " · ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum QuickCaptureRecognizerError: LocalizedError {
    case unreadableImage
    case noRecognizedText

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "暂时没法读取这张图片，请换一张更清晰的包装或菜单。"
        case .noRecognizedText:
            return "没有识别到清晰文字，试试对准品牌名、品类名或杯贴。"
        }
    }
}

enum QuickCaptureRecognizer {
    static func recognize(
        imageData: Data,
        source: QuickCaptureSource,
        catalog: [DrinkDefinitionSummary]
    ) async throws -> QuickCaptureRecognitionResult {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw QuickCaptureRecognizerError.unreadableImage
        }

        let recognizedText = try await recognizeText(in: cgImage)
        return buildResult(recognizedText: recognizedText, source: source, catalog: catalog)
    }

    static func buildResult(
        recognizedText: String,
        source: QuickCaptureSource,
        catalog: [DrinkDefinitionSummary]
    ) -> QuickCaptureRecognitionResult {
        let trimmedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let compactText = normalized(trimmedText)
        let searchTokens = queryTokens(from: trimmedText)

        let rankedMatches: [QuickCaptureMatch] = catalog
            .compactMap { drink in
                let match = score(drink: drink, compactText: compactText)
                guard match.score > 1.8 else {
                    return nil
                }
                return QuickCaptureMatch(
                    drink: drink,
                    score: match.score,
                    matchedTerms: Array(match.terms.prefix(3))
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.drink.name < rhs.drink.name
                }
                return lhs.score > rhs.score
            }

        return QuickCaptureRecognitionResult(
            id: UUID().uuidString,
            source: source,
            recognizedText: trimmedText,
            matches: Array(rankedMatches.prefix(3)),
            suggestedQuery: searchTokens.prefix(3).joined(separator: " ")
        )
    }

    private static func recognizeText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard text.isEmpty == false else {
                    continuation.resume(throwing: QuickCaptureRecognizerError.noRecognizedText)
                    return
                }

                continuation.resume(returning: text)
            }

            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let handler = VNImageRequestHandler(cgImage: cgImage)
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func score(
        drink: DrinkDefinitionSummary,
        compactText: String
    ) -> (score: Double, terms: [String]) {
        var score = 0.0
        var terms: [String] = []

        func add(_ term: String?, weight: Double) {
            guard let term else {
                return
            }

            let normalizedTerm = normalized(term)
            guard normalizedTerm.isEmpty == false else {
                return
            }

            if compactText.contains(normalizedTerm) {
                score += weight
                terms.append(term)
            }
        }

        add(drink.brand, weight: 5.2)
        add(drink.name, weight: 6.4)
        add(drink.category, weight: 2.1)
        add(drink.brandCollection, weight: 1.6)
        add(drink.heroFlavor, weight: 1.4)

        for tag in drink.tags {
            add(tag, weight: 1.2)
        }

        for method in drink.preparationMethods ?? [] {
            for keyword in methodKeywords(for: method) {
                add(keyword, weight: 1.8)
            }
        }

        if compactText.contains("无糖"), drink.metrics.sugarG <= 5 {
            score += 1.0
            terms.append("无糖")
        }

        if compactText.contains("0糖"), drink.metrics.sugarG <= 5 {
            score += 1.0
            terms.append("0糖")
        }

        if compactText.contains("latte"), normalized(drink.name).contains("拿铁") {
            score += 1.1
            terms.append("latte")
        }

        if compactText.contains("v60"), (drink.preparationMethods ?? []).contains(.handBrew) {
            score += 1.4
            terms.append("V60")
        }

        return (score, terms)
    }

    private static func queryTokens(from text: String) -> [String] {
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
            .union(.symbols)

        let raw = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }

        var deduped: [String] = []
        for item in raw {
            if deduped.contains(item) == false {
                deduped.append(item)
            }
        }

        if deduped.isEmpty {
            return [text]
        }

        return deduped
    }

    private static func normalized(_ string: String) -> String {
        string
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "zh_Hans"))
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private static func methodKeywords(for method: BrewMethod) -> [String] {
        switch method {
        case .handBrew:
            return ["手冲", "V60", "pour over", "pour-over"]
        case .espressoMachine:
            return ["拿铁", "浓缩", "espresso", "意式"]
        case .milkTea:
            return ["奶茶", "鲜奶茶", "light milk tea"]
        case .sparkling:
            return ["气泡", "sparkling"]
        case .readyToDrink:
            return ["即饮", "bottle", "can"]
        }
    }
}

struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}

struct QuickActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .adaptiveGlassCard(tint: tint.opacity(0.10), cornerRadius: 24, interactive: true, padding: 16)
    }
}

struct QuickCaptureResultSheet: View {
    let result: QuickCaptureRecognitionResult
    var isRecording: Bool
    let onRecord: (DrinkDefinitionSummary) -> Void
    let onUseSuggestedQuery: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: result.title, subtitle: result.subtitle) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(result.source.label, systemImage: result.source.systemImage)
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.accent)

                            Text(result.previewText)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(4)
                        }
                    }

                    if result.matches.isEmpty {
                        SectionCard(title: "继续搜", subtitle: "识别先帮你把关键词提出来") {
                            Button {
                                onUseSuggestedQuery(result.suggestedQuery)
                                dismiss()
                            } label: {
                                Label("用“\(result.suggestedQuery)”继续搜索", systemImage: "magnifyingglass")
                            }
                            .buttonStyle(PrimaryCTAStyle())
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(result.matches) { match in
                                QuickCaptureMatchCard(
                                    match: match,
                                    isRecording: isRecording
                                ) {
                                    onRecord(match.drink)
                                    dismiss()
                                }
                            }
                        }

                        if result.suggestedQuery.isEmpty == false {
                            Button {
                                onUseSuggestedQuery(result.suggestedQuery)
                                dismiss()
                            } label: {
                                Label("还是走搜索补充", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(SecondaryGlassButtonStyle())
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("快速识别")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VoiceCaptureSheet: View {
    let catalog: [DrinkDefinitionSummary]
    let onRecognized: (QuickCaptureRecognitionResult) -> Void
    let onUseSuggestedQuery: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceCaptureRecorder()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: "语音输入", subtitle: "一句话说出品牌和饮品") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                StatusChip(
                                    label: recorder.statusLabel,
                                    systemImage: recorder.isListening ? "waveform.circle.fill" : "mic.circle",
                                    tint: recorder.statusTint.opacity(0.18)
                                )
                                Spacer()
                            }

                            TextField("例如：瑞幸冰美式大杯，下午三点", text: $recorder.transcript, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3 ... 6)

                            Text("支持结构化短句，例如“霸王茶姬伯牙绝弦半糖”或“MANNER 燕麦拿铁一杯”。")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let errorMessage = recorder.errorMessage {
                        Text(errorMessage)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await recorder.toggle()
                            }
                        } label: {
                            Label(recorder.isListening ? "停止录音" : "开始录音", systemImage: recorder.isListening ? "stop.circle.fill" : "mic.fill")
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        Button {
                            useTranscript()
                        } label: {
                            Label("用这句继续匹配", systemImage: "arrow.right.circle")
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                        .disabled(recorder.trimmedTranscript.isEmpty)

                        if recorder.trimmedTranscript.isEmpty == false {
                            Button {
                                onUseSuggestedQuery(recorder.trimmedTranscript)
                                dismiss()
                            } label: {
                                Label("直接带去搜索", systemImage: "magnifyingglass")
                            }
                            .buttonStyle(.plain)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("语音记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        recorder.stop()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            recorder.stop()
        }
    }

    private func useTranscript() {
        let result = QuickCaptureRecognizer.buildResult(
            recognizedText: recorder.trimmedTranscript,
            source: .voice,
            catalog: catalog
        )
        onRecognized(result)
        recorder.stop()
        dismiss()
    }
}

@MainActor
final class VoiceCaptureRecorder: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
        ?? SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var trimmedTranscript: String {
        transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var statusLabel: String {
        if isListening {
            return "正在听"
        }
        if trimmedTranscript.isEmpty == false {
            return "已转写"
        }
        return "待开始"
    }

    var statusTint: Color {
        if isListening {
            return AppTheme.accent
        }
        if errorMessage == nil {
            return Color(red: 0.20, green: 0.47, blue: 0.74)
        }
        return Color.orange
    }

    func toggle() async {
        if isListening {
            stop()
        } else {
            await start()
        }
    }

    func stop() {
        isListening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func start() async {
        errorMessage = nil

        let speechGranted = await requestSpeechAuthorization()
        guard speechGranted else {
            errorMessage = "没有语音识别权限，请在系统设置里允许“语音识别”。"
            return
        }

        let recordGranted = await requestRecordPermission()
        guard recordGranted else {
            errorMessage = "没有麦克风权限，请在系统设置里允许麦克风后再试。"
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "当前设备暂时无法启动语音识别，请稍后再试。"
            return
        }

        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionRequest = request
            isListening = true

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else {
                    return
                }

                Task { @MainActor in
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.stop()
                        }
                    }

                    if let error {
                        self.errorMessage = "语音识别失败：\(error.localizedDescription)"
                        self.stop()
                    }
                }
            }
        } catch {
            errorMessage = "语音识别启动失败：\(error.localizedDescription)"
            stop()
        }
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestRecordPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

private struct QuickCaptureMatchCard: View {
    let match: QuickCaptureMatch
    var isRecording: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(match.drink.brand)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(match.confidenceTint)
                    Text(match.drink.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(match.drink.heroFlavor ?? "\(match.drink.category) · \(match.drink.brandCollection ?? "品牌目录")")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(match.confidenceLabel)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(match.confidenceTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(match.confidenceTint.opacity(0.12), in: Capsule())
            }

            if match.matchedTerms.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(match.matchedTerms, id: \.self) { term in
                            Text(term)
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.72), in: Capsule())
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                compactMetric("因 \(Int(match.drink.metrics.caffeineMG))mg")
                compactMetric("糖 \(Int(match.drink.metrics.sugarG))g")
                compactMetric("量 \(match.drink.preferredServing.volumeML)ml")
            }

            Button(action: action) {
                Label(isRecording ? "加入中" : "记这杯", systemImage: isRecording ? "hourglass" : "plus.circle.fill")
            }
            .buttonStyle(PrimaryCTAStyle())
            .disabled(isRecording)
        }
        .adaptiveGlassCard(cornerRadius: 30, interactive: true)
        .opacity(isRecording ? 0.82 : 1)
    }

    private func compactMetric(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.68), in: Capsule())
    }
}
