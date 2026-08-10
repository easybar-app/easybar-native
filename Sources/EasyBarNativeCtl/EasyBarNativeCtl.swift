import Darwin
import EasyBarShared
import Foundation

/// Thin launcher that gives EasyBarKit's shared CLI a Native-specific runtime profile.
@main
enum EasyBarNativeCtlMain {
  static func main() {
    let executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    let contentsURL = executableURL.deletingLastPathComponent().deletingLastPathComponent()
    let coreCLI =
      contentsURL
      .appendingPathComponent("Resources")
      .appendingPathComponent("EasyBarNative")
      .appendingPathComponent("CLI")
      .appendingPathComponent("EasyBarCtl")

    guard FileManager.default.isExecutableFile(atPath: coreCLI.path) else {
      fputs("easybar-native: bundled EasyBarCtl executable not found: \(coreCLI.path)\n", stderr)
      exit(1)
    }

    var environment = ProcessInfo.processInfo.environment
    setDefault(
      SharedEnvironmentKeys.configPath,
      path: ".config/easybar-native/config.toml",
      environment: &environment
    )
    setDefault(
      SharedEnvironmentKeys.runtimeDirectory,
      path: ".local/state/easybar-native/runtime",
      environment: &environment
    )
    setDefault(
      SharedEnvironmentKeys.widgetsDirectory,
      path: ".config/easybar-native/widgets",
      environment: &environment
    )
    setDefault(
      SharedEnvironmentKeys.widgetPackagesDirectory,
      path: ".local/share/easybar-native/packages",
      environment: &environment
    )
    setDefault(
      SharedEnvironmentKeys.loggingDirectory,
      path: ".local/state/easybar-native",
      environment: &environment
    )
    setDefault(
      SharedEnvironmentKeys.widgetEditorStubPath,
      path: ".local/share/easybar-native/easybar_api.lua",
      environment: &environment
    )

    environment[SharedEnvironmentKeys.cliName] = "easybar-native"
    environment[SharedEnvironmentKeys.cliDisplayName] = "EasyBar Native"
    environment[SharedEnvironmentKeys.cliSupportsHelperAgents] = "false"

    let process = Process()
    process.executableURL = coreCLI
    process.arguments = Array(CommandLine.arguments.dropFirst())
    process.environment = environment
    process.standardInput = FileHandle.standardInput
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
      try process.run()
      process.waitUntilExit()
      exit(process.terminationStatus)
    } catch {
      fputs("easybar-native: failed to start shared CLI: \(error.localizedDescription)\n", stderr)
      exit(1)
    }
  }

  private static func setDefault(
    _ key: String,
    path relativePath: String,
    environment: inout [String: String]
  ) {
    guard environment[key] == nil else { return }
    environment[key] = SharedPathDefaults.homeRelativePath(relativePath).path
  }
}
