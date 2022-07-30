import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_MemoryLeakTests: XCTestCase {
	override func tearDown() {
		// Prevents flaky tests
		yieldProcess()
	}

	func testLoadStore() {
		var coreDataManager: CoreDataManagerLogic! = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			try await coreDataManager.loadStore()
		}

		weak var weakManager: CoreDataManagerLogic? = coreDataManager
		weak var weakContainer: NSPersistentContainer? = coreDataManager.container
		weak var weakContext: NSManagedObjectContext? = coreDataManager.mainContext

		coreDataManager = nil

		XCTAssertNil(weakManager)
		XCTAssertNil(weakContainer)
		XCTAssertNil(weakContext)
	}

	func testNewBackgroundContextGetsReleased() {
		var coreDataManager: CoreDataManagerLogic! = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			try await coreDataManager.loadStore()
		}

		var context: NSManagedObjectContext! = coreDataManager.createNewContext()

		weak var weakManager: CoreDataManagerLogic? = coreDataManager
		weak var weakContext: NSManagedObjectContext? = context

		coreDataManager = nil
		context = nil

		XCTAssertNil(weakManager)
		XCTAssertNil(weakContext)
	}

	// MARK: - Unexpected Core Data issues with Xcode 13 which were fixed with Xcode 14

	func testMainContextGetsRetainedWhenPerformIsCalled() {
		var coreDataManager: CoreDataManagerLogic! = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			try await coreDataManager.loadStore()
		}

		let taskExpectation = expectation(description: "taskExpectation")
		Task { [coreDataManager] in
			// This was enough to make the mainContext getting retained.
			await coreDataManager?.mainContext.perform {}
			taskExpectation.fulfill()
		}
		wait(for: [taskExpectation], timeout: 1.0)

		weak var weakManager: CoreDataManagerLogic? = coreDataManager
		weak var weakContainer: NSPersistentContainer? = coreDataManager.container
		weak var weakContext: NSManagedObjectContext? = coreDataManager.mainContext

		coreDataManager = nil

		XCTAssertNil(weakManager)
		XCTAssertNil(weakContainer)
		XCTAssertNil(weakContext) // This failed with Xcode 13!
	}

	func testBackgroundContextGetsRetainedWhenPerformIsCalled() {
		var coreDataManager: CoreDataManagerLogic! = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			try await coreDataManager.loadStore()
		}

		var context: NSManagedObjectContext! = coreDataManager.createNewContext()

		let taskExpectation = expectation(description: "taskExpectation")
		Task { [context] in
			// This was enough to make the context getting retained.
			await context?.perform {}
			taskExpectation.fulfill()
		}
		wait(for: [taskExpectation], timeout: 1.0)

		weak var weakManager: CoreDataManagerLogic? = coreDataManager
		weak var weakContext: NSManagedObjectContext? = context

		coreDataManager = nil
		context = nil

		XCTAssertNil(weakManager)
		XCTAssertNil(weakContext) // This failed with Xcode 13!
	}

	func testObjecIsRetainedUntilContextHasBeenQueried() {
		var coreDataManager: CoreDataManagerLogic! = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			try await coreDataManager.loadStore()
		}

		var foo: Foo!
		performAsyncThrow {
			try await coreDataManager.performTask { context in
				let newObject = Foo(context: context)
				newObject.title = UUID().uuidString
				newObject.number = 1
				context.insert(newObject)

				foo = newObject // We are holding a reference to this object
			}
		}

		weak var weakManager: CoreDataManagerLogic? = coreDataManager
		weak var weakFoo: Foo? = foo

		foo = nil
		coreDataManager = nil
		sleep(1) // For Xcode 14 this is needed, otherwise the test becomes flaky.

		XCTAssertNil(weakManager)
		XCTAssertNil(weakFoo) // This failed with Xcode 13 and still fails sometimes with Xcode 14 when not sleeping!

		// With Xcode 14 the following code has become obsolete.
		/*
		 let releaseExpectation = expectation(description: "releaseExpectation")
		 performAsyncThrow {
		 	// Querying the object's context finally released the object!
		 	await weakFoo?.managedObjectContext?.perform {
		 		releaseExpectation.fulfill() // Unnecessary, just to verify perform is really called
		 	}
		 }
		 wait(for: [releaseExpectation], timeout: 1.0)

		 XCTAssertNil(weakFoo) // Now the object has been released with Xcode 13!
		 */
	}
}
