import CoreData

/// The published event when a managed object might change.
public struct ManagedObjectChange<ManagedObjectType: NSManagedObject> {
	/// The managed object which has been changed.
	public let object: ManagedObjectType
	/// The type of change.
	public let type: ManagedObjectChangeType
}
