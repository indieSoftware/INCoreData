import Combine
import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObjectType_ContextSavedTests: XCTestCase {
	private var coreDataManager: CoreDataManagerLogic!
	private var subscriptions = Set<AnyCancellable>()
	private var fooObject: Foo!
	private var context: NSManagedObjectContext!

	override func setUpWithError() throws {
		try super.setUpWithError()
		subscriptions.removeAll()

		coreDataManager = try CoreDataManagerLogic(
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
		subscriptions.removeAll()
		coreDataManager = nil
		fooObject = nil
		context = nil
		try super.tearDownWithError()
	}

	// MARK: - updated

	func testUpdatePublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = .allCases
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedOnContextSavedWhenNotListeningForUpdates() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .inserted]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
			notificationType: notificationType,
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

	func testUpdateNotPublishedOnContextSavedWhenPersistNotCalled() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
			notificationType: notificationType,
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

	func testUpdateNotPublishedOnContextSavedWhenPersistOnDifferentContext() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.createNewContext(),
			notificationType: notificationType,
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

	func testUpdatePublishedOnContextSaveWhenRelationshipSet() {
		let notificationType = ManagedNotification.contextSaved
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.addToBarRelationship(barObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipNSSetSet() {
		let notificationType = ManagedNotification.contextSaved
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.addToBarRelationship([barObject!])
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSaveWhenRelationshipRemoved() {
		let notificationType = ManagedNotification.contextSaved
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

		performAsyncThrow {
			try await self.context.perform {
				barObject.fooRelationship = nil
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnContextSavedWhenPersistingBackgroundContext() throws {
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
			try await self.coreDataManager.persist()
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedOnContextSavedWhenNotPersistingBackgroundContext() throws {
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

	func testInsertedPublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.insert(newObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnContextSavedWhenNotPersist() {
		let notificationType = ManagedNotification.contextSaved
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
			notificationType: notificationType,
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

	func testInsertedPublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.insert(newObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnContextSavedWhenPersistOnDifferentContext() {
		let notificationType = ManagedNotification.contextSaved
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
			notificationType: notificationType,
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

	func testDeletedPublishedOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnContextSavedWhenNotPersist() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			await self.context.perform {
				self.context.delete(self.fooObject)
				// no try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testDeletedPublishedOnContextSavedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.updated, .deleted, .inserted]

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnContextSavedWhenPersistOnDifferentContext() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: coreDataManager.createNewContext(),
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	// MARK: - Multi-changes

	func testUpdatedInsertedAndDeletedPublishedInCorrectOrderOnContextSaved() {
		let notificationType = ManagedNotification.contextSaved
		let changeTypes: [ManagedObjectChangeType] = ManagedObjectChangeType.allCases.shuffled()
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

		var publishedChanges = [ManagedObjectChangeType]()

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 3
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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
		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(deleteObject)
				self.context.insert(insertObject)
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()

		// Verify that all three changes have been emitted in correct order.
		XCTAssertEqual(changeTypes, publishedChanges)
	}

	func testOnlyRegisteredEventsArePublishedOnContextSavedEvenWhenMultipleOfSameType() {
		let notificationType = ManagedNotification.contextSaved
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

		var publishedChanges = [ManagedObjectChangeType]()

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 2 // Only 2 events are published
		coreDataManager.publisher(
			managedObjectType: Foo.self,
			context: context,
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
				let containsObject1 = managedObjectsChange.objects.contains { $0.objectID == insertObject.objectID }
				XCTAssertTrue(containsObject1)
				let containsObject2 = managedObjectsChange.objects.contains { $0.objectID == insertObject2.objectID }
				XCTAssertTrue(containsObject2)
			case .updated:
				XCTAssertEqual(managedObjectsChange.objects.count, 1)
				let changedObject = managedObjectsChange.objects[0]
				XCTAssertEqual(changedObject.objectID, self.fooObject.objectID)
			}
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

		// Verify that all three changes have been emitted in correct order.
		XCTAssertEqual(changeTypes, publishedChanges)
	}
}
