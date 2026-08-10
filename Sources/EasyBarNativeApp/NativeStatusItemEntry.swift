import AppKit
import SwiftUI

/// AppKit objects owned by one EasyBar Native widget surface.
final class NativeStatusItemEntry {
  let statusItem: NSStatusItem
  let hostingView: NSHostingView<AnyView>

  init(statusItem: NSStatusItem, hostingView: NSHostingView<AnyView>) {
    self.statusItem = statusItem
    self.hostingView = hostingView
  }
}
