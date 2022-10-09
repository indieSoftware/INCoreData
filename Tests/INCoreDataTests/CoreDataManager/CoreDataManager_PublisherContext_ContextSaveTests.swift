import Combine
import CoreData
@testable import INCoreData
import XCTest

final class CoreDataManager_PublisherContext_ContextSaveTests: XCTestCase {
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

	// MARK: - Tests

	func testContextChanges() {
		let changeTypes: [ManagedObjectChangeType] = .allCases.shuffled()
		let newTitle = "FooBar"

		var deleteObject: Foo!
		var insertObject: Bar!
		performAsyncThrow {
			try await self.context.perform {
				// Add an object to delete.
				deleteObject = Foo(context: self.context)
				deleteObject.title = UUID().uuidString
				deleteObject.number = 2
				self.context.insert(deleteObject)

				// Prepare object to insert.
				insertObject = Bar(context: self.context)
				insertObject.name = UUID().uuidString

				try self.context.save()
			}
		}

		let publishExpectation = expectation(description: "publishExpectation")
		publishExpectation.expectedFulfillmentCount = 1
		coreDataManager.publisher(
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
}
