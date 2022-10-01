import Combine
import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObject_ContextSavedTests: XCTestCase {
	private var coreDataManager: CoreDataManager!
	private var subscriptions = Set<AnyCancellable>()
	private var fooObject: Foo!
	private var context: NSManagedObjectContext!

	override func setUpWithError() throws {
		try super.setUpWithError()
		subscriptions.removeAll()

		coreDataManager = CoreDataManager(
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
		weak var weakManager: CoreDataManager? = coreDataManager
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
			managedObject: fooObject,
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
			managedObject: fooObject,
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

		var fooOnMain: Foo!
		let mainContext = coreDataManager.mainContext
		performAsyncThrow {
			await mainContext.perform {
				fooOnMain = self.fooObject.inContext(mainContext)
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooOnMain,
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.title, newTitle)
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

		var fooOnMain: Foo!
		let mainContext = coreDataManager.mainContext
		performAsyncThrow {
			await mainContext.perform {
				fooOnMain = self.fooObject.inContext(mainContext)
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: fooOnMain,
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
			managedObject: newObject,
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

		performAsyncThrow {
			try await self.context.perform {
				self.context.delete(self.fooObject)
				try self.context.save()
			}
		}

		waitForExpectations()
	}
}
