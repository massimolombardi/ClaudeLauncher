# Claude Launcher

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Platform: macOS](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

A native macOS app for launching [Claude Code](https://github.com/anthropics/claude-code) with the right API key and project folder, without having to run `export ANTHROPIC_API_KEY=...` every time.

## Features

- Save multiple API keys with custom names, encrypted in the macOS Keychain
- Save your favorite project folders
- Launch Claude Code in one click with the selected key and folder
- Supports Terminal, iTerm2, Warp, and Ghostty
- Persists the default terminal between sessions
- Includes a "Copy command" fallback button
- Lets the user switch the app language between English and Italian

## Security

API keys are never written to disk in plain text. The app uses two storage layers:

| Data | Stored in | Encrypted |
|------|-----------|-----------|
| API key value | macOS Keychain | Yes, encrypted by the OS |
| Name, id, date | UserDefaults | Not sensitive |
| Project folders | UserDefaults | Not sensitive |

The macOS Keychain encrypts secrets at the operating system level and only makes them available when the Mac is unlocked. No secret files are ever created inside the project folder, so `git push` is safe without extra precautions.

You can verify this by opening **Keychain Access.app** and searching for `com.local.claudelauncher`.

**Automatic migration:** if you used an older version of the app that stored keys in plain text in UserDefaults, the values are moved automatically to the Keychain on first launch and the old record is deleted.

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools
- Claude Code installed (`npm install -g @anthropic-ai/claude-code`)

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/ClaudeLauncher.git
cd ClaudeLauncher
chmod +x install.sh make_icon.sh
./install.sh
```

Choose option **2** (`~/Applications`) if you do not want to use an admin password.

### Custom Icon (Optional)

Place an `icon.png` file (at least 512x512) in the project root, then run:

```bash
./make_icon.sh
./install.sh
```

## First Launch

macOS may show an "unverified developer" warning. To open the app:

```bash
xattr -cr ~/Applications/ClaudeLauncher.app
open ~/Applications/ClaudeLauncher.app
```

The first time you press "Launch Claude", Terminal will ask for permission to be controlled via Apple Events. Click **OK** and it will not ask again.

## License

MIT. See [LICENSE](LICENSE).
