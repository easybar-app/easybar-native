import Darwin
import Foundation

/// Thin launcher that gives EasyBarKit's shared CLI a Native-specific runtime profile.
@main
enum EasyBarNativeCtlMain {
  /// Applies the Native profile and forwards the command to the bundled shared CLI core.
  static func main() {
    let environment = ProcessInfo.processInfo.environment
    let launcherURL = EasyBarNativeCLIProfile.launcherURL(
      argumentZero: CommandLine.arguments[0],
      environment: environment
    )
    let coreCLI = EasyBarNativeCLIProfile.coreCLIURL(
      for: launcherURL
    )

    guard FileManager.default.isExecutableFile(atPath: coreCLI.path) else {
      fputs("easybar-native: bundled EasyBarCtl executable not found: \(coreCLI.path)\n", stderr)
      exit(1)
    }

    let childEnvironment = EasyBarNativeCLIProfile.environment(inheriting: environment)

    let process = Process()
    process.executableURL = coreCLI
    process.arguments = Array(CommandLine.arguments.dropFirst())
    process.environment = childEnvironment
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
}
