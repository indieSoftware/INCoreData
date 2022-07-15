import CoreData
@testable import INCoreData
import XCTest

class CoreDataManagerTests: XCTestCase {
	var coreDataManager: CoreDataManagerLogic!
	var persistentContainerMock: PersistentContainerMock!

	override func setUpWithError() throws {
		try super.setUpWithError()

		persistentContainerMock = try XCTUnwrap(PersistentContainerMock())
		coreDataManager = CoreDataManagerLogic(persistentContainer: persistentContainerMock)
	}

	override func tearDownWithError() throws {
		try super.tearDownWithError()

		persistentContainerMock = nil
		coreDataManager = nil
	}

	// MARK: - Tests

	func testLoadStore() throws {
		let callExpectation = expectation(description: "callExpectation")
		persistentContainerMock.loadPersistentStoreMock = {
			callExpectation.fulfill()
		}

		performAsyncThrow {
			try await self.coreDataManager.loadStore()
		}

		waitForExpectations()
	}

	func testMainContext() {
		let callExpectation = expectation(description: "callExpectation")
		persistentContainerMock.viewContextMock = {
			callExpectation.fulfill()
			return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		}

		_ = coreDataManager.mainContext

		waitForExpectations()
	}

	func testCreateNewContext() {
		let callExpectation = expectation(description: "callExpectation")
		persistentContainerMock.createNewContextMock = {
			callExpectation.fulfill()
			return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		}

		_ = coreDataManager.createNewContext()

		waitForExpectations()
	}

	func testPersist() throws {
		let callExpectation = expectation(description: "callExpectation")
		persistentContainerMock.persistMock = {
			callExpectation.fulfill()
		}

		performAsyncThrow {
			try await self.coreDataManager.persist()
		}

		waitForExpectations()
	}
}
