import CoreData

public struct ManagedObjectChangeType: Equatable {
	let notificationKey: String
}

extension ManagedObjectChangeType: CaseIterable {
	public static let allCases: [ManagedObjectChangeType] = [
		.inserted,
		.deleted,
		.updated
	]
}

public extension ManagedObjectChangeType {
	/// An object has been added to a context.
	static let inserted = ManagedObjectChangeType(
		notificationKey: NSManagedObjectContext.NotificationKey.insertedObjects.rawValue
	)
	/// An object has been deleted from a context.
	static let deleted = ManagedObjectChangeType(
		notificationKey: NSManagedObjectContext.NotificationKey.deletedObjects.rawValue
	)
	/// An object has been modified / changed.
	static let updated = ManagedObjectChangeType(
		notificationKey: NSManagedObjectContext.NotificationKey.updatedObjects.rawValue
	)
}
