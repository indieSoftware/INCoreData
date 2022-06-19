import CoreData
import Foundation

public class CoreDataManagerLogic: CoreDataManager {
	/// The default name of a data model, equals "DataModel".
	public static let defaultDataModelName = "DataModel"

	/// The used persinstence stack which handles the main and the background context.
	private var persistenceStack: PersistenceStack?

	/**
	 Default initializer of the manager which does nothing.

	 Before using the manager the `setup` method must be called once.
	 */
	public init() {}

	/**
	 Sets up this mananger with a persistence stack on disk.

	 This must be called exactly once and before calling any other methods of the manager.
	 Calling this method will create the necessary folders and files for persistence and
	 potentially migrate any previous stores if necessary.
	 That might take some unpredictable time, so call this method in the life-cycle of the app
	 when it's appropriate for the user to wait for some time, i.e. when showing a splash screen.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file,
	 e.g. "DataModel".
	 - parameter bundle: The bundle where to find the data model, e.g. "main".
	 - parameter storeFolder: The relative folder path where to persist the store.
	 Usually this will be a new sub-folder in the documents folder.
	 The folder doesn't have to exist and will be created automatically.
	 - parameter completion: The completion block which will be called on the main thread
	 when the stack has been initialized and any data model potentially migrated.
	 The returned `Result` will indicate a success when the model could be created or a failure with the error.
	 */
	public func setup(
		dataModelName: String = defaultDataModelName,
		bundle: Bundle = .main,
		storeFolder: URL,
		completion: @escaping (Result<Void, CoreDataManagerError>) -> Void
	) {
		precondition(persistenceStack == nil, "This method should only be called once")
		persistenceStack = PersistenceStackLogic(
			dataModelName: dataModelName,
			bundle: bundle,
			storeFolder: storeFolder,
			completion: completion
		)
	}

	/**
	 Alternative initializer to use an in-memory persistence stack
	 suitable for Previews or UnitTests of apps using this library.

	 This initializer already sets up the manager, therefore, calling `setup` is not necessary and even forbidden.
	 It should only be used to inject an in-memory manager.
	 It's not intended to use this for productive code.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file.
	 - parameter bundle: The bundle where to find the data model. Default to the main bundle.
	 - parameter completion: The completion handler which gets called when the in-memory store has been created
	 and can be used.
	 - parameter persistentStoreCoordinator: The created persistent store coordinator.
	 - parameter mainContext: The created main context.
	 - parameter privateContext: The created private background context.
	 - parameter container: The created container.
	 */
	public convenience init(
		dataModelName: String = defaultDataModelName,
		bundle: Bundle = .main,
		completion: @escaping (
			_ persistentStoreCoordinator: NSPersistentStoreCoordinator,
			_ mainContext: NSManagedObjectContext,
			_ privateContext: NSManagedObjectContext,
			_ container: NSPersistentContainer
		) -> Void
	) {
		self.init()
		persistenceStack = PersistenceStackLogic(
			dataModelName: dataModelName,
			bundle: bundle,
			completion: completion
		)
	}

	/**
	 Alternative initializer to assign a persistence stack directly, i.e. for UnitTests of this module.

	 - parameter persistenceStack: The persistence stack to use, i.e. a mock.
	 */
	init(persistenceStack: PersistenceStack) {
		self.persistenceStack = persistenceStack
	}

	public var mainContext: NSManagedObjectContext {
		guard let persistenceStack = persistenceStack else {
			preconditionFailure("'setup' hasn't been called")
		}
		return persistenceStack.mainContext
	}

	public func createNewContext() -> NSManagedObjectContext {
		guard let persistenceStack = persistenceStack else {
			preconditionFailure("'setup' hasn't been called")
		}
		return persistenceStack.createNewContext()
	}

	public func persist() {
		guard let persistenceStack = persistenceStack else {
			preconditionFailure("'setup' hasn't been called")
		}
		return persistenceStack.persist()
	}

	public func persist(fromBackgroundContext backgroundContext: NSManagedObjectContext) throws {
		precondition(backgroundContext.parent == mainContext)
		try backgroundContext.save()
		persist()
	}
}
