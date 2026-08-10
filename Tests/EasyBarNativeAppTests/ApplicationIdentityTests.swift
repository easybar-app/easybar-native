import EasyBarKit
import EasyBarShared
import XCTest

@testable import EasyBarNativeApp

final class ApplicationIdentityTests: XCTestCase {
  func testNativeIdentityOwnsRuntimeAndUsesSharedAgentSockets() {
    let identity = EasyBarNativeAppMain.identity
    let sharedRuntimeDirectory = SharedPathDefaults.defaultRuntimeDirectory().path

    XCTAssertEqual(identity.displayName, "EasyBar Native")
    XCTAssertEqual(identity.processName, "easybar-native")
    XCTAssertEqual(identity.loggerLabel, "easybar-native")
    XCTAssertEqual(identity.logFileName, "easybar-native.out")
    XCTAssertEqual(identity.defaultConfigRelativePath, ".config/easybar-native/config.toml")
    XCTAssertEqual(identity.defaultRuntimeRelativePath, ".local/state/easybar-native/runtime")
    XCTAssertEqual(
      identity.defaultEnvironment[SharedEnvironmentKeys.calendarAgentSocketPath],
      SharedPathDefaults.calendarAgentSocketPath(in: sharedRuntimeDirectory)
    )
    XCTAssertEqual(
      identity.defaultEnvironment[SharedEnvironmentKeys.networkAgentSocketPath],
      SharedPathDefaults.networkAgentSocketPath(in: sharedRuntimeDirectory)
    )
  }
}
