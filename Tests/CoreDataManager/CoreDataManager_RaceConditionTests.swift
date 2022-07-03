import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_RaceConditionTests: XCTestCase {
	private var coreDataManager: CoreDataManager!

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

	func testDataRaceWithTwoBackgroundContexts() throws {
		let mainContext = coreDataManager.mainContext

		// Add initial object to the main context.
		var fooId: NSManagedObjectID!
		var foo: Foo!
//		mainContext.performAndWait {
		foo = Foo(context: mainContext)
		foo.title = "None"
		foo.number = 1
		mainContext.insert(foo)
		coreDataManager.persistMainContext()
		fooId = foo.objectID
//		}

		// Get two parallel background contexts and fetch foo from each.
		let queue1 = DispatchQueue(label: "Queue1", qos: .background)
		var backgroundContext1: NSManagedObjectContext!
		queue1.sync {
			backgroundContext1 = coreDataManager.createNewContext()
		}
		var fooInContext1: Foo!
		try backgroundContext1.performAndWait {
			fooInContext1 = try XCTUnwrap(backgroundContext1.object(with: fooId) as? Foo)
			XCTAssertEqual(fooInContext1.title, "None")
			XCTAssertEqual(fooInContext1.number, 1)
		}

		let queue2 = DispatchQueue(label: "Queue2", qos: .background)
		var backgroundContext2: NSManagedObjectContext!
		queue2.sync {
			backgroundContext2 = coreDataManager.createNewContext()
		}
		var fooInContext2: Foo!
		try backgroundContext2.performAndWait {
			fooInContext2 = try XCTUnwrap(backgroundContext2.object(with: fooId) as? Foo)
			XCTAssertEqual(fooInContext2.title, "None")
			XCTAssertEqual(fooInContext2.number, 1)
		}

		// Updating foo on tha main context automatically updates the background contexts
		// even though the main context has not been saved or persisted.
//		mainContext.performAndWait {
		foo.title = "Foo"
//		}

		backgroundContext1.performAndWait {
			XCTAssertEqual(fooInContext1.title, "Foo")
			XCTAssertEqual(fooInContext1.number, 1)
		}

		backgroundContext2.performAndWait {
			XCTAssertEqual(fooInContext2.title, "Foo")
			XCTAssertEqual(fooInContext2.number, 1)
		}

		// Both properties are updated on context 1 which has no impact on other contexts.
		backgroundContext1.performAndWait {
			fooInContext1.title = "Bar"
			fooInContext1.number = 2
		}

//		mainContext.performAndWait {
		XCTAssertEqual(foo.title, "Foo")
		XCTAssertEqual(foo.number, 1)
//		}

		backgroundContext2.performAndWait {
			XCTAssertEqual(fooInContext2.title, "Foo")
			XCTAssertEqual(fooInContext2.number, 1)
		}

		// Only one property is updated on context 2 which also has no effect on other contexts.
		backgroundContext2.performAndWait {
			fooInContext2.number = 3
		}

//		mainContext.performAndWait {
		XCTAssertEqual(foo.title, "Foo")
		XCTAssertEqual(foo.number, 1)
//		}

		backgroundContext1.performAndWait {
			XCTAssertEqual(fooInContext1.title, "Bar")
			XCTAssertEqual(fooInContext1.number, 2)
		}

		backgroundContext2.performAndWait {
			XCTAssertEqual(fooInContext2.title, "Foo")
			XCTAssertEqual(fooInContext2.number, 3)
		}

		// The first persist updates foo with the information from the first context,
		// but leaves the second context untouched.
		try backgroundContext1.performAndWait {
			try coreDataManager.persist(backgroundContext: backgroundContext1)
		}

//		mainContext.performAndWait {
		XCTAssertEqual(foo.title, "Bar")
		XCTAssertEqual(foo.number, 2)
//		}

		backgroundContext1.performAndWait {
			XCTAssertEqual(fooInContext1.title, "Bar")
			XCTAssertEqual(fooInContext1.number, 2)
		}

//		backgroundContext2.performAndWait {
//			XCTAssertEqual(fooInContext2.title, "Foo")
//			XCTAssertEqual(fooInContext2.number, 3)
//		}

		// The second persist overwrites the first persist,
		// but only for those properties which have been updated in the second context.
//		try backgroundContext2.performAndWait {
//			try coreDataManager.persist(backgroundContext: backgroundContext2)
//		}

//		mainContext.performAndWait {
		XCTAssertEqual(foo.title, "Bar")
		XCTAssertEqual(foo.number, 3)
//		}

		backgroundContext1.performAndWait {
			XCTAssertEqual(fooInContext1.title, "Bar")
			XCTAssertEqual(fooInContext1.number, 3)
		}

		backgroundContext2.performAndWait {
			XCTAssertEqual(fooInContext2.title, "Bar")
			XCTAssertEqual(fooInContext2.number, 3)
		}
	}
}
