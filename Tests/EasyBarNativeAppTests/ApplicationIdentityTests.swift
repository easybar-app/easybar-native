import EasyBarKit
import EasyBarShared
import XCTest

@testable import EasyBarNativeApp

final class ApplicationIdentityTests: XCTestCase {
  func testNativeIdentityOwnsRuntimeAndUserData() {
    let identity = EasyBarNativeAppMain.identity

    XCTAssertEqual(identity.displayName, "EasyBar Native")
    XCTAssertEqual(identity.processName, "easybar-native")
    XCTAssertEqual(identity.loggerLabel, "easybar-native")
    XCTAssertEqual(identity.logFileName, "easybar-native.out")
    XCTAssertEqual(identity.defaultConfigRelativePath, ".config/easybar-native/config.toml")
    XCTAssertEqual(identity.defaultRuntimeRelativePath, ".local/state/easybar-native/runtime")
    XCTAssertEqual(identity.builtInSurfacePolicy, .inboxOnly)

    XCTAssertEqual(
      identity.defaultEnvironment[SharedEnvironmentKeys.widgetsDirectory],
      SharedPathDefaults.homeRelativePath(".config/easybar-native/widgets").path
    )
    XCTAssertEqual(
      identity.defaultEnvironment[SharedEnvironmentKeys.widgetPackagesDirectory],
      SharedPathDefaults.homeRelativePath(".local/share/easybar-native/packages").path
    )
    XCTAssertEqual(
      identity.defaultEnvironment[SharedEnvironmentKeys.loggingDirectory],
      SharedPathDefaults.homeRelativePath(".local/state/easybar-native").path
    )
    XCTAssertEqual(
      identity.defaultEnvironment[SharedEnvironmentKeys.widgetEditorStubPath],
      SharedPathDefaults.homeRelativePath(".local/share/easybar-native/easybar_api.lua").path
    )

    XCTAssertNil(identity.defaultEnvironment[SharedEnvironmentKeys.calendarAgentSocketPath])
    XCTAssertNil(identity.defaultEnvironment[SharedEnvironmentKeys.networkAgentSocketPath])
  }
}
