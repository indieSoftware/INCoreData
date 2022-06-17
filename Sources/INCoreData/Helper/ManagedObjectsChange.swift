import CoreData

/// The published event when multiple managed objects might change.
public struct ManagedObjectsChange<ManagedObjectType: NSManagedObject> {
	/// The managed objects which have been changed.
	public let objects: [ManagedObjectType]
	/// The type of change.
	public let type: ManagedObjectChangeType
}
