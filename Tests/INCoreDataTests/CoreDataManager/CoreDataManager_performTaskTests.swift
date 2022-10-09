import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_performTaskTests: XCTestCase {
	override func tearDown() {
		// Prevents flaky tests
		yieldProcess()
	}

	func testPerformTaskRequestsFromContainerAndPerformsTask() throws {
		// Create the persistent container mock.
		let persistentContainerMock = try XCTUnwrap(PersistentContainerMock())
		persistentContainerMock.viewContextMock = {
			persistentContainerMock.viewContextSuper
		}
		let containerExpectation = expectation(description: "containerExpectation")
		Task {
			try await persistentContainerMock.loadPersistentStoreSuper()
			containerExpectation.fulfill()
		}
		waitForExpectations()

		// Inject the mock into the mananger.
		let coreDataManager = CoreDataManager(persistentContainer: persistentContainerMock)

		// Test that a new background context will be requested.
		let newContextExpectation = expectation(description: "newContextExpectation")
		persistentContainerMock.createNewContextMock = {
			newContextExpectation.fulfill()
			let context = persistentContainerMock.createNewContextSuper()
			context.name = "New background context"
			return context
		}

		// Test task will be executed with the new context as its parameter.
		let title = UUID().uuidString
		let taskExpectation = expectation(description: "taskExpectation")
		let task: @Sendable (NSManagedObjectContext) throws -> Void = { passedContext in
			XCTAssertEqual(passedContext.name, "New background context")

			// Create new object to check if save is really called.
			let newObject = Foo(context: passedContext)
			newObject.title = title
			newObject.number = 1
			passedContext.insert(newObject)

			taskExpectation.fulfill()
		}

		// Test that the viewContext will be requested.
		let mainContextExpectation = expectation(description: "mainContextExpectation")
		mainContextExpectation.expectedFulfillmentCount = 2
		persistentContainerMock.viewContextMock = {
			mainContextExpectation.fulfill()
			return persistentContainerMock.viewContextSuper
		}

		// Test that persist will be called.
		let persistExpectation = expectation(description: "persistExpectation")
		persistentContainerMock.persistMock = {
			try await persistentContainerMock.persistSuper()
			persistExpectation.fulfill()
		}

		// Call method under test.
		performAsyncThrow {
			try await coreDataManager.performTask(task)
		}

		waitForExpectations()

		// Confirm that the object has been saved on the main context.
		let mainContext = persistentContainerMock.viewContextSuper
		let verificationExpectation = expectation(description: "verificationExpectation")
		Task {
			try await mainContext.perform {
				XCTAssertFalse(mainContext.hasChanges)
				let foos = try mainContext.fetch(Foo.fetchRequest())
				XCTAssertEqual(1, foos.count)
				let foo = try XCTUnwrap(foos.first)
				XCTAssertEqual(foo.title, title)
				XCTAssertEqual(foo.number, 1)
			}
			verificationExpectation.fulfill()
		}
		waitForExpectations()
	}
}
