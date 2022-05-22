import CoreData
@testable import INCoreData
import XCTest

class PersistenceStackLogicTests: XCTestCase {
	var persistenceStack: PersistenceStackLogic!
	var persistentStoreCoordinator: NSPersistentStoreCoordinator!
	var mainContext: NSManagedObjectContext!
	var privateContext: NSManagedObjectContext!
	var container: NSPersistentContainer!

	override func setUp() {
		super.setUp()

		let testModel = testModel()
		container = NSPersistentContainer(name: "InMemoryTestContainer", managedObjectModel: testModel)
		persistentStoreCoordinator = container.persistentStoreCoordinator

		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
		container.persistentStoreDescriptions = [description]

		privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.persistentStoreCoordinator = persistentStoreCoordinator

		mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		mainContext.parent = privateContext

		persistenceStack = PersistenceStackLogic(
			persistentStoreCoordinator: persistentStoreCoordinator,
			mainConext: mainContext,
			privateContext: privateContext
		)

		// The properites are set up, but not ready to use, yet.
		// For that each test method has first to call 'setUpContainer()'
		// and wait for the completion handler to fire.
	}

	/**
	 Loads the persistent store of the container.
	 Needs to be called in each test method before using the test properites.
	 */
	private func setUpContainer() {
		let setupExpectation = expectation(description: "setupExpectation")
		container.loadPersistentStores { _, error in
			if let error = error {
				fatalError("Failed to setup in memory store \(error.localizedDescription)")
			}
			setupExpectation.fulfill()
		}
		waitForExpectations(timeout: 1)
	}

	// MARK: - init

	func testModelGetsMigratedOnInit() {}

	// MARK: - persist

	func testBackgroundAndMainContextGetPersisted() throws {
		setUpContainer()

		// Sanity check that nothing is pending on the contexts and it's empty.
		XCTAssertFalse(mainContext.hasChanges)
		XCTAssertFalse(privateContext.hasChanges)
		XCTAssertEqual(0, try mainContext.fetch(Foo.fetchRequest()).count)

		// Insert new object as a change for the contexts.
		let newObject = Foo(context: mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 1
		mainContext.insert(newObject)

		// Sanity check that a change is pending.
		XCTAssertTrue(mainContext.hasChanges)
		XCTAssertFalse(privateContext.hasChanges)

		// Method under test.
		persistenceStack.persist()

		privateContext.performAndWait {
			// Just wait for the block to be executed to make sure
			// the async changes are applied to the private stack.
		}

		// Verify that changes have been persisted.
		XCTAssertFalse(mainContext.hasChanges)
		XCTAssertFalse(privateContext.hasChanges)

		let foosInMainContext = try mainContext.fetch(Foo.fetchRequest())
		XCTAssertEqual(1, foosInMainContext.count)
		let fooInMainContext = try XCTUnwrap(foosInMainContext.first)
		XCTAssertEqual(newObject.title, fooInMainContext.title)
		XCTAssertEqual(newObject.objectID, fooInMainContext.objectID, "The persisted object ID should match the one from the stack where it is saved")

		let foosInPrivateContext = try privateContext.fetch(Foo.fetchRequest())
		XCTAssertEqual(1, foosInPrivateContext.count)
		let fooInPrivateContext = try XCTUnwrap(foosInPrivateContext.first)
		XCTAssertEqual(newObject.title, fooInPrivateContext.title)
		XCTAssertNotEqual(newObject.objectID, fooInPrivateContext.objectID, "Different contexts have different IDs for their objects")
	}

	func testPersistMethodDoesNotChangeAnythingOnUnchangedContext() throws {
		setUpContainer()

		// Sanity check that nothing is pending on the contexts and it's empty.
		XCTAssertFalse(mainContext.hasChanges)
		XCTAssertFalse(privateContext.hasChanges)
		XCTAssertEqual(0, try mainContext.fetch(Foo.fetchRequest()).count)

		// Method under test.
		persistenceStack.persist()

		privateContext.performAndWait {
			// Just wait for the block to be executed to make sure
			// the async changes are applied to the private stack.
		}

		// Verify nothing has changed.
		XCTAssertFalse(mainContext.hasChanges)
		XCTAssertFalse(privateContext.hasChanges)
		XCTAssertEqual(0, try mainContext.fetch(Foo.fetchRequest()).count)
	}

	// MARK: - createNewContext

	func testNewContextWithMainAsParentGetsReturned() throws {
		setUpContainer()

		// Sanity check that the contexts is empty.
		XCTAssertEqual(0, try mainContext.fetch(Foo.fetchRequest()).count)

		// Method under test.
		let newContext = persistenceStack.createNewContext()

		// Insert new object to the new context.
		let newObject = Foo(context: newContext)
		newObject.title = UUID().uuidString
		newObject.number = 1
		newContext.insert(newObject)
		try newContext.save()

		// Verify that the new object has been saved to the main context through the new context.
		let foosInMainContext = try mainContext.fetch(Foo.fetchRequest())
		XCTAssertEqual(1, foosInMainContext.count)
		let fooInMainContext = try XCTUnwrap(foosInMainContext.first)
		XCTAssertEqual(newObject.title, fooInMainContext.title)
	}

	func testNewObjectGetsPassedToNewContext() throws {
		setUpContainer()

		// Sanity check that the contexts is empty.
		XCTAssertEqual(0, try mainContext.fetch(Foo.fetchRequest()).count)

		// Method under test.
		let newContext = persistenceStack.createNewContext()

		// Insert new object to the main context.
		let newObject = Foo(context: mainContext)
		newObject.title = UUID().uuidString
		newObject.number = 1
		mainContext.insert(newObject)
		try mainContext.save()

		// Verify that the new object has been synced from the main context to the new context.
		let foosInNewContext = try newContext.fetch(Foo.fetchRequest())
		XCTAssertEqual(1, foosInNewContext.count)
		let fooInNewContext = try XCTUnwrap(foosInNewContext.first)
		XCTAssertEqual(newObject.title, fooInNewContext.title)
	}
}
