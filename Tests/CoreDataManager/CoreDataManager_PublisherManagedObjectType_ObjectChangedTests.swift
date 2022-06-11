import Combine
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObjectType_ObjectChangedTests: XCTestCase {
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

	func testUpdatePublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations(timeout: 1)
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForUpdates() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations(timeout: 1)
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForCorrectType() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Bar.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		fooObject.title = newTitle

		waitForExpectations(timeout: 1)
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

		waitForExpectations(timeout: 1)
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

		waitForExpectations(timeout: 1)
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

		waitForExpectations(timeout: 1)
	}

	func testUpdatePublishedOnObjectChangedWhenSavingChangesOnBackgrdoundContext() throws {
		let notificationType = ManagedNotification.objectChanged
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
		try backgroundContext.save()

		waitForExpectations(timeout: 1)
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
		// no backgroundContext.save()

		waitForExpectations(timeout: 1)
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

		waitForExpectations(timeout: 1)
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

		waitForExpectations(timeout: 1)
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForCorrectType() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		let newObject = Foo(context: coreDataManager.mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 2

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Bar.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.insert(newObject)

		waitForExpectations(timeout: 1)
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

		waitForExpectations(timeout: 1)
	}

	// MARK: - deleted

	func testDeletedPublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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

		waitForExpectations(timeout: 1)
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForDeletion() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

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

		coreDataManager.mainContext.delete(fooObject)

		waitForExpectations(timeout: 1)
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForCorrectType() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Bar.self,
			context: coreDataManager.mainContext,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		coreDataManager.mainContext.delete(fooObject)

		waitForExpectations(timeout: 1)
	}

	func testDeletedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .updated, .inserted]

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

		waitForExpectations(timeout: 1)
	}
}
