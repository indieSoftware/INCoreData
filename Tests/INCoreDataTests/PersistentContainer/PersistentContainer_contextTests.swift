@testable import INCoreData
import XCTest

class PersistentContainer_contextTests: XCTestCase {
	var container: PersistentContainer!

	override func setUpWithError() throws {
		try super.setUpWithError()

		PersistentContainer.persistentStoreDirectoryName = "test"
		try deletePersistentDirectory()

		container = try PersistentContainer(name: TestModel.name, bundle: Bundle(for: Self.self), inMemory: true)
		performAsyncThrow {
			try await self.container.loadPersistentStore()
		}
	}

	override func tearDownWithError() throws {
		container = nil
		try deletePersistentDirectory()

		// Prevents flaky tests
		yieldProcess()

		try super.tearDownWithError()
	}

	private func deletePersistentDirectory() throws {
		let urlPath = PersistentContainer.defaultDirectoryURL().path
		if FileManager.default.fileExists(atPath: urlPath) {
			try FileManager.default.removeItem(atPath: urlPath)
		}
	}

	// MARK: - viewContext

	func testSaveOnMainContext() async throws {
		let context = container.viewContext

		// Insert new object as a change for the contexts.
		let title = UUID().uuidString
		try await context.perform {
			let newObject = Foo(context: context)
			newObject.title = title
			newObject.number = 1
			context.insert(newObject)

			try context.save()
		}

		// Retrieve saved object from context
		try await context.perform {
			let foos = try context.fetch(Foo.fetchRequest())
			XCTAssertEqual(1, foos.count)
			let foo = try XCTUnwrap(foos.first)
			XCTAssertEqual(foo.title, title)
			XCTAssertEqual(foo.number, 1)
		}
	}

	// MARK: - createNewContext

	func testNewBackgroundContextHasNoParent() async throws {
		let newContext = container.newBackgroundContext()
		let parentContext = newContext.parent

		// The new background context has no parent,
		// but is directly associated with the store coordinator.
		XCTAssertNil(parentContext)
	}

	func testCreateNewContextHasParent() async throws {
		let newContext = container.createNewContext()
		let parentContext = newContext.parent

		XCTAssertEqual(parentContext, container.viewContext)
	}

	func testSaveOnBackgroundContextAlsoSavesToMainContext() async throws {
		let context = container.createNewContext()

		// Insert new object as a change for the contexts.
		let title = UUID().uuidString
		try await context.perform {
			let newObject = Foo(context: context)
			newObject.title = title
			newObject.number = 1
			context.insert(newObject)

			try context.save()
		}

		// Retrieve saved object from context
		try await context.perform {
			let foos = try context.fetch(Foo.fetchRequest())
			XCTAssertEqual(1, foos.count)
			let foo = try XCTUnwrap(foos.first)
			XCTAssertEqual(foo.title, title)
			XCTAssertEqual(foo.number, 1)
		}

		// Retrieve saved object from main context
		let mainContext = container.viewContext
		try await mainContext.perform {
			let foos = try mainContext.fetch(Foo.fetchRequest())
			XCTAssertEqual(1, foos.count)
			let foo = try XCTUnwrap(foos.first)
			XCTAssertEqual(foo.title, title)
			XCTAssertEqual(foo.number, 1)
		}
	}

	func testNewObjectSavedToMainContextGetsPassedToBackgroundContext() async throws {
		let context = container.createNewContext()

		// Sanity check that there is no object in the background context.
		try await context.perform {
			let foos = try context.fetch(Foo.fetchRequest())
			XCTAssertEqual(0, foos.count)
		}

		// Insert new object to the main context.
		let title = UUID().uuidString
		let mainContext = container.viewContext
		try await mainContext.perform {
			let newObject = Foo(context: mainContext)
			newObject.title = title
			newObject.number = 1
			mainContext.insert(newObject)

			try mainContext.save()
		}

		// Check that the saved object has been passed to the background context.
		try await context.perform {
			let foos = try context.fetch(Foo.fetchRequest())
			XCTAssertEqual(1, foos.count)
			let foo = try XCTUnwrap(foos.first)
			XCTAssertEqual(foo.title, title)
			XCTAssertEqual(foo.number, 1)
		}
	}

	// MARK: - persist

	func testPersistWithoutChangesDoesNothing() async throws {
		try await container.persist()
	}

	func testPersistSavesMainContextChanges() async throws {
		// Get main context and ensure there are no pending changes on it.
		let mainContext = container.viewContext
		try await mainContext.perform {
			XCTAssertFalse(mainContext.hasChanges)
			let foosInMainContext = try mainContext.fetch(Foo.fetchRequest())
			XCTAssertEqual(0, foosInMainContext.count)
		}

		// Insert new object on a background context.
		let context = container.createNewContext()
		let title = UUID().uuidString
		try await context.perform {
			let newObject = Foo(context: context)
			newObject.title = title
			newObject.number = 1
			context.insert(newObject)
			try context.save()
		}

		// The saved background changes lead to pending changes on the main context.
		try await mainContext.perform {
			XCTAssertTrue(mainContext.hasChanges)

			// Verify that the saved object is really present in the main context.
			let foosInMainContext = try mainContext.fetch(Foo.fetchRequest())
			XCTAssertEqual(1, foosInMainContext.count)
			let fooInMainContext = try XCTUnwrap(foosInMainContext.first)
			XCTAssertEqual(fooInMainContext.title, title)
		}

		try await container.persist()

		// After persist the pending changes on the main context have been saved as well.
		await mainContext.perform {
			XCTAssertFalse(mainContext.hasChanges)
		}
	}
}
