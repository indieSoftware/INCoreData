import CoreData
import Foundation

public class CoreDataManagerLogic: CoreDataManager {
	/// The default name of a data model, currently "DataModel".
	public static let defaultDataModelName = "DataModel"

	/// The used persinstence stack which handles the main and the background context.
	private var persistenceStack: PersistenceStack

	/**
	 Initializes the mananger.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file.
	 - parameter bundle: The bundle where to find the data model.
	 - parameter storeFolder: The relative folder path where to persist the store.
	 - parameter completion: The completion block which will be called on the main thread
	 when the stack has been initialized and any data model potentially migrated.
	 The returned `Result` will indicate a success when the model could be created or a failure with the error.
	 */
	public init(
		dataModelName: String = defaultDataModelName,
		bundle: Bundle = .main,
		storeFolder: URL,
		completion: @escaping (Result<Void, CoreDataManagerError>) -> Void
	) {
		persistenceStack = PersistenceStackLogic(
			dataModelName: dataModelName,
			bundle: bundle,
			storeFolder: storeFolder,
			completion: completion
		)
	}

	/**
	 Alternative initializer to use an in-memory persistence stack, i.e. for UnitTests.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file.
	 - parameter bundle: The bundle where to find the data model. Default to the main bundle.
	 - parameter completion: The completion handler which gets called when the in-memory store has been created
	 and can be used.
	 */
	public init(
		dataModelName: String = defaultDataModelName,
		bundle: Bundle = .main,
		completion: @escaping () -> Void
	) {
		persistenceStack = PersistenceStackLogic(
			dataModelName: dataModelName,
			bundle: bundle,
			completion: completion
		)
	}

	public var mainContext: NSManagedObjectContext {
		persistenceStack.mainContext
	}

	public func createNewContext() -> NSManagedObjectContext {
		persistenceStack.createNewContext()
	}

	public func persist() {
		persistenceStack.persist()
	}

	public func persist(fromBackgroundContext backgroundContext: NSManagedObjectContext) throws {
		precondition(backgroundContext.parent == mainContext)
		try backgroundContext.save()
		persist()
	}
}
