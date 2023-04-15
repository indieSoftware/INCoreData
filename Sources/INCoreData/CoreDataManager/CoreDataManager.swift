import CoreData
import Foundation

/**
 A manager for CoreData which acts as a facade for the `PersistentContainer`.

 The wrapped `PersistentContainer` is a `NSPersistentCloudKitContainer` with some
 additional functionalities to streamline the usage of Core Data with this manager.
 */
public final class CoreDataManager: @unchecked Sendable {
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
	 - parameter syncSchemeWithCloudKit: Set to `true` to sync the scheme with CloutKit
	 during loading the persistent store.
	 Will only be respected in a debug build for a non-in-memory store.
	 Defaults to `false`.
	 */
	public init(
		name: String = CoreDataManager.defaultDataModelName,
		bundle: Bundle = .main,
		storeDirectoryName: String? = CoreDataManager.defaultStoreDirectoryName,
		inMemory: Bool = false,
		syncSchemeWithCloudKit: Bool = false
	) {
		Task {
			await MainActor.run {
				PersistentContainer.persistentStoreDirectoryName = storeDirectoryName
			}
		}
		persistentContainerParameter = PersistentContainerParameter(
			modelName: name,
			modelBundle: bundle,
			inMemory: inMemory,
			syncSchemeWithCloudKit: syncSchemeWithCloudKit
		)
	}

	/**
	 Loads the persistent store.

	 Has to be called once as part of the set up before interacting with the Core Data stack.

	 - throws: A `CoreDataManagerError` when loading the container failed.
	 */
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

		guard let container else {
			preconditionFailure("Impossible state")
		}
		try await container.loadPersistentStore()
	}

	/**
	 A reference to the `viewContext` for tasks on the main context.

	 This context acts on the main thread and thus is also used by the UI.
	 Keep any operations on this one as few as possible
	 and consider applying them on a new background context instead if possible.

	 For this use `createNewContext()` or `performTask(_:)`.
	 */
	public var mainContext: NSManagedObjectContext {
		guard let container else {
			preconditionFailure("No container, call loadStore() first")
		}
		return container.viewContext
	}

	/**
	 Creates a new managed object context for background tasks.

	 The new MOC is intended to be used on a background thread
	 and has its parent set to be the main context.

	 To save any changes back to the main context just call `save` directly on the new context.
	 Use  `saveContext(_:)` on the main context to persist any previously saved changes.

	 - returns: The new background MOC.
	 */
	public func createNewContext() -> NSManagedObjectContext {
		guard let container else {
			preconditionFailure("No container, call loadStore() first")
		}
		return container.createNewContext()
	}

	/**
	 Saves any changes of the main context.

	 The save is wrapped by an async `perform(_:)` call on the main context.
	 Use this method to save a context which received some changes from a child context's save.
	 Usually saving a background context leads to unsaved changes on the main context, thus,
	 to persist those changes either call `save` on the main context or use this method.

	 Does nothing if the context has no pending changes.

	 ```
	 let backgroundContext = manager.createNewContext()
	 try await backgroundContext.perform {
	 let foo = Foo(context: backgroundContext)
	 backgroundContext.insert(foo)
	 try context.save()
	 }
	 manager.saveContext()
	 ```

	 Does nothing if the context has no pending changes.
	 */
	public func persist() async throws {
		guard let container else {
			preconditionFailure("No container, call loadStore() first")
		}
		try await container.persist()
	}

	/**
	 Executes a task block on a new background context and persists any changes.

	 This is a shorthand convenience method to create a new background context,
	 perform any async changes on it, then save it back to the main context
	 and performing save on the main context to persist any changes.
	 */
	public func performTask(_ task: @escaping @Sendable (NSManagedObjectContext) throws -> Void) async throws {
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
