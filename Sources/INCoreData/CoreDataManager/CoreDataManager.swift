import CoreData
import Foundation

/**
 A manager for CoreData which acts as a facade for the `PersistentContainer`.

 Usually `CoreDataManagerLogic` should be instantiated as an implementation of this protocol.

 The wrapped `PersistentContainer` is a `NSPersistentCloudKitContainer` with some
 additional functionalities to streamline the usage of Core Data with this manager.
 The protocol makes it possible to inject the manager to all dependents and replace it with
 a mocked version for unit tests and SwiftUI previews.
 For this only methods provided by this manager should be used instead of the underlying container.
 */
public protocol CoreDataManager {
	/**
	 Loads the persistent store.

	 Has to be called once as part of the set up before interacting with the Core Data stack.

	 - throws: A `CoreDataManagerError` when loading the container failed.
	 */
	func loadStore() async throws

	/**
	 A reference to the `viewContext` for tasks on the main context.

	 This context acts on the main thread and thus is also used by the UI.
	 Keep any operations on this one as few as possible
	 and consider applying them on a new background context instead if possible.

	 For this use `createNewContext()` or `performTask(_:)`.
	 */
	var mainContext: NSManagedObjectContext { get }

	/**
	 Creates a new managed object context for background tasks.

	 The new MOC is intended to be used on a background thread
	 and has its parent set to be the main context.

	 To save any changes back to the main context just call `save` directly on the new context.
	 Use  `saveContext(_:)` on the main context to persist any previously saved changes.

	 - returns: The new background MOC.
	 */
	func createNewContext() -> NSManagedObjectContext

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
	func persist() async throws

	/**
	 Executes a task block on a new background context and persists any changes.

	 This is a shorthand convenience method to create a new background context,
	 perform any async changes on it, then save it back to the main context
	 and performing save on the main context to persist any changes.
	 */
	func performTask(_ task: @escaping (NSManagedObjectContext) throws -> Void) async throws
}
