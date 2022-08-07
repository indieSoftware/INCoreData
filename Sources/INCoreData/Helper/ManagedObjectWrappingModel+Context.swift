import CoreData

public extension ManagedObjectWrappingModel where ManagedObject.Model == Self {
	/// Returns a new model with the wrapped managed object retrieved from the given context.
	/// - parameter context: The context in which to retrieve the model's managed object.
	/// - returns: The new model for the new managed object.
	func inContext(_ context: NSManagedObjectContext) -> Self {
		managedObject.inContext(context).asModel
	}

	/// Inserts the model's wrapped managed object into its persist store on save.
	/// The managed object must have a context assigned.
	func addToContext() {
		guard let context = managedObject.managedObjectContext else {
			preconditionFailure("Managed object has no context")
		}
		context.insert(managedObject)
	}

	/// Deletes the model's wrapped manager object from its persistent store on save.
	/// The managed object must have a context assigned.
	func removeFromContext() {
		guard let context = managedObject.managedObjectContext else {
			preconditionFailure("Managed object has no context")
		}
		context.delete(managedObject)
	}
}
