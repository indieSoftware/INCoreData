@testable import INCoreData
import XCTest

class NSManagedObject_InContextTests: XCTestCase {
	var coreDataManager: CoreDataManager!

	override func setUp() {
		super.setUp()

		let setupExpectation = expectation(description: "setupExpectation")
		coreDataManager = CoreDataManagerLogic(
			dataModelName: TestModel.name,
			bundle: Bundle(for: Self.self),
			completion: { _, _, _, _ in
				setupExpectation.fulfill()
			}
		)
		waitForExpectations()
	}

	override func tearDown() {
		super.tearDown()

		coreDataManager = nil
	}

	// MARK: - Tests

	func testFindObjectInContext() {
		let mainContext = coreDataManager.mainContext

		// Insert new object to the main context.
		let newObject = Foo(context: mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 1
		mainContext.insert(newObject)
		coreDataManager.persistMainContext()

		let backgroundContext = coreDataManager.createNewContext()

		// Method under test.
		let result = newObject.inContext(backgroundContext)

		XCTAssertEqual(result.title, newObject.title)
		XCTAssertIdentical(result.managedObjectContext, backgroundContext)
		XCTAssertIdentical(newObject.managedObjectContext, mainContext)
		XCTAssertNotIdentical(mainContext, backgroundContext)
	}
}
