import CoreData

// This is not a struct to have a compile-time hint when not exhausive
// and to get automatically a case iterable conformance.
// An option set will not work well either, because it wouldn't provide
// any real benefit, but would require a raw value which still
// wouldn't match the associated notification key, so we would end up
// again with a switch branch for the mapping and a custom case iterable
// implementation.
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
			NSManagedObjectContext.NotificationKey.insertedObjects.rawValue
		case .deleted:
			NSManagedObjectContext.NotificationKey.deletedObjects.rawValue
		case .updated:
			NSManagedObjectContext.NotificationKey.updatedObjects.rawValue
		}
	}
}

public extension [ManagedObjectChangeType] {
	/// A shorthand accessor for `ManagedObjectChangeType.allCases`
	/// to simplify the parameter for `changeTypes: [ManagedObjectChangeType]`
	/// so that it's possible to directly pass `changeTypes: .allCases`.
	static var allCases: Self { Element.allCases }
}
