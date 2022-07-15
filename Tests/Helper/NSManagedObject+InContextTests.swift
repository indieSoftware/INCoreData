@testable import INCoreData
import XCTest

class NSManagedObject_InContextTests: XCTestCase {
	var coreDataManager: CoreDataManagerLogic!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = try CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)
		performAsyncThrow {
			try await self.coreDataManager.loadStore()
		}
	}

	override func tearDownWithError() throws {
		try super.tearDownWithError()

		coreDataManager = nil
	}

	// MARK: - Tests

	func testFindObjectInContext() {
		var newObject: Foo!

		// Insert new object to the main context.
		let title = UUID().uuidString
		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				newObject = Foo(context: context)
				newObject.title = title
				newObject.number = 1
				context.insert(newObject)
			}
		}

		let backgroundContext = coreDataManager.createNewContext()
		XCTAssertNotIdentical(coreDataManager.mainContext, backgroundContext)

		performAsyncThrow {
			await backgroundContext.perform {
				// Method under test.
				let result = newObject.inContext(backgroundContext)

				// Verify the object matches the original.
				XCTAssertEqual(result.title, title)
				XCTAssertIdentical(result.managedObjectContext, backgroundContext)
				XCTAssertIdentical(result.managedObjectContext, backgroundContext)
				XCTAssertNotIdentical(result.managedObjectContext, newObject.managedObjectContext)
			}
		}
	}
}
