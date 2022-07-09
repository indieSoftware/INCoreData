import CoreData
import Foundation

/**
 A manager for CoreData.

 The idea is to have two contexts managed by this manager.
 One main context which runs on the main thread, is accessible by the UI
 and towards which all queries goes.
 And a second background context not accessible by outside of the manager.
 The purpose of the hidden background context is to persist all changes done to the main context.
 So, the main context itself is not persisting anything and
 thus doesn't do such a heavy work on the main thread.
 Instead it syncs itself into the background context which then
 persists the changes asynchronously in the background.
 */
public protocol CoreDataManager {
	/// This is the main MOC and acts as the "Single Source of Truth".
	/// It will run on the main queue, however it's encouraged to create a new background context via `createNewContext`
	/// for background tasks and sync all changes later back to the main context via `persist(fromBackgroundContext:)`.
	/// The UI will reference this MOC for anything it needs.
	var mainContext: NSManagedObjectContext { get }

	/**
	 Saves the main context synchronously by syncing any changes to the hidden background context.
	 After that a save request is queried for the background context to finally persist the changes.
	 */
	func persistMainContext()

	/**
	 Creates a new managed object context of the main context.
	 The new MOC is intended to be used on a background thread.

	 This can be used to create a new MOC for work on a background task
	 which will then later saved back to the main context.

	 - returns: The new background MOC.
	 */
	func createBackgroundContext() -> NSManagedObjectContext

	/**
	 Saves the content of the background context synchronously back into the main context
	 and requests the main context to persist it.

	 The background context's parent has to be the `mainContext`.
	 This is automatically the case when `createBackgroundContext` is used to create the background context.
	 Has to be called on the same thread where the new context has been created.

	 - parameter backgroundContext: The background context which to save back to the main context.
	 */
	func persist(backgroundContext: NSManagedObjectContext) throws
}
