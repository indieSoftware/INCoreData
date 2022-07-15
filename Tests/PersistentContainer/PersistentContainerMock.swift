import CoreData
@testable import INCoreData
import XCTest

class PersistentContainerMock: PersistentContainer {
	init() throws {
		try super.init(name: TestModel.name, bundle: Bundle(for: Self.self), inMemory: true)
	}

	// MARK: - viewContext

	override var viewContext: NSManagedObjectContext {
		viewContextMock()
	}

	var viewContextMock: () -> NSManagedObjectContext = {
		XCTFail()
		return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
	}

	var viewContextSuper: NSManagedObjectContext {
		super.viewContext
	}

	// MARK: - loadPersistentStore

	override func loadPersistentStore() async throws {
		loadPersistentStoreMock()
	}

	var loadPersistentStoreMock: () -> Void = { XCTFail() }

	func loadPersistentStoreSuper() async throws {
		try await super.loadPersistentStore()
	}

	// MARK: - createNewContext

	override func createNewContext() -> NSManagedObjectContext {
		createNewContextMock()
	}

	var createNewContextMock: () -> NSManagedObjectContext = {
		XCTFail()
		return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
	}

	func createNewContextSuper() -> NSManagedObjectContext {
		super.createNewContext()
	}

	// MARK: - persist

	override func persist() async throws {
		try await persistMock()
	}

	var persistMock: () async throws -> Void = { XCTFail() }

	func persistSuper() async throws {
		try await super.persist()
	}
}
