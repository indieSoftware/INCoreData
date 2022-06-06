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

	// MARK: - Multi-changes

	func testUpdatedInsertedAndDeletedPublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ChangeType] = [.updated, .inserted, .deleted]
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
		insertObject.number = 2

		var publishedChanges = [ChangeType]()

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

		// Delete
		coreDataManager.mainContext.delete(deleteObject)

		// Update
		fooObject.title = newTitle

		// Insert
		coreDataManager.mainContext.insert(insertObject)

		// Perform changes which emits the events to the publisher.
		coreDataManager.persist()

		waitForExpectations(timeout: 1)

		// Verify that all three changes have been emitted (updated, inserted and deleted).
		XCTAssertEqual(changeTypes, publishedChanges)
	}

	func testOnlyRegisteredEventsArePublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ChangeType] = [.updated, .inserted]
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
		insertObject.number = 2

		var publishedChanges = [ChangeType]()

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 2
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

		// Delete (negative test)
		coreDataManager.mainContext.delete(deleteObject)

		// Update
		fooObject.title = newTitle

		// Insert
		coreDataManager.mainContext.insert(insertObject)

		// Perform changes which emits the events to the publisher.
		coreDataManager.persist()

		waitForExpectations(timeout: 1)

		// Verify that all three changes have been emitted (updated, inserted and deleted).
		XCTAssertEqual(changeTypes, publishedChanges)
	}
}
