import Foundation
import UIKit

struct AppConfig: Sendable {
    let apiBaseURL: URL?
    let previewFallbackEnabled: Bool
    let developmentTokenSeed: String
    let deviceName: String

    static let preview = AppConfig(
        apiBaseURL: nil,
        previewFallbackEnabled: true,
        developmentTokenSeed: "preview-seed",
        deviceName: "Preview iPhone"
    )

    @MainActor
    static var current: AppConfig {
        let bundle = Bundle.main
        let baseURLString = (bundle.object(forInfoDictionaryKey: "YINZHI_API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let previewFallbackEnabled = (bundle.object(forInfoDictionaryKey: "YINZHI_ENABLE_PREVIEW_FALLBACK") as? NSNumber)?
            .boolValue ?? true
        let developmentTokenSeed = (bundle.object(forInfoDictionaryKey: "YINZHI_DEVELOPMENT_TOKEN_SEED") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let deviceName = (bundle.object(forInfoDictionaryKey: "YINZHI_DEVICE_NAME") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackDeviceName = UIDevice.current.name

        return AppConfig(
            apiBaseURL: baseURLString.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            previewFallbackEnabled: previewFallbackEnabled,
            developmentTokenSeed: developmentTokenSeed.flatMap { $0.isEmpty ? nil : $0 } ?? "yinzhi-dev-seed",
            deviceName: deviceName.flatMap { $0.isEmpty ? nil : $0 } ?? fallbackDeviceName
        )
    }

    var hasRemoteAPI: Bool {
        apiBaseURL != nil
    }

    func makeDevelopmentIdentityToken() -> String {
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "\(developmentTokenSeed)-\(nonce)"
    }
}
