import Combine
import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObjectType_UnionedContextSaveTests: XCTestCase {
	private var coreDataManager: CoreDataManagerLogic!
	private var subscriptions = Set<AnyCancellable>()
	private var fooObject: Foo!
	private var context: NSManagedObjectContext!

	override func setUpWithError() throws {
		try super.setUpWithError()
		subscriptions.removeAll()

		coreDataManager = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			// Prepare manager.
			try await self.coreDataManager.loadStore()

			// Add initial object to the main context.
			try await self.coreDataManager.performTask { context in
				let newObject = Foo(context: context)
				newObject.title = UUID().uuidString
				newObject.number = 1
				context.insert(newObject)

				self.fooObject = newObject
				self.context = context
			}
		}
	}

	override func tearDownWithError() throws {
		weak var weakManager: CoreDataManagerLogic? = coreDataManager
		weak var weakContainer: NSPersistentContainer? = coreDataManager.container
		weak var weakFooObject: Foo? = fooObject
		weak var weakContext: NSManagedObjectContext? = context

		subscriptions.removeAll()
		fooObject = nil
		coreDataManager = nil
		context = nil

		// Prevents flaky tests
		yieldProcess()

		XCTAssertNil(weakManager)
		XCTAssertNil(weakFooObject)
		XCTAssertNil(weakContainer)
		XCTAssertNil(weakContext)

		try super.tearDownWithError()
	}

	// MARK: - updated

	func testUpdatePublished() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedWhenListeningAlsoForOtherChanges() {
		let changeTypes: [ManagedObjectChangeType] = .allCases
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testNothingPublishedWhenNotListeningForUpdates() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .inserted]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedWhenPersistNotCalled() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		performAsyncThrow {
			await self.context.perform {
				self.fooObject.title = newTitle
				// no try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedWhenPersistOnDifferentContext() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.createNewContext(),
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedWhenRelationshipSet() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			try await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
				try self.context.save()
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.addToBarRelationship(barObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedWhenRelationshipNSSetSet() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			try await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
				try self.context.save()
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.addToBarRelationship([barObject!])
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedWhenRelationshipRemoved() {
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			try await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
				self.fooObject.addToBarRelationship(barObject)
				try self.context.save()
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				barObject.fooRelationship = nil
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedWhenPersistingBackgroundContext() throws {
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
			try await self.coreDataManager.persist()
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedWhenNotPersistingBackgroundContext() throws {
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
			// no try await self.coreDataManager.persist()
		}

		waitForExpectations()
	}

	// MARK: - inserted

	func testInsertedPublished() {
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		var newObject: Foo!
		performAsyncThrow {
			await self.context.perform {
				newObject = Foo(context: self.context)
				newObject.title = UUID().uuidString
				newObject.number = 2
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.insert(newObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedWhenNotPersist() {
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		var newObject: Foo!
		performAsyncThrow {
			await self.context.perform {
				newObject = Foo(context: self.context)
				newObject.title = UUID().uuidString
				newObject.number = 2
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		performAsyncThrow {
			await self.context.perform {
				self.context.insert(newObject)
				// no try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testInsertedPublishedWhenListeningAlsoForOtherChanges() {
		let changeTypes: [ManagedObjectChangeType] = [.inserted, .deleted, .updated]

		// Prepare new object.
		var newObject: Foo!
		performAsyncThrow {
			await self.context.perform {
				newObject = Foo(context: self.context)
				newObject.title = UUID().uuidString
				newObject.number = 2
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.insert(newObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedWhenPersistOnDifferentContext() {
		let changeTypes: [ManagedObjectChangeType] = [.inserted]

		// Prepare new object.
		var newObject: Foo!
		performAsyncThrow {
			await self.context.perform {
				newObject = Foo(context: self.context)
				newObject.title = UUID().uuidString
				newObject.number = 2
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.createNewContext(),
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		performAsyncThrow {
			try await self.context.perform {
				self.context.insert(newObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	// MARK: - deleted

	func testDeletedPublished() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedWhenNotPersist() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			await self.context.perform {
				self.context.delete(self.fooObject)
				// no try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testDeletedPublishedWhenListeningAlsoForOtherChanges() {
		let changeTypes: [ManagedObjectChangeType] = [.updated, .deleted, .inserted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedWhenPersistOnDifferentContext() {
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.createNewContext(),
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	// MARK: - Multi-changes

	func testUpdatedInsertedAndDeletedPublished() {
		let changeTypes: [ManagedObjectChangeType] = .allCases.shuffled()
		let newTitle = "FooBar"

		var deleteObject: Foo!
		var insertObject: Foo!
		performAsyncThrow {
			try await self.context.perform {
				// Add an object to delete.
				deleteObject = Foo(context: self.context)
				deleteObject.title = UUID().uuidString
				deleteObject.number = 2
				self.context.insert(deleteObject)

				// Prepare object to insert.
				insertObject = Foo(context: self.context)
				insertObject.title = UUID().uuidString
				insertObject.number = 3

				try self.context.save()
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 1
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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
		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(deleteObject)
				self.context.insert(insertObject)
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testOnlyRegisteredEventsArePublishedEvenWhenMultipleOfSameType() {
		let changeTypes: [ManagedObjectChangeType] = [.updated, .inserted]
		let newTitle = "FooBar"

		var deleteObject: Foo!
		var insertObject: Foo!
		var insertObject2: Foo!
		performAsyncThrow {
			try await self.context.perform {
				// Add an object to delete.
				deleteObject = Foo(context: self.context)
				deleteObject.title = UUID().uuidString
				deleteObject.number = 2
				self.context.insert(deleteObject)

				// Prepare object to insert.
				insertObject = Foo(context: self.context)
				insertObject.title = UUID().uuidString
				insertObject.number = 3

				// Prepare second object to insert.
				insertObject2 = Foo(context: self.context)
				insertObject2.title = UUID().uuidString
				insertObject2.number = 4

				try self.context.save()
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 1
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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
		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(deleteObject)
				self.context.insert(insertObject)
				self.context.insert(insertObject2)
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}
}
