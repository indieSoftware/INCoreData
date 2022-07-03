import Foundation
import XCTest

extension XCTestCase {
	/// The default time for expectations when they should time out.
	static let defaultExpectationTimeout: TimeInterval = 0.5

	/**
	 Waits until the test fulfills all expectations or until it times out.
	 */
	func waitForExpectations() {
		waitForExpectations(timeout: XCTestCase.defaultExpectationTimeout)
	}
}
