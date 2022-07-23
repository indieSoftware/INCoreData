import CoreData
import Foundation

public class CoreDataManagerLogic: CoreDataManager {
	/// The default name of a data model in the bundle, equals to "DataModel".
	public static let defaultDataModelName = "DataModel"

	/// The default folder name of the persistent store in the documents folder, equals to "CoreData".
	public static let defaultStoreDirectoryName = "CoreData"

	/// The underlying persistent container used.
	public private(set) var container: PersistentContainer

	/**
	 Initializes the manager with a persistent container directly, i.e. to use it for unit tests.

	 - parameter persistentContainer: The persistent container to use.
	 */
	init(persistentContainer: PersistentContainer) {
		container = persistentContainer
	}

	/**
	 Instantiates the manager.

	 This will set the store directory name `PersistentContainer.persistentStoreDirectoryName`
	 and instantiate an instance of `PersistentContainer`.

	 - parameter name: The name of the CoreData model which is the file name of the `xcdatamodeld` without extension.
	 - parameter bundle: The bundle where to find the data model. Defaults to the main bundle.
	 - parameter storeDirectoryName: The directory's name of the persistent store,
	 where the SQLite DB has to be written to.
	 Any provided name will be treated as a relative path from the app's document folder.
	 When `nil` then the default path will be used which is directly the app's document folder.
	 - parameter inMemory: Pass true to use an in-memory store suitable for Previews and UnitTests,
	 rather than a "real" one. Defaults to `false`.
	 - throws: A `PersistentContainerError` when initializing the container failed.
	 */
	public init(
		name: String = CoreDataManagerLogic.defaultDataModelName,
		bundle: Bundle = .main,
		storeDirectoryName: String? = CoreDataManagerLogic.defaultStoreDirectoryName,
		inMemory: Bool = false
	) throws {
		PersistentContainer.persistentStoreDirectoryName = storeDirectoryName
		container = try PersistentContainer(name: name, bundle: bundle, inMemory: inMemory)
	}

	// MARK: - CoreDataManager interface

	public func loadStore() async throws {
		try await container.loadPersistentStore()
	}

	public var mainContext: NSManagedObjectContext {
		container.viewContext
	}

	public func createNewContext() -> NSManagedObjectContext {
		container.createNewContext()
	}

	public func persist() async throws {
		try await container.persist()
	}

	public func performTask(_ task: @escaping (NSManagedObjectContext) throws -> Void) async throws {
		let context = createNewContext()
		try await context.perform {
			try task(context)
			if context.hasChanges {
				try context.save()
			}
		}
		try await persist()
	}
}
