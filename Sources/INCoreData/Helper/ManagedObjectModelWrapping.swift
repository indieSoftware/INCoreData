import CoreData

/// Extend a managed object to conform to this protocol to get an automatic wrapping model for it.
public protocol ManagedObjectModelWrapping {
	associatedtype Model: ManagedObjectWrappingModel

	/// Returns a corresponding model which wraps this managed object.
	var asModel: Model { get }
}

public extension ManagedObjectModelWrapping where
	Self: NSManagedObject,
	Model: ManagedObjectWrappingModel,
	Model.ManagedObject == Self
{ // swiftlint:disable:this opening_brace
	/// Wraps the managed object into a model which acts as a facade
	/// to provide a better interface to the managed object.
	var asModel: Model {
		Model(managedObject: self)
	}
}
