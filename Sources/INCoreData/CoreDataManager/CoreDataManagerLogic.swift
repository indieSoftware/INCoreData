import CoreData
import Foundation

public class CoreDataManagerLogic: CoreDataManager {
	/// The default name of a data model in the bundle, equals to "DataModel".
	public static let defaultDataModelName = "DataModel"

	/// The default folder name of the persistent store in the documents folder, equals to "CoreData".
	public static let defaultStoreDirectoryName = "CoreData"

	/// The underlying persistent container used.
	public private(set) var container: PersistentContainer?

	/// The parameters for the persistent container for passing later during the loading rather the init.
	private let persistentContainerParameter: PersistentContainerParameter?

	/**
	 Initializes the manager with a persistent container directly, i.e. to use it for unit tests.

	 - parameter persistentContainer: The persistent container to use.
	 */
	init(persistentContainer: PersistentContainer) {
		persistentContainerParameter = nil
		container = persistentContainer
	}

	/**
	 Instantiates the manager.

	 This will set the store directory name `PersistentContainer.persistentStoreDirectoryName`
	 and instantiate an instance of `PersistentContainer`.

	 To finish the initialization `loadStore()` has to be called once before the manager can be used.

	 - parameter name: The name of the CoreData model which is the file name of the `xcdatamodeld` without extension.
	 - parameter bundle: The bundle where to find the data model. Defaults to the main bundle.
	 - parameter storeDirectoryName: The directory's name of the persistent store,
	 where the SQLite DB has to be written to.
	 Any provided name will be treated as a relative path from the app's document folder.
	 When `nil` then the default path will be used which is directly the app's document folder.
	 - parameter inMemory: Pass true to use an in-memory store suitable for Previews and UnitTests,
	 rather than a "real" one. Defaults to `false`.
	 - parameter syncSchemeWithCloudKit: Set to `true` to sync the scheme with CloutKit during loading the persistent store.
	 Will only be respected in a debug build for a non-in-memory store.
	 Defaults to `false`.
	 */
	public init(
		name: String = CoreDataManagerLogic.defaultDataModelName,
		bundle: Bundle = .main,
		storeDirectoryName: String? = CoreDataManagerLogic.defaultStoreDirectoryName,
		inMemory: Bool = false,
		syncSchemeWithCloudKit: Bool = false
	) {
		PersistentContainer.persistentStoreDirectoryName = storeDirectoryName
		persistentContainerParameter = PersistentContainerParameter(
			modelName: name,
			modelBundle: bundle,
			inMemory: inMemory,
			syncSchemeWithCloudKit: syncSchemeWithCloudKit
		)
	}

	// MARK: - CoreDataManager interface

	public func loadStore() async throws {
		if let parameter = persistentContainerParameter {
			guard container == nil else {
				throw CoreDataManagerError.multipleLoadStoreCalls
			}
			// Default state where the public init-method has been called
			// and this is the first call of `loadStore()`.
			container = try PersistentContainer(
				name: parameter.modelName,
				bundle: parameter.modelBundle,
				inMemory: parameter.inMemory
			)
		} else {
			precondition(container != nil, "Impossible state")
			// The internal init-method has been called,
			// so a container exists already and we can simply proceed.
		}

		guard let container = container else {
			preconditionFailure("Impossible state")
		}
		try await container.loadPersistentStore()
	}

	public var mainContext: NSManagedObjectContext {
		guard let container = container else {
			preconditionFailure("No container, call loadStore() first")
		}
		return container.viewContext
	}

	public func createNewContext() -> NSManagedObjectContext {
		guard let container = container else {
			preconditionFailure("No container, call loadStore() first")
		}
		return container.createNewContext()
	}

	public func persist() async throws {
		guard let container = container else {
			preconditionFailure("No container, call loadStore() first")
		}
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
