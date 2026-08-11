import EasyBarShared
import Foundation

/// Resolves the isolated runtime contract used by the `easybar-native` launcher.
enum EasyBarNativeCLIProfile {
  private static let pathDefaults = [
    SharedEnvironmentKeys.configPath: ".config/easybar-native/config.toml",
    SharedEnvironmentKeys.runtimeDirectory: ".local/state/easybar-native/runtime",
    SharedEnvironmentKeys.widgetsDirectory: ".config/easybar-native/widgets",
    SharedEnvironmentKeys.widgetPackagesDirectory: ".local/share/easybar-native/packages",
    SharedEnvironmentKeys.loggingDirectory: ".local/state/easybar-native",
    SharedEnvironmentKeys.widgetEditorStubPath: ".local/share/easybar-native/easybar_api.lua",
  ]

  /// Resolves the launcher path exactly as the invoking shell did, including a bare PATH command.
  static func launcherURL(
    argumentZero: String,
    environment: [String: String],
    currentDirectoryURL: URL = URL(
      fileURLWithPath: FileManager.default.currentDirectoryPath,
      isDirectory: true
    ),
    fileManager: FileManager = .default
  ) -> URL {
    let suppliedURL = URL(
      fileURLWithPath: argumentZero,
      relativeTo: currentDirectoryURL
    ).standardizedFileURL
    guard !argumentZero.contains("/") else { return suppliedURL }

    for pathEntry in environment["PATH", default: ""].split(
      separator: ":",
      omittingEmptySubsequences: false
    ) {
      let directoryURL =
        pathEntry.isEmpty
        ? currentDirectoryURL
        : URL(
          fileURLWithPath: String(pathEntry),
          isDirectory: true,
          relativeTo: currentDirectoryURL
        ).standardizedFileURL
      let candidate = directoryURL.appendingPathComponent(argumentZero, isDirectory: false)
      if fileManager.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }

    return suppliedURL
  }

  /// Locates the private shared CLI core relative to the installed launcher, resolving symlinks.
  static func coreCLIURL(for executableURL: URL) -> URL {
    executableURL.resolvingSymlinksInPath()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Resources")
      .appendingPathComponent("EasyBarNative")
      .appendingPathComponent("CLI")
      .appendingPathComponent("EasyBarCtl")
  }

  /// Returns a child-process environment with Native defaults and no helper-agent commands.
  static func environment(
    inheriting base: [String: String],
    homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
  ) -> [String: String] {
    var environment = base
    for (key, relativePath) in pathDefaults where environment[key] == nil {
      environment[key] = homeDirectory.appendingPathComponent(relativePath).standardizedFileURL.path
    }

    environment[SharedEnvironmentKeys.cliName] = "easybar-native"
    environment[SharedEnvironmentKeys.cliDisplayName] = "EasyBar Native"
    environment[SharedEnvironmentKeys.cliSupportsHelperAgents] = "false"
    return environment
  }
}
