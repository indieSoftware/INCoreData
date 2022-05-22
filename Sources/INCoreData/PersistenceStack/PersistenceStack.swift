import CoreData

protocol PersistenceStack {
	/// This is the main MOC which runs on the main queue.
	var mainContext: NSManagedObjectContext { get }

	/**
	 Saves the main context synchronously.
	 */
	func persist()

	/**
	 Creates a new managed object context of the main context.
	 The new MOC is intended to be used on a background thread.

	 - returns: The new background MOC.
	 */
	func createNewContext() -> NSManagedObjectContext
}
