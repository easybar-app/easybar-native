import AppKit
import SwiftUI

/// AppKit objects owned by one EasyBar Native widget surface.
final class NativeStatusItemEntry {
  /// System status item allocated for the widget surface.
  let statusItem: NSStatusItem

  /// SwiftUI host embedded in the status item's button.
  let hostingView: NSHostingView<AnyView>

  /// Couples one system status item with the SwiftUI view hosted inside its button.
  init(statusItem: NSStatusItem, hostingView: NSHostingView<AnyView>) {
    self.statusItem = statusItem
    self.hostingView = hostingView
  }
}
