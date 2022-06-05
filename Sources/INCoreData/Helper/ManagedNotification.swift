import CoreData

/// The notification emitted by a managed object.
public struct ManagedNotification {
	let name: Notification.Name
}

public extension ManagedNotification {
	/// A notification that posts when the managed object has changed, e.g. in a different context.
	/// This is triggered immediately when the object has changed,
	/// thus no context save or so is necessary.
	static let objectChanged = ManagedNotification(name: NSManagedObjectContext.didChangeObjectsNotification)

	/// A notification that posts when the context completes a save.
	/// This is triggered only when the context has saved,
	/// thus not immediately when an object just has changed.
	static let contextSaved = ManagedNotification(name: NSManagedObjectContext.didSaveObjectsNotification)
}
