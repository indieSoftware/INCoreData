import CoreData
@testable import INCoreData
import XCTest

class CoreDataManagerTests: XCTestCase {
	var coreDataManager: CoreDataManager!
	var persistenceStackMock: PersistenceStackMock!

	override func setUp() {
		super.setUp()

		let setupExpectation = expectation(description: "setupExpectation")
		persistenceStackMock = PersistenceStackMock()
		persistenceStackMock.initialize {
			setupExpectation.fulfill()
		}
		waitForExpectations()
		coreDataManager = CoreDataManagerLogic(persistenceStack: persistenceStackMock)
	}

	override func tearDown() {
		super.tearDown()

		persistenceStackMock = nil
		coreDataManager = nil
	}

	// MARK: - mainContext

	func testMainContextIsReturned() {
		let mainContextExpectation = expectation(description: "mainContextExpectation")
		persistenceStackMock.mainContextMock = {
			mainContextExpectation.fulfill()
			return NSManagedObjectContext(.mainQueue) // any context, doesn't matter
		}

		_ = coreDataManager.mainContext

		waitForExpectations()
	}

	// MARK: - createNewContext

	func testCreateNewContext() {
		let createNewContextExpectation = expectation(description: "createNewContextExpectation")
		persistenceStackMock.createNewContextMock = {
			createNewContextExpectation.fulfill()
			return NSManagedObjectContext(.mainQueue) // any context, doesn't matter
		}

		_ = coreDataManager.createNewContext()

		waitForExpectations()
	}

	// MARK: - persist

	func testPersist() {
		let persistExpectation = expectation(description: "persistExpectation")
		persistenceStackMock.persistMock = {
			persistExpectation.fulfill()
		}

		coreDataManager.persist()

		waitForExpectations()
	}

	// MARK: - persistFromBackgroundContext

	func testPersistFromBackgroundContext() throws {
		let persistExpectation = expectation(description: "persistExpectation")
		persistenceStackMock.persistMock = {
			persistExpectation.fulfill()
		}

		let backgroundContext = coreDataManager.createNewContext()

		// Insert new object to the main context.
		let newObject = Foo(context: backgroundContext)
		newObject.title = UUID().uuidString
		newObject.number = 1
		backgroundContext.insert(newObject)
		XCTAssertTrue(backgroundContext.hasChanges)

		try coreDataManager.persist(fromBackgroundContext: backgroundContext)

		waitForExpectations()
		XCTAssertFalse(backgroundContext.hasChanges)
	}
}
