import Combine
import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherManagedObject_ObjectChangedTests: XCTestCase {
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

	func testUpdatePublishedOnObjectChanged() throws {
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

		performAsyncThrow {
			await self.context.perform {
				self.fooObject.title = newTitle
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenListeningAlsoForOtherChanges() throws {
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

		performAsyncThrow {
			await self.context.perform {
				self.fooObject.title = newTitle
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForUpdates() throws {
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

		performAsyncThrow {
			await self.context.perform {
				self.fooObject.title = newTitle
			}
		}

		waitForExpectations()
	}

	func testUpdateNotPublishedOnObjectChangedWhenNotListeningForCorrectInstance() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		// Prepare new object.
		var newObject: Foo!
		performAsyncThrow {
			await self.context.perform {
				newObject = Foo(context: self.context)
				newObject.title = UUID().uuidString
				newObject.number = 2
				self.context.insert(newObject)
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: newObject, // not listening on fooObject
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

	func testUpdatePublishedOnObjectChangedWhenRelationshipSet() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
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
			await self.context.perform {
				self.fooObject.addToBarRelationship(barObject)
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipNSSetSet() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
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
			await self.context.perform {
				self.fooObject.addToBarRelationship([barObject!])
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectChangedWhenRelationshipRemoved() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]

		// Add new object for relationship
		var barObject: Bar!
		performAsyncThrow {
			await self.context.perform {
				barObject = Bar(context: self.context)
				barObject.name = UUID().uuidString
				self.fooObject.addToBarRelationship(barObject)
				XCTAssertEqual(self.fooObject.barRelationship?.count, 1)
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
			await self.context.perform {
				barObject.fooRelationship = nil
			}
		}

		waitForExpectations()
	}

	func testUpdatePublishedOnObjectOnMainContextChangedWhenSavingChangesOnBackgrdound() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		// Get foo object on main context.
		let mainContext = coreDataManager.mainContext
		var fooOnMain: Foo!
		performAsyncThrow {
			await mainContext.perform {
				fooOnMain = self.fooObject.inContext(mainContext)
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		coreDataManager.publisher(
			managedObject: fooOnMain, // foo on main context
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { managedObjectChange in
			XCTAssertEqual(managedObjectChange.type, .updated)
			XCTAssertEqual(managedObjectChange.object.title, newTitle)
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		// Change on background.
		let backgroundContext = coreDataManager.createNewContext()
		performAsyncThrow {
			try await backgroundContext.perform {
				let fooOnBackground = self.fooObject.inContext(backgroundContext)
				fooOnBackground.title = newTitle
				try backgroundContext.save()
			}
		}

		waitForExpectations()
	}

	func testNoUpdatePublishedOnObjectChangedWhenNotSavingChangesOnBackgrdoundContext() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.updated]
		let newTitle = "FooBar"

		// Get foo object on main context.
		let mainContext = coreDataManager.mainContext
		var fooOnMain: Foo!
		performAsyncThrow {
			await mainContext.perform {
				fooOnMain = self.fooObject.inContext(mainContext)
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.isInverted = true
		coreDataManager.publisher(
			managedObject: fooOnMain, // foo on main context
			notificationType: notificationType,
			changeTypes: changeTypes
		)
		.sink(receiveValue: { _ in
			publishExpectation.fulfill()
		})
		.store(in: &subscriptions)

		// Change on background.
		let backgroundContext = coreDataManager.createNewContext()
		performAsyncThrow {
			await backgroundContext.perform {
				let fooOnBackground = self.fooObject.inContext(backgroundContext)
				fooOnBackground.title = newTitle
				// no try backgroundContext.save()
			}
		}

		waitForExpectations()
	}

	// MARK: - inserted

	func testInsertedPublishedOnObjectChanged() throws {
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
			await self.context.perform {
				self.context.insert(newObject)
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForInsertion() throws {
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
			}
		}

		waitForExpectations()
	}

	func testInsertedNotPublishedOnObjectChangedWhenNotListeningForCorrectInstance() throws {
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
				self.context.insert(newObject)
			}
		}

		waitForExpectations()
	}

	func testInsertedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() throws {
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
			await self.context.perform {
				self.context.insert(newObject)
			}
		}

		waitForExpectations()
	}

	// MARK: - deleted

	func testDeletedPublishedOnObjectChanged() throws {
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

		performAsyncThrow {
			await self.context.perform {
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForDeletion() throws {
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

		performAsyncThrow {
			await self.context.perform {
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedNotPublishedOnObjectChangedWhenNotListeningForCorrectInstance() throws {
		let notificationType = ManagedNotification.objectChanged
		let changeTypes: [ManagedObjectChangeType] = [.deleted]

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
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}

	func testDeletedPublishedOnObjectChangedWhenListeningAlsoForOtherChanges() throws {
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

		performAsyncThrow {
			await self.context.perform {
				self.context.delete(self.fooObject)
			}
		}

		waitForExpectations()
	}
}
