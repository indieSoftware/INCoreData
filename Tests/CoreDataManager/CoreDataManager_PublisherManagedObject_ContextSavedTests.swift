import Combine
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObject_ContextSavedTests: XCTestCase {
	private var coreDataManager: CoreDataManager!
	private var subscriptions = Set<AnyCancellable>()
	private var fooObject: Foo!

	override func setUp() {
		super.setUp()
		subscriptions.removeAll()

		let setupExpectation = expectation(description: "setupExpectation")
		coreDataManager = CoreDataManagerLogic(
			dataModelName: TestModel.name,
			bundle: Bundle(for: Self.self),
			completion: { _, _, _, _ in
				setupExpectation.fulfill()
			}
		)
		waitForExpectations()

		// Add initial object to the main context.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 1
		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persistMainContext()
		fooObject = newObject
	}

	override func tearDown() {
		super.tearDown()
		subscriptions.removeAll()
		coreDataManager = nil
	}

	// MARK: - updated

	func testUpdatePublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = .allCases
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testUpdateNotPublishedOnContextSavedWhenNotListeningForUpdates() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .inserted]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testUpdateNotPublishedOnContextSavedWhenPersistNotCalled() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		// No persist()

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipSet() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persistMainContext()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.barRelationship?.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.addToBarRelationship(barObject)
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipNSSetSet() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persistMainContext()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.barRelationship?.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.addToBarRelationship([barObject])
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipRemoved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		fooObject.addToBarRelationship(barObject)
		coreDataManager.persistMainContext()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.barRelationship?.count, 0)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		barObject.fooRelationship = nil
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSavedWhenPersistingBackgroundContext() throws {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createBackgroundContext()
		let fooOnBackground = fooObject.inContext(backgroundContext)

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooOnBackground.title = newTitle
		try coreDataManager.persist(backgroundContext: backgroundContext)

		waitForExpectations()
	}

	func testUpdateNotPublishedOnContextSavedWhenNotPersistingBackgroundContext() throws {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createBackgroundContext()
		let fooOnBackground = fooObject.inContext(backgroundContext)

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooOnBackground.title = newTitle
		// no persist(fromBackgroundContext: backgroundContext)

		waitForExpectations()
	}

	// MARK: - inserted

	func testInsertedPublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: newObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .inserted)
			XCTAssertEqual(managedObjectChange.object.objectID, newObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testInsertedNotPublishedOnContextSavedWhenNotPersist() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: newObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		// no persist()

		waitForExpectations()
	}

	func testInsertedPublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.inserted, .deleted, .updated]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: newObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .inserted)
			XCTAssertEqual(managedObjectChange.object.objectID, newObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	// MARK: - deleted

	func testDeletedPublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .deleted)
			XCTAssertEqual(managedObjectChange.object.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		coreDataManager.persistMainContext()

		waitForExpectations()
	}

	func testDeletedNotPublishedOnContextSavedWhenNotPersist() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .deleted)
			XCTAssertEqual(managedObjectChange.object.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		// no persist()

		waitForExpectations()
	}

	func testDeletedPublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated, .deleted, .inserted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooObject,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .deleted)
			XCTAssertEqual(managedObjectChange.object.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		coreDataManager.persistMainContext()

		waitForExpectations()
	}
}
