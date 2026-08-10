import EasyBarKit
import EasyBarShared

/// Process entry point for the native macOS menu-bar frontend.
@main
enum EasyBarNativeAppMain {
  static var identity: EasyBarApplicationIdentity {
    EasyBarApplicationIdentity(
      displayName: "EasyBar Native",
      processName: "easybar-native",
      loggerLabel: "easybar-native",
      logFileName: "easybar-native.out",
      defaultConfigRelativePath: ".config/easybar-native/config.toml",
      defaultRuntimeRelativePath: ".local/state/easybar-native/runtime",
      defaultEnvironment: [
        SharedEnvironmentKeys.widgetsDirectory:
          SharedPathDefaults.homeRelativePath(".config/easybar-native/widgets").path,
        SharedEnvironmentKeys.widgetPackagesDirectory:
          SharedPathDefaults.homeRelativePath(".local/share/easybar-native/packages").path,
        SharedEnvironmentKeys.loggingDirectory:
          SharedPathDefaults.homeRelativePath(".local/state/easybar-native").path,
        SharedEnvironmentKeys.widgetEditorStubPath:
          SharedPathDefaults.homeRelativePath(".local/share/easybar-native/easybar_api.lua").path,
      ],
      builtInSurfacePolicy: .inboxOnly
    )
  }

  @MainActor
  static func main() {
    EasyBarApplication.run(identity: identity) { context in
      NativeStatusItemController(context: context)
    }
  }
}
