import Foundation

actor SessionStore {
    private let defaults: UserDefaults
    private let sessionKey: String

    init(
        defaults: UserDefaults = .standard,
        sessionKey: String = "com.luca.yinzhi.session"
    ) {
        self.defaults = defaults
        self.sessionKey = sessionKey
    }

    func loadSession() -> AppSession? {
        guard let data = defaults.data(forKey: sessionKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(AppSession.self, from: data)
    }

    func saveSession(_ session: AppSession?) {
        guard let session else {
            defaults.removeObject(forKey: sessionKey)
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(session) {
            defaults.set(data, forKey: sessionKey)
        }
    }
}
