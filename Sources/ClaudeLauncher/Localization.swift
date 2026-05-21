import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en_US")
        case .italian:
            return Locale(identifier: "it_IT")
        }
    }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        }
    }
}

struct L10n {
    let language: AppLanguage

    var subtitle: String {
        switch language {
        case .english: return "Choose an API key and project folder, then launch."
        case .italian: return "Scegli API key e cartella, poi lancia."
        }
    }

    var versionLabel: String {
        switch language {
        case .english: return "Version"
        case .italian: return "Versione"
        }
    }

    var terminalLabel: String {
        switch language {
        case .english: return "Terminal:"
        case .italian: return "Terminale:"
        }
    }

    var languageLabel: String {
        switch language {
        case .english: return "Language:"
        case .italian: return "Lingua:"
        }
    }

    var apiKeySectionTitle: String { "API Key" }

    var projectFolderSectionTitle: String {
        switch language {
        case .english: return "Project Folder"
        case .italian: return "Cartella progetto"
        }
    }

    var noSavedAPIKeys: String {
        switch language {
        case .english: return "No saved API keys"
        case .italian: return "Nessuna API key salvata"
        }
    }

    var noSavedFolders: String {
        switch language {
        case .english: return "No saved folders"
        case .italian: return "Nessuna cartella salvata"
        }
    }

    var selectKeyAndFolder: String {
        switch language {
        case .english: return "Select an API key and a folder"
        case .italian: return "Seleziona una key e una cartella"
        }
    }

    var copiedLabel: String {
        switch language {
        case .english: return "Copied!"
        case .italian: return "Copiato!"
        }
    }

    var copyCommandLabel: String {
        switch language {
        case .english: return "Copy cmd"
        case .italian: return "Copia cmd"
        }
    }

    var launchedLabel: String {
        switch language {
        case .english: return "Launched!"
        case .italian: return "Lanciato!"
        }
    }

    var launchClaudeLabel: String {
        switch language {
        case .english: return "Launch Claude"
        case .italian: return "Lancia Claude"
        }
    }

    var selectPrompt: String {
        switch language {
        case .english: return "Select"
        case .italian: return "Seleziona"
        }
    }

    var chooseProjectFolderMessage: String {
        switch language {
        case .english: return "Choose the project folder"
        case .italian: return "Scegli la cartella del progetto"
        }
    }

    var hideKeyHelp: String {
        switch language {
        case .english: return "Hide"
        case .italian: return "Nascondi"
        }
    }

    var showKeyHelp: String {
        switch language {
        case .english: return "Show key"
        case .italian: return "Mostra key"
        }
    }

    var editHelp: String {
        switch language {
        case .english: return "Edit"
        case .italian: return "Modifica"
        }
    }

    var deleteHelp: String {
        switch language {
        case .english: return "Delete"
        case .italian: return "Elimina"
        }
    }

    var addAPIKeyTitle: String {
        switch language {
        case .english: return "Add API Key"
        case .italian: return "Aggiungi API Key"
        }
    }

    var editAPIKeyTitle: String {
        switch language {
        case .english: return "Edit API Key"
        case .italian: return "Modifica API Key"
        }
    }

    var addFolderTitle: String {
        switch language {
        case .english: return "Add Folder"
        case .italian: return "Aggiungi cartella"
        }
    }

    var nameLabel: String {
        switch language {
        case .english: return "Name"
        case .italian: return "Nome"
        }
    }

    var personalAnthropicPlaceholder: String {
        switch language {
        case .english: return "e.g. Personal Anthropic"
        case .italian: return "es. Anthropic Personale"
        }
    }

    var apiKeyLabel: String { "API Key" }
    var apiKeyPlaceholder: String { "sk-ant-..." }

    var cancelButton: String {
        switch language {
        case .english: return "Cancel"
        case .italian: return "Annulla"
        }
    }

    var saveButton: String {
        switch language {
        case .english: return "Save"
        case .italian: return "Salva"
        }
    }

    var pathLabel: String {
        switch language {
        case .english: return "Path"
        case .italian: return "Percorso"
        }
    }

    var browseButton: String {
        switch language {
        case .english: return "Browse"
        case .italian: return "Sfoglia"
        }
    }
}
