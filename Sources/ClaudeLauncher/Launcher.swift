import Foundation
import AppKit

enum TerminalApp: String, CaseIterable {
    case terminal = "Terminal"
    case iTerm = "iTerm"
    case warp = "Warp"
    case ghostty = "Ghostty"

    var bundleID: String {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .iTerm:    return "com.googlecode.iterm2"
        case .warp:     return "dev.warp.Warp-Stable"
        case .ghostty:  return "com.mitchellh.ghostty"
        }
    }

    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }
}

struct Launcher {
    static func launch(folder: ProjectFolder, apiKey: APIKey, terminal: TerminalApp) {
        switch terminal {
        case .terminal:
            launchTerminalApp(folder: folder, apiKey: apiKey)
        case .iTerm:
            launchITerm(folder: folder, apiKey: apiKey)
        case .warp:
            launchWarp(folder: folder, apiKey: apiKey)
        case .ghostty:
            launchGhostty(folder: folder, apiKey: apiKey)
        }
    }

    // Uses osascript binary directly — works without Apple Events entitlements
    private static func osascript(_ script: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }

    private static func shell(_ command: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", command]
        try? task.run()
    }

    private static func launchTerminalApp(folder: ProjectFolder, apiKey: APIKey) {
        // Write a temp launcher script so we avoid quoting nightmares with the API key
        let script = makeTempScript(folder: folder, apiKey: apiKey)
        let escaped = script.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "\"", with: "\\\"")
        osascript("""
            tell application "Terminal"
                activate
                do script "\(escaped)"
            end tell
        """)
    }

    private static func launchITerm(folder: ProjectFolder, apiKey: APIKey) {
        let script = makeTempScript(folder: folder, apiKey: apiKey)
        let escaped = script.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "\"", with: "\\\"")
        osascript("""
            tell application "iTerm"
                activate
                create window with default profile
                tell current session of current window
                    write text "\(escaped)"
                end tell
            end tell
        """)
    }

    private static func launchWarp(folder: ProjectFolder, apiKey: APIKey) {
        // Warp doesn't support AppleScript injection; open folder + copy cmd
        copyCommand(folder: folder, apiKey: apiKey)
        shell("open -a Warp \"\(folder.path.replacingOccurrences(of: "\"", with: "\\\""))\"")
    }

    private static func launchGhostty(folder: ProjectFolder, apiKey: APIKey) {
        let script = makeTempScript(folder: folder, apiKey: apiKey)
        shell("open -a Ghostty --args bash -c \"\(script.replacingOccurrences(of: "\"", with: "\\\""))\"")
    }

    /// Writes a one-shot shell script to /tmp and returns the path.
    /// This sidesteps all quoting issues with special characters in API keys.
    private static func makeTempScript(folder: ProjectFolder, apiKey: APIKey) -> String {
        let tmpPath = "/tmp/claude_launch_\(UUID().uuidString.prefix(8)).sh"
        let content = """
        #!/bin/bash
        export ANTHROPIC_API_KEY='\(apiKey.value.replacingOccurrences(of: "'", with: "'\\''"))'
        cd '\(folder.path.replacingOccurrences(of: "'", with: "'\\''"))'
        claude
        """
        try? content.write(toFile: tmpPath, atomically: true, encoding: .utf8)
        shell("chmod +x \(tmpPath)")
        return tmpPath
    }

    // Copies the export command to clipboard as fallback
    static func copyCommand(folder: ProjectFolder, apiKey: APIKey) {
        let path = folder.path
        let cmd = """
        export ANTHROPIC_API_KEY="\(apiKey.value)" && cd "\(path)" && claude
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
    }
}
