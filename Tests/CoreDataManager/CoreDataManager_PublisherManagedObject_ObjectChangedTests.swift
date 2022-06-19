import Combine
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObject_ObjectChangedTests: XCTestCase {
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
		coreDataManager.persist()
		fooObject = newObject
	}

	override func tearDown() {
		super.tearDown()
		subscriptions.removeAll()
		coreDataManager = nil
	}

	// MARK: - updated

	func testUpdatePublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations()
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForUpdates() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations()
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForCorrectInstance() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2
		coreDataManager.mainContext.insert(newObject)

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

		fooObject.title = newTitle

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipSet() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persist()

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

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipNSSetSet() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persist()

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

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipRemoved() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		fooObject.addToBarRelationship(barObject)
		coreDataManager.persist()
		XCTAssertEqual(fooObject.barRelationship?.count, 1)

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

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenSavingChangesOnBackgrdoundContext() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createNewContext()
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
		try backgroundContext.save()

		waitForExpectations()
	}

	func testNoUpdatePublishedOnObjectChangedWhenNotSavingChangesOnBackgrdoundContext() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createNewContext()
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
		// no backgroundContext.save()

		waitForExpectations()
	}

	// MARK: - inserted

	func testInsertedPublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForInsertion() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = []

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

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForCorrectInstance() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

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

		coreDataManager.mainContext.insert(newObject)

		waitForExpectations()
	}

	func testInsertedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .updated, .inserted]

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

		waitForExpectations()
	}

	// MARK: - deleted

	func testDeletedPublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForDeletion() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

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

		coreDataManager.mainContext.delete(fooObject)

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForCorrectInstance() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2
		coreDataManager.mainContext.insert(newObject)

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

		coreDataManager.mainContext.delete(fooObject)

		waitForExpectations()
	}

	func testDeletedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .updated, .inserted]

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

		waitForExpectations()
	}
}
