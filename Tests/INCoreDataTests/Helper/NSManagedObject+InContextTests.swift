@testable import INCoreData
import XCTest

class NSManagedObject_InContextTests: XCTestCase {
	var coreDataManager: CoreDataManager!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = CoreDataManager(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)
		performAsyncThrow {
			try await self.coreDataManager.loadStore()
		}
	}

	override func tearDownWithError() throws {
		coreDataManager = nil

		// Prevents flaky tests
		yieldProcess()

		try super.tearDownWithError()
	}

	// MARK: - Tests

	func testFindObjectInContext() {
		let newObjectHolder = ObjectHolder<Foo>()

		// Insert new object to the main context.
		let title = UUID().uuidString
		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let newObject = Foo(context: context)
				newObject.title = title
				newObject.number = 1
				context.insert(newObject)
				newObjectHolder.object = newObject
			}
		}

		let context = coreDataManager.mainContext

		performAsyncThrow {
			try await context.perform {
				// Method under test.
				let result = try XCTUnwrap(newObjectHolder.object?.inContext(context))

				// Verify the object matches the original.
				XCTAssertTrue(result.isFault)
				XCTAssertEqual(result.title, title)
				XCTAssertFalse(result.isFault)
				XCTAssertIdentical(result.managedObjectContext, context)
				XCTAssertNotIdentical(result.managedObjectContext, newObjectHolder.object?.managedObjectContext)
			}
		}
	}

	func testReturnsFaultObjectForNonExistent() {
		let backgroundContext1 = coreDataManager.createNewContext()
		var newObject: Foo!

		// Create new object, but don't add it to the context.
		let title = UUID().uuidString
		performAsyncThrow {
			await backgroundContext1.perform {
				newObject = Foo(context: backgroundContext1)
				newObject.title = title
			}
		}

		let backgroundContext2 = coreDataManager.createNewContext()

		performAsyncThrow {
			await backgroundContext2.perform {
				// Method under test.
				let result = newObject.inContext(backgroundContext2)

				// An empty fault object is returned.
				XCTAssertTrue(result.isFault)
				XCTAssertNil(result.title)
				XCTAssertFalse(result.isFault)
			}
		}
	}
}
