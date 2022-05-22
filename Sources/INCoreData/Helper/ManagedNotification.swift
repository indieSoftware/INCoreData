import CoreData

/// The notification emitted by a managed object.
public struct ManagedNotification {
	let name: Notification.Name
}

public extension ManagedNotification {
	/// A notification that posts when the managed object has changed, e.g. in a different context.
	static let objectChanged = ManagedNotification(name: NSManagedObjectContext.didChangeObjectsNotification)

	/// A notification that posts when the context completes a save.
	static let contextSaved = ManagedNotification(name: NSManagedObjectContext.didSaveObjectsNotification)
}
