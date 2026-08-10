import EasyBarShared
import XCTest

@testable import EasyBarNativeApp

final class NativeWidgetOrderingTests: XCTestCase {
  func testLogicalRegionsHaveDeterministicRanks() {
    XCTAssertEqual(NativeWidgetOrdering.rank(for: .left), 0)
    XCTAssertEqual(NativeWidgetOrdering.rank(for: .center), 1)
    XCTAssertEqual(NativeWidgetOrdering.rank(for: .right), 2)
  }

  func testOrderingUsesRegionThenOrderThenIdentifier() {
    XCTAssertTrue(
      NativeWidgetOrdering.precedes(
        lhsPosition: .left,
        lhsOrder: 100,
        lhsID: "z",
        rhsPosition: .center,
        rhsOrder: 0,
        rhsID: "a"
      )
    )
    XCTAssertTrue(
      NativeWidgetOrdering.precedes(
        lhsPosition: .right,
        lhsOrder: 1,
        lhsID: "z",
        rhsPosition: .right,
        rhsOrder: 2,
        rhsID: "a"
      )
    )
    XCTAssertTrue(
      NativeWidgetOrdering.precedes(
        lhsPosition: .right,
        lhsOrder: 2,
        lhsID: "a",
        rhsPosition: .right,
        rhsOrder: 2,
        rhsID: "b"
      )
    )
  }
}
