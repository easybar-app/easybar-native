import AppKit
import Combine
import EasyBarKit
import EasyBarShared
import SwiftUI

/// Presents every EasyBar top-level widget as an independent native `NSStatusItem`.
@MainActor
final class NativeStatusItemController: EasyBarSurfaceController {
  private let context: EasyBarSurfaceContext
  private let presentationModel: EasyBarPresentationModel
  private var entries: [String: NativeStatusItemEntry] = [:]
  private var orderedIDs: [String] = []
  private var widgetSubscription: AnyCancellable?
  private var isVisible = false

  init(context: EasyBarSurfaceContext) {
    self.context = context
    self.presentationModel = context.presentationModel
  }

  func present() {
    isVisible = true
    installSubscriptionIfNeeded()
    reconcile(presentationModel.widgets)
    setEntriesVisible(true)
  }

  func hide() {
    isVisible = false
    setEntriesVisible(false)
  }

  func reloadLayout() {
    reconcile(presentationModel.widgets, forceReorder: true)
  }

  func stop() {
    widgetSubscription?.cancel()
    widgetSubscription = nil
    removeAllStatusItems()
  }

  private func installSubscriptionIfNeeded() {
    guard widgetSubscription == nil else { return }

    widgetSubscription = presentationModel.$widgets
      .sink { [weak self] widgets in
        self?.reconcile(widgets)
      }
  }

  /// Keeps native status items aligned with the current top-level runtime widgets.
  private func reconcile(
    _ widgets: [EasyBarPresentationModel.WidgetSurface],
    forceReorder: Bool = false
  ) {
    let sorted = widgets.sorted(by: nativeOrder)
    let nextIDs = sorted.map(\.id)

    // AppKit does not expose arbitrary insertion indices for NSStatusItems. Recreate
    // only when ordering changes; ordinary widget state refreshes update in place.
    if forceReorder || nextIDs != orderedIDs {
      removeAllStatusItems()
      orderedIDs = nextIDs

      // Status items are allocated from the system-status area inward. Creating the
      // logical order in reverse keeps the visible order intuitive for this app.
      for widget in sorted.reversed() {
        entries[widget.id] = makeEntry(for: widget)
      }
      setEntriesVisible(isVisible)
      return
    }

    for widget in sorted {
      guard let entry = entries[widget.id] else { continue }
      update(entry: entry, with: widget)
    }
  }

  private func makeEntry(for widget: EasyBarPresentationModel.WidgetSurface)
    -> NativeStatusItemEntry
  {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.autosaveName = "easybar-native.\(widget.id)"

    let hostingView = NSHostingView(rootView: widget.makeView())
    let entry = NativeStatusItemEntry(statusItem: statusItem, hostingView: hostingView)

    guard let button = statusItem.button else {
      context.logger.warn("native status item has no button", .field("widget", widget.id))
      return entry
    }

    button.title = ""
    button.image = nil
    button.imagePosition = .noImage
    button.toolTip = widget.id

    hostingView.translatesAutoresizingMaskIntoConstraints = false
    button.addSubview(hostingView)
    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
      hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
      hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      hostingView.heightAnchor.constraint(lessThanOrEqualTo: button.heightAnchor),
    ])

    update(entry: entry, with: widget)
    return entry
  }

  private func update(
    entry: NativeStatusItemEntry,
    with widget: EasyBarPresentationModel.WidgetSurface
  ) {
    entry.hostingView.rootView = widget.makeView()
    entry.hostingView.invalidateIntrinsicContentSize()
    entry.hostingView.needsLayout = true
    entry.hostingView.layoutSubtreeIfNeeded()

    let fittingWidth = entry.hostingView.fittingSize.width
    let minimumWidth = max(18, NSStatusBar.system.thickness)
    entry.statusItem.length = max(minimumWidth, ceil(fittingWidth) + 4)
    entry.statusItem.isVisible = isVisible
  }

  private func setEntriesVisible(_ visible: Bool) {
    for entry in entries.values {
      entry.statusItem.isVisible = visible
    }
  }

  private func removeAllStatusItems() {
    for entry in entries.values {
      NSStatusBar.system.removeStatusItem(entry.statusItem)
    }
    entries.removeAll()
    orderedIDs.removeAll()
  }

  /// Converts EasyBar's left/center/right positions into one deterministic native order.
  /// macOS still owns the actual system status area, so these are relative ordering hints.
  private func nativeOrder(
    _ lhs: EasyBarPresentationModel.WidgetSurface,
    _ rhs: EasyBarPresentationModel.WidgetSurface
  ) -> Bool {
    NativeWidgetOrdering.precedes(
      lhsPosition: lhs.position,
      lhsOrder: lhs.order,
      lhsID: lhs.id,
      rhsPosition: rhs.position,
      rhsOrder: rhs.order,
      rhsID: rhs.id
    )
  }
}
