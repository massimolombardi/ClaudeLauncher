import SwiftUI

struct ContentView: View {
    @StateObject private var store = Store()
    @State private var selectedKey: APIKey?
    @State private var selectedFolder: ProjectFolder?
    @State private var showAddKey = false
    @State private var showAddFolder = false
    @State private var editingKey: APIKey? = nil
    @State private var launched = false
    @State private var copied = false

    var canLaunch: Bool { selectedKey != nil && selectedFolder != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Claude Launcher")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Scegli API key e cartella, poi lancia.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Versione \(AppInfo.version)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
                // Terminal default picker inline in header
                HStack(spacing: 6) {
                    Text("Terminale:")
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // API Keys
                    SectionCard(
                        title: "API Key",
                        icon: "key.fill",
                        onAdd: { showAddKey = true }
                    ) {
                        if store.apiKeys.isEmpty {
                            EmptyRow(text: "Nessuna API key salvata")
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

                    // Folders
                    SectionCard(
                        title: "Cartella progetto",
                        icon: "folder.fill",
                        onAdd: { pickFolder() }
                    ) {
                        if store.folders.isEmpty {
                            EmptyRow(text: "Nessuna cartella salvata")
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

            // Launch bar
            HStack(spacing: 10) {
                // Summary
                VStack(alignment: .leading, spacing: 2) {
                    if let k = selectedKey, let f = selectedFolder {
                        Text("\(k.name)  →  \(f.displayPath)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("Seleziona una key e una cartella")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondary.opacity(0.6))
                    }
                }
                Spacer()

                // Copy button
                Button {
                    guard let k = selectedKey, let f = selectedFolder else { return }
                    Launcher.copyCommand(folder: f, apiKey: k)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Copiato!" : "Copia cmd", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .disabled(!canLaunch)
                .tint(copied ? .green : .secondary)

                // Launch button
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
                    Label(launched ? "Lanciato!" : "Lancia Claude", systemImage: launched ? "checkmark.circle.fill" : "play.fill")
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
            // Auto-select first items if none selected
            if selectedKey == nil { selectedKey = store.apiKeys.first }
            if selectedFolder == nil { selectedFolder = store.folders.first }
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Seleziona"
        panel.message = "Scegli la cartella del progetto"
        if panel.runModal() == .OK, let url = panel.url {
            let name = url.lastPathComponent
            var folder = ProjectFolder(name: name, path: url.path)
            store.addFolder(folder)
            selectedFolder = store.folders.last(where: { $0.path == url.path })
        }
    }
}

// MARK: - Section card

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

// MARK: - Key row

struct KeyRow: View {
    let key: APIKey
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovered = false
    @State private var showValue = false

    var maskedValue: String {
        let v = key.value
        guard v.count > 8 else { return String(repeating: "•", count: v.count) }
        return v.prefix(7) + "..." + v.suffix(4)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Selection indicator
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
                .help(showValue ? "Nascondi" : "Mostra key")

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Modifica")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .help("Elimina")
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

// MARK: - Folder row

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

// MARK: - Empty state

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

// MARK: - Add key sheet

struct AddKeySheet: View {
    let onSave: (APIKey) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var value = ""
    @State private var showValue = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Aggiungi API Key")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Nome").font(.system(size: 12)).foregroundColor(.secondary)
                TextField("es. Anthropic Personale", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("API Key").font(.system(size: 12)).foregroundColor(.secondary)
                HStack {
                    if showValue {
                        TextField("sk-ant-...", text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    } else {
                        SecureField("sk-ant-...", text: $value)
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
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Salva") {
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

// MARK: - Edit key sheet

struct EditKeySheet: View {
    let key: APIKey
    let onSave: (APIKey) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var value: String
    @State private var showValue = false

    init(key: APIKey, onSave: @escaping (APIKey) -> Void) {
        self.key = key
        self.onSave = onSave
        _name = State(initialValue: key.name)
        _value = State(initialValue: key.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Modifica API Key")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Nome").font(.system(size: 12)).foregroundColor(.secondary)
                TextField("es. Anthropic Personale", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("API Key").font(.system(size: 12)).foregroundColor(.secondary)
                HStack {
                    if showValue {
                        TextField("sk-ant-...", text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    } else {
                        SecureField("sk-ant-...", text: $value)
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
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Salva") {
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
    let onSave: (ProjectFolder) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var path = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Aggiungi cartella")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Nome").font(.system(size: 12)).foregroundColor(.secondary)
                TextField("es. MyProject", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Percorso").font(.system(size: 12)).foregroundColor(.secondary)
                HStack {
                    TextField("~/Developer/myproject", text: $path)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    Button("Sfoglia") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.prompt = "Seleziona"
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
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Salva") {
                    let expandedPath = (path as NSString).expandingTildeInPath
                    let folder = ProjectFolder(name: name.isEmpty ? URL(fileURLWithPath: expandedPath).lastPathComponent : name, path: expandedPath)
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
