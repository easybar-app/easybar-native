import EasyBarKit
import EasyBarShared

/// Process entry point for the native macOS menu-bar frontend.
@main
enum EasyBarNativeAppMain {
  static var identity: EasyBarApplicationIdentity {
    let sharedAgentRuntimeDirectory = SharedPathDefaults.defaultRuntimeDirectory().path

    return EasyBarApplicationIdentity(
      displayName: "EasyBar Native",
      processName: "easybar-native",
      loggerLabel: "easybar-native",
      logFileName: "easybar-native.out",
      defaultConfigRelativePath: ".config/easybar-native/config.toml",
      defaultRuntimeRelativePath: ".local/state/easybar-native/runtime",
      defaultEnvironment: [
        SharedEnvironmentKeys.calendarAgentSocketPath:
          SharedPathDefaults.calendarAgentSocketPath(in: sharedAgentRuntimeDirectory),
        SharedEnvironmentKeys.networkAgentSocketPath:
          SharedPathDefaults.networkAgentSocketPath(in: sharedAgentRuntimeDirectory),
      ]
    )
  }

  @MainActor
  static func main() {
    EasyBarApplication.run(identity: identity) { context in
      NativeStatusItemController(context: context)
    }
  }
}
