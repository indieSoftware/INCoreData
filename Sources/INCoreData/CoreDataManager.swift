import CoreData
import Foundation

public protocol CoreDataManager {
	/// This is the main MOC and acts as the "Single Source of Truth".
	/// It will run on the main queue, however it's encouraged to create a new background context via `createNewContext`
	/// for background tasks and sync all changes later back to the main context via `persist(fromBackgroundContext:)`.
	/// The UI will reference this MOC for anything it needs.
	var mainContext: NSManagedObjectContext { get }

	/**
	 Creates a new managed object context of the main context.
	 The new MOC is intended to be used on a background thread.

	 This can be used to create a new MOC for work on a background task
	 which will then later saved back to the main context.

	 - returns: The new background MOC.
	 */
	func createNewContext() -> NSManagedObjectContext

	/**
	 Saves the main context synchronously.

	 No matter how many MOCs have been created, all changes will funnel through
	 the main context and thus persist through this method.
	 */
	func persist()

	/**
	 Saves the content of the background context synchronously back into the main context and persists it.

	 - parameter backgroundContext: The background context which to save back to the main context.
	 */
	func persist(fromBackgroundContext backgroundContext: NSManagedObjectContext) throws
}
