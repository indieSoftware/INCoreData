import CoreData

/// A protocol to mark `Model`s so that they can be used by a managed object
/// which conforms to `ManagedObjectModelWrapping` to automatically wrap them.
/// A model should conform to this protocol to act as a facade for the wrapped managed object.
/// The idea is to provide a better and type-safe interface with a model to the managed object.
public protocol ManagedObjectWrappingModel: Equatable {
	associatedtype ManagedObject: NSManagedObject

	/// The reference property pointing to the wrapped managed object.
	var managedObject: ManagedObject { get }

	/// An initialized which takes the matching managed object and assigns it to the reference property.
	init(managedObject: ManagedObject)
}

public extension ManagedObjectWrappingModel {
	/// Returns true if the objectID of the wrapped managed objects
	/// of the two wrapping models are the same, otherwise false.
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.managedObject.objectID == rhs.managedObject.objectID
	}
}
