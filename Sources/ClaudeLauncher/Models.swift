import Foundation

// MARK: - APIKey
// `value` is intentionally excluded from Codable — it lives in the Keychain only.
// UserDefaults stores only id, name, createdAt (non-sensitive metadata).

struct APIKey: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var value: String   // loaded from Keychain at runtime, never persisted to disk
    var createdAt: Date = Date()
}

// Codable conformance for metadata only
extension APIKey: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        name      = try c.decode(String.self, forKey: .name)
        createdAt = try c.decode(Date.self,   forKey: .createdAt)
        value     = KeychainStore.load(id: id) ?? ""   // pull secret from Keychain
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(name,      forKey: .name)
        try c.encode(createdAt, forKey: .createdAt)
        // value is NOT encoded — Keychain is the only storage
    }
}

// MARK: - ProjectFolder

struct ProjectFolder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var path: String
    var lastUsed: Date?

    var displayPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }

    var exists: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}

// MARK: - Store

class Store: ObservableObject {
    @Published var apiKeys: [APIKey] = []
    @Published var folders: [ProjectFolder] = []
    @Published var defaultTerminal: TerminalApp = .terminal

    private let keysKey     = "claude_api_keys_meta"   // renamed to force clean reload
    private let foldersKey  = "claude_folders"
    private let terminalKey = "claude_default_terminal"

    init() {
        load()
    }

    func load() {
        // API keys: metadata from UserDefaults, values from Keychain (via APIKey.init(from:))
        if let data = UserDefaults.standard.data(forKey: keysKey),
           let decoded = try? JSONDecoder().decode([APIKey].self, from: data) {
            apiKeys = decoded
        } else {
            // Migration: old key "claude_api_keys" stored value in plaintext — move to Keychain
            migrateOldKeys()
        }

        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([ProjectFolder].self, from: data) {
            folders = decoded
        }

        if let saved = UserDefaults.standard.string(forKey: terminalKey),
           let t = TerminalApp(rawValue: saved) {
            defaultTerminal = t
        } else {
            for t in [TerminalApp.iTerm, .warp, .ghostty, .terminal] {
                if t.isInstalled { defaultTerminal = t; break }
            }
        }
    }

    // Migrate from old plaintext UserDefaults storage
    private func migrateOldKeys() {
        struct OldKey: Codable { var id: UUID; var name: String; var value: String; var createdAt: Date }
        guard let data = UserDefaults.standard.data(forKey: "claude_api_keys"),
              let old = try? JSONDecoder().decode([OldKey].self, from: data)
        else { return }

        for o in old {
            KeychainStore.migrateIfNeeded(id: o.id, plaintextValue: o.value)
            let key = APIKey(id: o.id, name: o.name, value: o.value, createdAt: o.createdAt)
            apiKeys.append(key)
        }
        saveMetadata()
        // Remove old plaintext entry
        UserDefaults.standard.removeObject(forKey: "claude_api_keys")
    }

    private func saveMetadata() {
        if let encoded = try? JSONEncoder().encode(apiKeys) {
            UserDefaults.standard.set(encoded, forKey: keysKey)
        }
    }

    func save() {
        saveMetadata()
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: foldersKey)
        }
        UserDefaults.standard.set(defaultTerminal.rawValue, forKey: terminalKey)
    }

    func addKey(_ key: APIKey) {
        KeychainStore.save(id: key.id, value: key.value)
        apiKeys.append(key)
        saveMetadata()
    }

    func updateKey(_ key: APIKey) {
        if let i = apiKeys.firstIndex(where: { $0.id == key.id }) {
            KeychainStore.save(id: key.id, value: key.value)
            apiKeys[i] = key
            saveMetadata()
        }
    }

    func deleteKey(_ key: APIKey) {
        KeychainStore.delete(id: key.id)
        apiKeys.removeAll { $0.id == key.id }
        saveMetadata()
    }

    func addFolder(_ folder: ProjectFolder) {
        guard !folders.contains(where: { $0.path == folder.path }) else { return }
        folders.append(folder)
        save()
    }

    func deleteFolder(_ folder: ProjectFolder) {
        folders.removeAll { $0.id == folder.id }
        save()
    }

    func markUsed(_ folder: inout ProjectFolder) {
        if let i = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[i].lastUsed = Date()
            folder = folders[i]
            save()
        }
    }

    func saveDefaultTerminal(_ t: TerminalApp) {
        defaultTerminal = t
        save()
    }
}
