@testable import INCoreData
import XCTest

class INCoreDataTests: XCTestCase {
	func testVersionNumber() {
		let version = DataManager.version()
		XCTAssertEqual(0, version)
	}
}
