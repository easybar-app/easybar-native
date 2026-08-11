import EasyBarShared
import Foundation
import XCTest

@testable import EasyBarNativeCtl

final class EasyBarNativeCLIProfileTests: XCTestCase {
  func testEnvironmentUsesIsolatedNativeDefaults() {
    let home = URL(fileURLWithPath: "/Users/native-test", isDirectory: true)
    let environment = EasyBarNativeCLIProfile.environment(inheriting: [:], homeDirectory: home)

    XCTAssertEqual(environment[SharedEnvironmentKeys.cliName], "easybar-native")
    XCTAssertEqual(environment[SharedEnvironmentKeys.cliDisplayName], "EasyBar Native")
    XCTAssertEqual(environment[SharedEnvironmentKeys.cliSupportsHelperAgents], "false")
    XCTAssertEqual(
      environment[SharedEnvironmentKeys.configPath],
      "/Users/native-test/.config/easybar-native/config.toml"
    )
    XCTAssertEqual(
      environment[SharedEnvironmentKeys.widgetsDirectory],
      "/Users/native-test/.config/easybar-native/widgets"
    )
    XCTAssertEqual(
      environment[SharedEnvironmentKeys.widgetPackagesDirectory],
      "/Users/native-test/.local/share/easybar-native/packages"
    )
    XCTAssertNil(environment[SharedEnvironmentKeys.calendarAgentSocketPath])
    XCTAssertNil(environment[SharedEnvironmentKeys.networkAgentSocketPath])
  }

  func testEnvironmentPreservesExplicitPathOverrides() {
    let explicit = "/tmp/custom-native-config.toml"
    let environment = EasyBarNativeCLIProfile.environment(
      inheriting: [SharedEnvironmentKeys.configPath: explicit],
      homeDirectory: URL(fileURLWithPath: "/Users/native-test", isDirectory: true)
    )

    XCTAssertEqual(environment[SharedEnvironmentKeys.configPath], explicit)
  }

  func testCoreCLIPathIsResolvedInsideTheApplicationResources() {
    let launcher = URL(
      fileURLWithPath: "/Applications/EasyBarNative.app/Contents/MacOS/easybar-native"
    )

    XCTAssertEqual(
      EasyBarNativeCLIProfile.coreCLIURL(for: launcher).path,
      "/Applications/EasyBarNative.app/Contents/Resources/EasyBarNative/CLI/EasyBarCtl"
    )
  }

  func testBareLauncherCommandResolvesThroughPATHBeforeLocatingCoreCLI() throws {
    let fileManager = FileManager.default
    let temporaryDirectory = fileManager.temporaryDirectory
      .appendingPathComponent("easybar-native-cli-profile-\(UUID().uuidString)", isDirectory: true)
    defer { try? fileManager.removeItem(at: temporaryDirectory) }

    let launcher =
      temporaryDirectory
      .appendingPathComponent("EasyBarNative.app/Contents/MacOS/easybar-native")
    let binDirectory = temporaryDirectory.appendingPathComponent("bin", isDirectory: true)
    let linkedLauncher = binDirectory.appendingPathComponent("easybar-native")
    try fileManager.createDirectory(
      at: launcher.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try fileManager.createDirectory(at: binDirectory, withIntermediateDirectories: true)
    XCTAssertTrue(fileManager.createFile(atPath: launcher.path, contents: Data()))
    try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcher.path)
    try fileManager.createSymbolicLink(at: linkedLauncher, withDestinationURL: launcher)

    let resolvedLauncher = EasyBarNativeCLIProfile.launcherURL(
      argumentZero: "easybar-native",
      environment: ["PATH": binDirectory.path],
      currentDirectoryURL: temporaryDirectory.appendingPathComponent("unrelated", isDirectory: true)
    )

    XCTAssertEqual(resolvedLauncher.resolvingSymlinksInPath().path, launcher.path)
    XCTAssertEqual(
      EasyBarNativeCLIProfile.coreCLIURL(for: resolvedLauncher).path,
      temporaryDirectory
        .appendingPathComponent("EasyBarNative.app/Contents/Resources/EasyBarNative/CLI/EasyBarCtl")
        .path
    )
  }
}
