import EasyBarShared

/// Maps logical EasyBar regions into the native status-area ordering model.
enum NativeWidgetOrdering {
  static func rank(for position: WidgetPosition) -> Int {
    switch position {
    case .left: 0
    case .center: 1
    case .right: 2
    }
  }

  static func precedes(
    lhsPosition: WidgetPosition,
    lhsOrder: Int,
    lhsID: String,
    rhsPosition: WidgetPosition,
    rhsOrder: Int,
    rhsID: String
  ) -> Bool {
    let lhsRank = rank(for: lhsPosition)
    let rhsRank = rank(for: rhsPosition)

    if lhsRank != rhsRank {
      return lhsRank < rhsRank
    }
    if lhsOrder != rhsOrder {
      return lhsOrder < rhsOrder
    }
    return lhsID < rhsID
  }
}
