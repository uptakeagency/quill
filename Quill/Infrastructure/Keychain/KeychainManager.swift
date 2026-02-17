import KeychainAccess

final class KeychainManager {
    static let shared = KeychainManager()

    private let keychain = Keychain(service: "com.c3nx.quill")
    private let apiKeyKey = "claude-api-key"
    private let geminiKeyKey = "gemini-api-key"

    func getAPIKey() -> String? {
        try? keychain.get(apiKeyKey)
    }

    func saveAPIKey(_ key: String) {
        try? keychain.set(key, key: apiKeyKey)
        Log.general.info("API key saved to Keychain")
    }

    func deleteAPIKey() {
        try? keychain.remove(apiKeyKey)
        Log.general.info("API key removed from Keychain")
    }

    func getGeminiKey() -> String? {
        try? keychain.get(geminiKeyKey)
    }

    func saveGeminiKey(_ key: String) {
        try? keychain.set(key, key: geminiKeyKey)
        Log.general.info("Gemini key saved to Keychain")
    }

    func deleteGeminiKey() {
        try? keychain.remove(geminiKeyKey)
        Log.general.info("Gemini key removed from Keychain")
    }
}
