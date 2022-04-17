@testable import INCoreData
import XCTest

class INCoreDataTests: XCTestCase {
	func testVersionNumber() {
		let version = INCoreDataVersion.version
		XCTAssertEqual(1, version)
	}
}
