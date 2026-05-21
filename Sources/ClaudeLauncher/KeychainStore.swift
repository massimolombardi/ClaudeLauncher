import Foundation
import Security

/// Manages API key *values* in the macOS Keychain.
/// Metadata (name, id, date) stays in UserDefaults; only the secret goes here.
enum KeychainStore {

    private static let service = "com.local.claudelauncher"

    // MARK: - Public API

    static func save(id: UUID, value: String) {
        let data = Data(value.utf8)
        let account = id.uuidString

        if exists(id: id) {
            // Update existing item
            let query = baseQuery(account: account)
            let attributes: [CFString: Any] = [
                kSecValueData: data
            ]
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            // Add new item
            var item = baseQuery(account: account)
            item[kSecValueData] = data
            item[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlocked
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    static func load(id: UUID) -> String? {
        var query = baseQuery(account: id.uuidString)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    static func delete(id: UUID) {
        let query = baseQuery(account: id.uuidString)
        SecItemDelete(query as CFDictionary)
    }

    /// Migrates a plaintext value from UserDefaults into the Keychain.
    /// Overwrites only if the Keychain entry is missing.
    static func migrateIfNeeded(id: UUID, plaintextValue: String) {
        guard !exists(id: id) else { return }
        save(id: id, value: plaintextValue)
    }

    // MARK: - Private

    private static func exists(id: UUID) -> Bool {
        let query = baseQuery(account: id.uuidString)
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    private static func baseQuery(account: String) -> [CFString: Any] {
        [
            kSecClass:   kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }
}
