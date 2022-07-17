import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_RaceConditionTests: XCTestCase {
	private var coreDataManager: CoreDataManagerLogic!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = try CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			// Prepare manager.
			try await self.coreDataManager.loadStore()
		}
	}

	override func tearDownWithError() throws {
		coreDataManager = nil
		try super.tearDownWithError()
	}

	// MARK: - Tests

	func testDataRaceWithTwoBackgroundContexts() throws {
		let mainContext = coreDataManager.mainContext

		// Add initial object to the main context.
		var fooId: NSManagedObjectID!
		var foo: Foo!
		performAsyncThrow {
			try await mainContext.perform {
				foo = Foo(context: mainContext)
				foo.title = "None"
				foo.number = 1
				mainContext.insert(foo)
				try mainContext.save()
				fooId = foo.objectID
			}
		}

		// Get two parallel background contexts and fetch foo from each.
		let backgroundContext1 = coreDataManager.createNewContext()
		var fooInContext1: Foo!
		performAsyncThrow {
			try await backgroundContext1.perform {
				fooInContext1 = try XCTUnwrap(backgroundContext1.object(with: fooId) as? Foo)
				XCTAssertEqual(fooInContext1.title, "None")
				XCTAssertEqual(fooInContext1.number, 1)
			}
		}

		let backgroundContext2 = coreDataManager.createNewContext()
		var fooInContext2: Foo!
		performAsyncThrow {
			try await backgroundContext2.perform {
				fooInContext2 = try XCTUnwrap(backgroundContext2.object(with: fooId) as? Foo)
				XCTAssertEqual(fooInContext2.title, "None")
				XCTAssertEqual(fooInContext2.number, 1)
			}
		}

		// Updating foo on tha main context automatically updates the background contexts
		// even though the main context has not been saved or persisted.
		performAsyncThrow {
			try await mainContext.perform {
				foo.title = "Foo"
				try mainContext.save()
			}
		}

		performAsyncThrow {
			await backgroundContext1.perform {
				XCTAssertEqual(fooInContext1.title, "Foo")
				XCTAssertEqual(fooInContext1.number, 1)
			}
		}

		performAsyncThrow {
			await backgroundContext2.perform {
				XCTAssertEqual(fooInContext2.title, "Foo")
				XCTAssertEqual(fooInContext2.number, 1)
			}
		}

		// Both properties are updated on context 1 which has no impact on other contexts.
		performAsyncThrow {
			await backgroundContext1.perform {
				fooInContext1.title = "Bar"
				fooInContext1.number = 2
			}
		}

		performAsyncThrow {
			await mainContext.perform {
				XCTAssertEqual(foo.title, "Foo")
				XCTAssertEqual(foo.number, 1)
			}
		}

		performAsyncThrow {
			await backgroundContext2.perform {
				XCTAssertEqual(fooInContext2.title, "Foo")
				XCTAssertEqual(fooInContext2.number, 1)
			}
		}

		// Only one property is updated on context 2 which also has no effect on other contexts.
		performAsyncThrow {
			await backgroundContext2.perform {
				fooInContext2.number = 3
			}
		}

		performAsyncThrow {
			await mainContext.perform {
				XCTAssertEqual(foo.title, "Foo")
				XCTAssertEqual(foo.number, 1)
			}
		}

		performAsyncThrow {
			await backgroundContext1.perform {
				XCTAssertEqual(fooInContext1.title, "Bar")
				XCTAssertEqual(fooInContext1.number, 2)
			}
		}

		performAsyncThrow {
			await backgroundContext2.perform {
				XCTAssertEqual(fooInContext2.title, "Foo")
				XCTAssertEqual(fooInContext2.number, 3)
			}
		}

		// Saving the changes on context 1 updates foo with the information
		// from the first context, but leaves the second context untouched.
		performAsyncThrow {
			try await backgroundContext1.perform {
				try backgroundContext1.save()
			}
		}

		performAsyncThrow {
			await mainContext.perform {
				XCTAssertEqual(foo.title, "Bar")
				XCTAssertEqual(foo.number, 2)
			}
		}

		performAsyncThrow {
			await backgroundContext1.perform {
				XCTAssertEqual(fooInContext1.title, "Bar")
				XCTAssertEqual(fooInContext1.number, 2)
			}
		}

		performAsyncThrow {
			await backgroundContext2.perform {
				XCTAssertEqual(fooInContext2.title, "Foo")
				XCTAssertEqual(fooInContext2.number, 3)
			}
		}

		// Saving the changes on context 2 overwrites the first save,
		// but only for those properties which have been updated in the second context
		// and only on the main context.
		performAsyncThrow {
			try await backgroundContext2.perform {
				try backgroundContext2.save()
			}
		}

		performAsyncThrow {
			await mainContext.perform {
				XCTAssertEqual(foo.title, "Bar")
				XCTAssertEqual(foo.number, 3)
			}
		}

		performAsyncThrow {
			await backgroundContext1.perform {
				XCTAssertEqual(fooInContext1.title, "Bar")
				XCTAssertEqual(fooInContext1.number, 2)
			}
		}

		performAsyncThrow {
			await backgroundContext2.perform {
				XCTAssertEqual(fooInContext2.title, "Foo")
				XCTAssertEqual(fooInContext2.number, 3)
			}
		}

		// When saving the main context then it also updates all the other contexts.
		performAsyncThrow {
			try await mainContext.perform {
				try mainContext.save()
			}
		}

		performAsyncThrow {
			await mainContext.perform {
				XCTAssertEqual(foo.title, "Bar")
				XCTAssertEqual(foo.number, 3)
			}
		}

		performAsyncThrow {
			await backgroundContext1.perform {
				XCTAssertEqual(fooInContext1.title, "Bar")
				XCTAssertEqual(fooInContext1.number, 3)
			}
		}

		performAsyncThrow {
			await backgroundContext2.perform {
				XCTAssertEqual(fooInContext2.title, "Bar")
				XCTAssertEqual(fooInContext2.number, 3)
			}
		}
	}
}
