import Combine
import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObjectType_ObjectChangedTests: XCTestCase {
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

	func testUpdatePublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.fooObject.title = newTitle
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.fooObject.title = newTitle
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForUpdates() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.fooObject.title = newTitle
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForCorrectType() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Bar.self,
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
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipSet() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.fooObject.addToBarRelationship(barObject)
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipNSSetSet() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.fooObject.addToBarRelationship([barObject!])
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipRemoved() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			try await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
				self.fooObject.addToBarRelationship(barObject)
				try self.context.save()
				XCTAssertEqual(self.fooObject.barRelationship?.count, 1)
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
			await self.context.perform {
				barObject.fooRelationship = nil
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenSavingChangesOnBackgroundContext() throws {
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

		performAsyncThrow {
			try await self.context.perform {
				self.fooObject.title = newTitle
				try self.context.save()
			}
		}

		waitForExpectations()
	}

	func testNoUpdatePublishedOnObjectChangedWhenPersistOnDifferentContext() throws {
		let notificationType = ManagedNotification.objectChanged
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

	// MARK: - inserted

	func testInsertedPublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.context.insert(newObject)
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForInsertion() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = []

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
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForCorrectType() {
		let notificationType = ManagedNotification.objectChanged
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
			managedObjectType: Bar.self,
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
			}
		}

		waitForExpectations()
	}

	func testInsertedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .updated, .inserted]

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
			await self.context.perform {
				self.context.insert(newObject)
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenListeningOnDifferentContext() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.context.insert(newObject)
			}
		}

		waitForExpectations()
	}

	// MARK: - deleted

	func testDeletedPublishedOnObjectChanged() {
		let notificationType = ManagedNotification.objectChanged
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
			await self.context.perform {
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForDeletion() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

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
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForCorrectType() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObjectType: Bar.self,
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
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted, .updated, .inserted]

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
			await self.context.perform {
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenListeningOnDifferentContext() {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

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
			await self.context.perform {
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}
}
