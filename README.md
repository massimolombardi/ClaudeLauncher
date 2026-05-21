# Claude Launcher

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Platform: macOS](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

App nativa macOS per lanciare [Claude Code](https://github.com/anthropics/claude-code) con la giusta API key e cartella progetto — senza dover fare `export ANTHROPIC_API_KEY=...` ogni volta.

## Funzionalità

- Salva più API key con nome personalizzato, cifrate nel Keychain di macOS
- Salva le cartelle progetto preferite
- Lancia Claude Code in un click con key e cartella selezionate
- Supporta Terminal, iTerm2, Warp, Ghostty
- Terminale di default persistente tra sessioni
- Pulsante "Copia comando" come fallback

## Sicurezza

Le API key non vengono mai scritte su disco in chiaro. L'app usa due livelli di storage:

| Dato | Dove | Cifrato |
|------|------|---------|
| Valore della API key | macOS Keychain | ✅ sì, cifrato dall'OS |
| Nome, id, data | UserDefaults | — (non sensibile) |
| Cartelle progetto | UserDefaults | — (non sensibile) |

Il Keychain di macOS cifra i segreti a livello di sistema operativo e li rende accessibili solo quando il Mac è sbloccato. Nessun file con segreti viene mai creato nella cartella del progetto, quindi fare `git push` è sicuro senza nessuna precauzione aggiuntiva.

Puoi verificare aprendo **Keychain Access.app** e cercando `com.local.claudelauncher`.

**Migrazione automatica:** se hai usato una versione precedente dell'app (che salvava le key in chiaro in UserDefaults), al primo avvio i valori vengono spostati automaticamente nel Keychain e il vecchio record viene cancellato.

## Requisiti

- macOS 13 (Ventura) o superiore
- Xcode Command Line Tools
- Claude Code installato (`npm install -g @anthropic-ai/claude-code`)

## Installazione

```bash
git clone https://github.com/TUO_USERNAME/ClaudeLauncher.git
cd ClaudeLauncher
chmod +x install.sh make_icon.sh
./install.sh
```

Scegli opzione **2** (`~/Applications`) se non vuoi usare la password admin.

### Icona personalizzata (opzionale)

Metti un file `icon.png` (almeno 512×512) nella root del progetto, poi:

```bash
./make_icon.sh
./install.sh
```

## Prima apertura

macOS potrebbe mostrare un avviso "sviluppatore non verificato". Per aprire l'app:

```bash
xattr -cr ~/Applications/ClaudeLauncher.app
open ~/Applications/ClaudeLauncher.app
```

La prima volta che premi "Lancia Claude", Terminal chiederà il permesso per essere controllato via Apple Events: clicca **OK** — non lo chiede più.

## Licenza

MIT — vedi [LICENSE](LICENSE).
