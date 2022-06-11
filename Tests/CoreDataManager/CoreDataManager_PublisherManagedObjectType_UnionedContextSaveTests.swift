import Combine
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObjectType_UnionedContextSaveTests: XCTestCase {
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

	func testUpdatePublished() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations()
	}

	func testUpdatePublishedWhenListeningAlsoForOtherChanges() {
		let changeTypes: [ManagedObjectChangeType] = ManagedObjectChangeType.allCases
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations()
	}

	func testNothingPublishedWhenNotListeningForUpdates() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .inserted]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations()
	}

	func testUpdateNotPublishedWhenPersistNotCalled() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
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

	func testUpdatePublishedWhenRelationshipSet() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persist()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.barRelationship?.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.addToBarRelationship(barObject)
		coreDataManager.persist()

		waitForExpectations()
	}

	func testUpdatePublishedWhenRelationshipNSSetSet() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		let barObject = Bar(context: coreDataManager.mainContext)
		barObject.name = UUID().uuidString
		coreDataManager.persist()

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.barRelationship?.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.addToBarRelationship([barObject])
		coreDataManager.persist()

		waitForExpectations()
	}

	func testUpdatePublishedWhenRelationshipRemoved() {
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
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.barRelationship?.count, 0)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		barObject.fooRelationship = nil
		coreDataManager.persist()

		waitForExpectations()
	}

	func testUpdatePublishedWhenPersistingBackgroundContext() throws {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createNewContext()
		let fooOnBackground = fooObject.inContext(backgroundContext)

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .updated)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooOnBackground.title = newTitle
		try coreDataManager.persist(fromBackgroundContext: backgroundContext)

		waitForExpectations()
	}

	func testUpdateNotPublishedWhenNotPersistingBackgroundContext() throws {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let backgroundContext = coreDataManager.createNewContext()
		let fooOnBackground = fooObject.inContext(backgroundContext)

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
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

	func testInsertedPublished() {
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .inserted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, newObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persist()

		waitForExpectations()
	}

	func testInsertedNotPublishedWhenNotPersist() {
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

	func testInsertedPublishedWhenListeningAlsoForOtherChanges() {
		let changeTypes: [ManagedObjectChangeType] = [.inserted, .deleted, .updated]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .inserted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, newObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)
		coreDataManager.persist()

		waitForExpectations()
	}

	// MARK: - deleted

	func testDeletedPublished() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .deleted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		coreDataManager.persist()

		waitForExpectations()
	}

	func testDeletedNotPublishedWhenNotPersist() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .deleted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		// no persist()

		waitForExpectations()
	}

	func testDeletedPublishedWhenListeningAlsoForOtherChanges() {
		let changeTypes: [ManagedObjectChangeType] = [.updated, .deleted, .inserted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 1)
			let managedObjectsChange = managedObjectsChanges[0]
			XCTAssertEqual(managedObjectsChange.type, .deleted)
			XCTAssertEqual(managedObjectsChange.objects.count, 1)
			let changedObject = managedObjectsChange.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)
		coreDataManager.persist()

		waitForExpectations()
	}

	// MARK: - Multi-changes

	func testUpdatedInsertedAndDeletedPublished() {
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

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 1
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 3)
			let changedObject1 = managedObjectsChanges[0]
			XCTAssertEqual(changedObject1.type, changeTypes[0])
			XCTAssertEqual(changedObject1.objects.count, 1)
			let changedObject2 = managedObjectsChanges[1]
			XCTAssertEqual(changedObject2.type, changeTypes[1])
			XCTAssertEqual(changedObject2.objects.count, 1)
			let changedObject3 = managedObjectsChanges[2]
			XCTAssertEqual(changedObject3.type, changeTypes[2])
			XCTAssertEqual(changedObject3.objects.count, 1)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		// Perform changes, but only persist emits the event to the publisher.
		coreDataManager.mainContext.delete(deleteObject)
		coreDataManager.mainContext.insert(insertObject)
		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations()
	}

	func testOnlyRegisteredEventsArePublishedEvenWhenMultipleOfSameType() {
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

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 1
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.mainContext,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectsChanges in
			XCTAssertEqual(managedObjectsChanges.count, 2)

			// Updated
			let changedObject1 = managedObjectsChanges[0]
			XCTAssertEqual(changedObject1.type, changeTypes[0])
			XCTAssertEqual(changedObject1.objects.count, 1)
			let changedObject = changedObject1.objects[0]
			XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)

			// Inserted
			let changedObject2 = managedObjectsChanges[1]
			XCTAssertEqual(changedObject2.type, changeTypes[1])
			XCTAssertEqual(changedObject2.objects.count, 2)

			XCTAssertEqual(changedObject2.objects.count, 2)
			let containsInsertedObject1 = changedObject2.objects.contains { $0.objectID == insertObject.objectID }
			XCTAssertTrue(containsInsertedObject1)
			let containsInsertedObject2 = changedObject2.objects.contains { $0.objectID == insertObject2.objectID }
			XCTAssertTrue(containsInsertedObject2)

			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		// Perform changes, but only persist emits the events to the publisher.
		coreDataManager.mainContext.delete(deleteObject)
		coreDataManager.mainContext.insert(insertObject)
		coreDataManager.mainContext.insert(insertObject2)
		fooObject.title = newTitle
		coreDataManager.persist()

		waitForExpectations()
	}
}
