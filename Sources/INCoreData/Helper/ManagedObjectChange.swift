import CoreData

/// The published event when a managed object might change.
public struct ManagedObjectChange<ManagedObjectType: NSManagedObject> {
	/// The managed object which has been changed.
	public let object: ManagedObjectType
	/// The type of change.
	public let type: ManagedObjectChangeType
}

/// The published event when multiple managed objects might change.
public struct ManagedObjectsChange<ManagedObjectType: NSManagedObject> {
	/// The managed objects which have been changed.
	public let objects: [ManagedObjectType]
	/// The type of change.
	public let type: ManagedObjectChangeType
}
