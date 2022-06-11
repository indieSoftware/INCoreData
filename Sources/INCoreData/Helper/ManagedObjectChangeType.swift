import CoreData

public enum ManagedObjectChangeType: Equatable, CaseIterable {
	/// An object has been added to a context.
	case inserted
	/// An object has been deleted from a context.
	case deleted
	/// An object has been modified / changed.
	case updated

	var notificationKey: String {
		switch self {
		case .inserted:
			return NSManagedObjectContext.NotificationKey.insertedObjects.rawValue
		case .deleted:
			return NSManagedObjectContext.NotificationKey.deletedObjects.rawValue
		case .updated:
			return NSManagedObjectContext.NotificationKey.updatedObjects.rawValue
		}
	}
}
