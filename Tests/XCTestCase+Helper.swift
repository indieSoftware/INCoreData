import CoreData
import XCTest

extension XCTestCase {
	/**
	 Returns the "TestModel" from the tests.
	 */
	func testModel() -> NSManagedObjectModel {
		let bundle = Bundle(for: Self.self)
		guard let modelUrl = bundle.url(forResource: "TestModel", withExtension: "momd"),
		      let objectModel = NSManagedObjectModel(contentsOf: modelUrl)
		else {
			fatalError("Error initializing managed object model")
		}
		return objectModel
	}
}
