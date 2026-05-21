import SwiftUI

struct ContentView: View {
    @AppStorage("app_language") private var appLanguageRaw = AppLanguage.english.rawValue
    @StateObject private var store = Store()
    @State private var selectedKey: APIKey?
    @State private var selectedFolder: ProjectFolder?
    @State private var showAddKey = false
    @State private var showAddFolder = false
    @State private var editingKey: APIKey? = nil
    @State private var launched = false
    @State private var copied = false

    var canLaunch: Bool { selectedKey != nil && selectedFolder != nil }
    var language: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }
    var l10n: L10n { L10n(language: language) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Claude Launcher")
                        .font(.system(size: 14, weight: .semibold))
                    Text(l10n.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(l10n.versionLabel) \(AppInfo.version)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(l10n.languageLabel)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Picker("", selection: $appLanguageRaw) {
                            ForEach(AppLanguage.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 110)
                        .labelsHidden()
                    }

                    HStack(spacing: 6) {
                        Text(l10n.terminalLabel)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Picker("", selection: Binding(
                            get: { store.defaultTerminal },
                            set: { store.saveDefaultTerminal($0) }
                        )) {
                            ForEach(TerminalApp.allCases.filter { $0.isInstalled }, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 110)
                        .labelsHidden()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    SectionCard(
                        title: l10n.apiKeySectionTitle,
                        icon: "key.fill",
                        onAdd: { showAddKey = true }
                    ) {
                        if store.apiKeys.isEmpty {
                            EmptyRow(text: l10n.noSavedAPIKeys)
                        } else {
                            ForEach(store.apiKeys) { key in
                                KeyRow(
                                    key: key,
                                    isSelected: selectedKey?.id == key.id,
                                    onSelect: { selectedKey = key },
                                    onEdit: { editingKey = key },
                                    onDelete: {
                                        store.deleteKey(key)
                                        if selectedKey?.id == key.id { selectedKey = nil }
                                    }
                                )
                            }
                        }
                    }

                    SectionCard(
                        title: l10n.projectFolderSectionTitle,
                        icon: "folder.fill",
                        onAdd: { pickFolder() }
                    ) {
                        if store.folders.isEmpty {
                            EmptyRow(text: l10n.noSavedFolders)
                        } else {
                            ForEach(store.folders) { folder in
                                FolderRow(
                                    folder: folder,
                                    isSelected: selectedFolder?.id == folder.id,
                                    onSelect: { selectedFolder = folder },
                                    onDelete: {
                                        store.deleteFolder(folder)
                                        if selectedFolder?.id == folder.id { selectedFolder = nil }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    if let k = selectedKey, let f = selectedFolder {
                        Text("\(k.name)  →  \(f.displayPath)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text(l10n.selectKeyAndFolder)
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondary.opacity(0.6))
                    }
                }

                Spacer()

                Button {
                    guard let k = selectedKey, let f = selectedFolder else { return }
                    Launcher.copyCommand(folder: f, apiKey: k)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? l10n.copiedLabel : l10n.copyCommandLabel, systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .disabled(!canLaunch)
                .tint(copied ? .green : .secondary)

                Button {
                    guard let k = selectedKey, var f = selectedFolder else { return }
                    store.markUsed(&f)
                    selectedFolder = f
                    Launcher.launch(folder: f, apiKey: k, terminal: store.defaultTerminal)
                    withAnimation { launched = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { launched = false }
                    }
                } label: {
                    Label(launched ? l10n.launchedLabel : l10n.launchClaudeLabel, systemImage: launched ? "checkmark.circle.fill" : "play.fill")
                        .font(.system(size: 13, weight: .medium))
                        .frame(minWidth: 130)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canLaunch)
                .tint(launched ? .green : .accentColor)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .environment(\.locale, language.locale)
        .sheet(isPresented: $showAddKey) {
            AddKeySheet { key in
                store.addKey(key)
                selectedKey = key
                showAddKey = false
            }
        }
        .sheet(item: $editingKey) { key in
            EditKeySheet(key: key) { updated in
                store.updateKey(updated)
                if selectedKey?.id == updated.id { selectedKey = updated }
                editingKey = nil
            }
        }
        .sheet(isPresented: $showAddFolder) {
            AddFolderSheet { folder in
                store.addFolder(folder)
                selectedFolder = folder
                showAddFolder = false
            }
        }
        .onAppear {
            if selectedKey == nil { selectedKey = store.apiKeys.first }
            if selectedFolder == nil { selectedFolder = store.folders.first }
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = l10n.selectPrompt
        panel.message = l10n.chooseProjectFolderMessage
        if panel.runModal() == .OK, let url = panel.url {
            let name = url.lastPathComponent
            let folder = ProjectFolder(name: name, path: url.path)
            store.addFolder(folder)
            selectedFolder = store.folders.last(where: { $0.path == url.path })
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let onAdd: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            VStack(spacing: 0) {
                content
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }
}

struct KeyRow: View {
    @AppStorage("app_language") private var appLanguageRaw = AppLanguage.english.rawValue
    let key: APIKey
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovered = false
    @State private var showValue = false

    var language: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }
    var l10n: L10n { L10n(language: language) }

    var maskedValue: String {
        let v = key.value
        guard v.count > 8 else { return String(repeating: "•", count: v.count) }
        return v.prefix(7) + "..." + v.suffix(4)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(key.name)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                Text(showValue ? key.value : maskedValue)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if hovered || isSelected {
                Button(action: { showValue.toggle() }) {
                    Image(systemName: showValue ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help(showValue ? l10n.hideKeyHelp : l10n.showKeyHelp)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help(l10n.editHelp)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .help(l10n.deleteHelp)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isSelected ? Color.accentColor.opacity(0.07) : (hovered ? Color.primary.opacity(0.03) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovered = $0 }
    }
}

struct FolderRow: View {
    let folder: ProjectFolder
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1))

            Image(systemName: folder.exists ? "folder.fill" : "folder.badge.questionmark")
                .font(.system(size: 13))
                .foregroundColor(folder.exists ? .accentColor.opacity(0.8) : .orange)

            VStack(alignment: .leading, spacing: 1) {
                Text(folder.name)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                Text(folder.displayPath)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let lastUsed = folder.lastUsed, (hovered || isSelected) {
                Text(lastUsed.formatted(.relative(presentation: .named)))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            if hovered || isSelected {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isSelected ? Color.accentColor.opacity(0.07) : (hovered ? Color.primary.opacity(0.03) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovered = $0 }
    }
}

struct EmptyRow: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color.secondary.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
    }
}

struct AddKeySheet: View {
    @AppStorage("app_language") private var appLanguageRaw = AppLanguage.english.rawValue
    let onSave: (APIKey) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var value = ""
    @State private var showValue = false

    var language: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }
    var l10n: L10n { L10n(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(l10n.addAPIKeyTitle)
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.nameLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField(l10n.personalAnthropicPlaceholder, text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.apiKeyLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                HStack {
                    if showValue {
                        TextField(l10n.apiKeyPlaceholder, text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    } else {
                        SecureField(l10n.apiKeyPlaceholder, text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Button(action: { showValue.toggle() }) {
                        Image(systemName: showValue ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                Spacer()
                Button(l10n.cancelButton) { dismiss() }
                    .keyboardShortcut(.escape)
                Button(l10n.saveButton) {
                    let key = APIKey(name: name.isEmpty ? "Key \(Int.random(in: 100...999))" : name, value: value)
                    onSave(key)
                }
                .buttonStyle(.borderedProminent)
                .disabled(value.count < 10)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}

struct EditKeySheet: View {
    @AppStorage("app_language") private var appLanguageRaw = AppLanguage.english.rawValue
    let key: APIKey
    let onSave: (APIKey) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var value: String
    @State private var showValue = false

    var language: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }
    var l10n: L10n { L10n(language: language) }

    init(key: APIKey, onSave: @escaping (APIKey) -> Void) {
        self.key = key
        self.onSave = onSave
        _name = State(initialValue: key.name)
        _value = State(initialValue: key.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(l10n.editAPIKeyTitle)
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.nameLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField(l10n.personalAnthropicPlaceholder, text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.apiKeyLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                HStack {
                    if showValue {
                        TextField(l10n.apiKeyPlaceholder, text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    } else {
                        SecureField(l10n.apiKeyPlaceholder, text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Button(action: { showValue.toggle() }) {
                        Image(systemName: showValue ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                Spacer()
                Button(l10n.cancelButton) { dismiss() }
                    .keyboardShortcut(.escape)
                Button(l10n.saveButton) {
                    var updated = key
                    updated.name = name.isEmpty ? key.name : name
                    updated.value = value
                    onSave(updated)
                }
                .buttonStyle(.borderedProminent)
                .disabled(value.count < 10)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}

struct AddFolderSheet: View {
    @AppStorage("app_language") private var appLanguageRaw = AppLanguage.english.rawValue
    let onSave: (ProjectFolder) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var path = ""

    var language: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .english }
    var l10n: L10n { L10n(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(l10n.addFolderTitle)
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.nameLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField("e.g. MyProject", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.pathLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                HStack {
                    TextField("~/Developer/myproject", text: $path)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    Button(l10n.browseButton) {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.prompt = l10n.selectPrompt
                        if panel.runModal() == .OK, let url = panel.url {
                            path = url.path
                            if name.isEmpty { name = url.lastPathComponent }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack {
                Spacer()
                Button(l10n.cancelButton) { dismiss() }
                    .keyboardShortcut(.escape)
                Button(l10n.saveButton) {
                    let expandedPath = (path as NSString).expandingTildeInPath
                    let folder = ProjectFolder(
                        name: name.isEmpty ? URL(fileURLWithPath: expandedPath).lastPathComponent : name,
                        path: expandedPath
                    )
                    onSave(folder)
                }
                .buttonStyle(.borderedProminent)
                .disabled(path.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
