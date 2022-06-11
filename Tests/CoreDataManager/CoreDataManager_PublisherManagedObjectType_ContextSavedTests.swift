import Combine
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObjectType_ContextSavedTests: XCTestCase {
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
		waitForExpectations(timeout: 1)

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

	func testUpdatePublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = ManagedObjectChangeType.allCases
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdateNotPublishedOnContextSavedWhenNotListeningForUpdates() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .inserted]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdateNotPublishedOnContextSavedWhenPersistNotCalled() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		// No persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipSet() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persist()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.barRelationship?.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.addToBarRelationship(barObject)
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipNSSetSet() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persist()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.barRelationship?.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.addToBarRelationship([barObject])
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipRemoved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		fooObject.addToBarRelationship(barObject)
		coreDataManager.persist()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.barRelationship?.count, 0)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		barObject.fooRelationship = nil
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnContextSavedWhenPersistingBackgroundContext() throws {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createNewContext()
		let fooOnBackground = fooObject.inContext(backgroundContext)

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooOnBackground.title = newTitle
		try coreDataManager.persist(fromBackgroundContext: backgroundContext)

		waitForExpectations(timeout: 1)
	}

	func testUpdateNotPublishedOnContextSavedWhenNotPersistingBackgroundContext() throws {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createNewContext()
		let fooOnBackground = fooObject.inContext(backgroundContext)

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooOnBackground.title = newTitle
		// no persist(fromBackgroundContext: backgroundContext)

		waitForExpectations(timeout: 1)
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
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .inserted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, newObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
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
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		// no persist()

		waitForExpectations(timeout: 1)
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
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .inserted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, newObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	// MARK: - deleted

	func testDeletedPublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .deleted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	func testDeletedNotPublishedOnContextSavedWhenNotPersist() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .deleted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		// no persist()

		waitForExpectations(timeout: 1)
	}

	func testDeletedPublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated, .deleted, .inserted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			XCTAssertEqual(managedObjectsChange.type, .deleted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		coreDataManager.persist()

		waitForExpectations(timeout: 1)
	}

	// MARK: - Multi-changes

	func testUpdatedInsertedAndDeletedPublishedInCorrectOrderOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = ManagedObjectChangeType.allCases.shuffled()
		let newTitle = "FooBar"

		// Add an object to delete.
		let deleteObject = Foo(context: coreDataManager.mainContext)
		deleteObject.title = UUID().uuidString
		deleteObject.number = 2
		coreDataManager.mainContext.insert(deleteObject)
		coreDataManager.persist()

		// Prepare object to insert.
		let insertObject = Foo(context: coreDataManager.mainContext)
		insertObject.title = UUID().uuidString
		insertObject.number = 3

		var publishedChanges = [ManagedObjectChangeType]()

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 3
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			publishedChanges.append(managedObjectsChange.type)
			// Verify each change.
			switch managedObjectsChange.type {
			case .deleted:
				XCTAssertEqual(managedObjectsChange.objects.count, 1)
				let changedObject = managedObjectsChange.objects[0]
				XCTAssertEqual(changedObject.objectID, deleteObject.objectID)
			case .inserted:
				XCTAssertEqual(managedObjectsChange.objects.count, 1)
				let changedObject = managedObjectsChange.objects[0]
				XCTAssertEqual(changedObject.objectID, insertObject.objectID)
			case .updated:
				XCTAssertEqual(managedObjectsChange.objects.count, 1)
				let changedObject = managedObjectsChange.objects[0]
				XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			}
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		// Perform changes, but only persist emits the events to the publisher.
		coreDataManager.mainContext.delete(deleteObject)
		coreDataManager.mainContext.insert(insertObject)
		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations(timeout: 1)

		// Verify that all three changes have been emitted in correct order.
		XCTAssertEqual(changeTypes, publishedChanges)
	}

	func testOnlyRegisteredEventsArePublishedOnContextSavedEvenWhenMultipleOfSameType() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated, .inserted]
		let newTitle = "FooBar"

		// Add an object to delete.
		let deleteObject = Foo(context: coreDataManager.mainContext)
		deleteObject.title = UUID().uuidString
		deleteObject.number = 2
		coreDataManager.mainContext.insert(deleteObject)
		coreDataManager.persist()

		// Prepare object to insert.
		let insertObject = Foo(context: coreDataManager.mainContext)
		insertObject.title = UUID().uuidString
		insertObject.number = 3

		// Prepare second object to insert.
		let insertObject2 = Foo(context: coreDataManager.mainContext)
		insertObject2.title = UUID().uuidString
		insertObject2.number = 4

		var publishedChanges = [ManagedObjectChangeType]()

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 2 // Only 2 events are published
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChange in
			publishedChanges.append(managedObjectsChange.type)
			// Verify each change.
			switch managedObjectsChange.type {
			case .deleted:
				XCTFail("We are not registerd of delete events!")
			case .inserted:
				XCTAssertEqual(managedObjectsChange.objects.count, 2)
				let changedObject = managedObjectsChange.objects[0]
				XCTAssertEqual(changedObject.objectID, insertObject.objectID)
				let changedObject2 = managedObjectsChange.objects[1]
				XCTAssertEqual(changedObject2.objectID, insertObject2.objectID)
			case .updated:
				XCTAssertEqual(managedObjectsChange.objects.count, 1)
				let changedObject = managedObjectsChange.objects[0]
				XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			}
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		// Perform changes, but only persist emits the events to the publisher.
		coreDataManager.mainContext.delete(deleteObject)
		coreDataManager.mainContext.insert(insertObject)
		coreDataManager.mainContext.insert(insertObject2)
		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations(timeout: 1)

		// Verify that all three changes have been emitted in correct order.
		XCTAssertEqual(changeTypes, publishedChanges)
	}
}
