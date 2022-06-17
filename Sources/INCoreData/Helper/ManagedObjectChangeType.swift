import CoreData

// This is not a struct to have a compile-time hint when not exchausive
// and to get automatically a case iterable conformance.
// An option set will not work well because it prevents the associated value
// of the notification key.
public enum ManagedObjectChangeType: Equatable, CaseIterable {
	/// An object has been added to a context.
	case inserted
	/// An object has been deleted from a context.
	case deleted
	/// An object has been modified / changed.
	case updated

	/// The `NSManagedObjectContext.NotificationKey`'s raw value used
	/// to retrieve the managed objects from a notification's userInfo dictionary.
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
