import CoreData

public extension ManagedObjectWrappingModel where ManagedObject.Model == Self {
	/**
	 Appends the given model to the sorted list.

	 - parameter model: The model to add.
	 - parameter managedObjectAddingMethod: The method on the `managedObject` to call to add a relationship.
	 - parameter listIndexKeyPath: A writeable key-path to the model's list index to update its index.
	 - parameter listCountKeyPath: A key-path to a property which returns the count of the list in a non-looping way.
	 */
	func addModel<Model: ManagedObjectWrappingModel>(
		_ model: Model,
		managedObjectAddingMethod: (Model.ManagedObject) -> Void,
		listIndexKeyPath: ReferenceWritableKeyPath<Model, Int>,
		listCountKeyPath: KeyPath<Self, Int>
	) {
		// Just append the new object.
		managedObjectAddingMethod(model.managedObject)
		model[keyPath: listIndexKeyPath] = self[keyPath: listCountKeyPath] - 1
	}

	/**
	 Removes a given model from the list.

	 - warning: The model's managed object gets removed from the relationship list, but not from the persistent store.
	 You still have to call `model.removeFromContext()` if you want to delete it from the persistent store on save.

	 - parameter model: The model to remove.
	 - parameter managedObjectRemovingMethod: The method on the `managedObject` to call to remove a relationship.
	 - parameter listIndexKeyPath: A writeable key-path to the model's list index to update its index.
	 - parameter listKeyPath: A key-path to a property which returns the list of the model's managed objects.
	 */
	func removeModel<Model: ManagedObjectWrappingModel>(
		_ model: Model,
		managedObjectRemovingMethod: (Model.ManagedObject) -> Void,
		listIndexKeyPath: ReferenceWritableKeyPath<Model, Int>,
		listKeyPath: KeyPath<ManagedObject, NSSet?>
	) where Model == Model.ManagedObject.Model {
		// Decrement index of all following objects.
		let modelIndex = model[keyPath: listIndexKeyPath]
		guard let objectSet = managedObject[keyPath: listKeyPath] else {
			preconditionFailure("No set")
		}
		objectSet.forEach { object in
			guard let mappedObject = object as? Model.ManagedObject else {
				preconditionFailure("Not matching managed object in set: \(object)")
			}
			let mappedObjectModel: Model = mappedObject.asModel
			if mappedObjectModel[keyPath: listIndexKeyPath] > modelIndex {
				mappedObjectModel[keyPath: listIndexKeyPath] -= 1
			}
		}

		// Finally remove the object.
		managedObjectRemovingMethod(model.managedObject)
	}

	/**
	 Inserts the given model into the list at a specific position.

	 - parameter model: The model to insert.
	 - parameter index: The zero-based index at which position to add the model.
	 - parameter managedObjectAddingMethod: The method on the `managedObject` to call to add a relationship.
	 - parameter listIndexKeyPath: A writeable key-path to the model's list index to update its index.
	 - parameter listKeyPath: A key-path to a property which returns the list of the model's managed objects.
	 */
	func insertModel<Model: ManagedObjectWrappingModel>(
		_ model: Model,
		index: Int,
		managedObjectAddingMethod: (Model.ManagedObject) -> Void,
		listIndexKeyPath: ReferenceWritableKeyPath<Model, Int>,
		listKeyPath: KeyPath<ManagedObject, NSSet?>
	) where Model == Model.ManagedObject.Model {
		// Add first the object to respect any constraints.
		managedObjectAddingMethod(model.managedObject)
		model[keyPath: listIndexKeyPath] = index

		// Increase the index of all other objects from the index position.
		guard let objectSet = managedObject[keyPath: listKeyPath] else {
			preconditionFailure("No set")
		}
		objectSet.forEach { object in
			guard let mappedObject = object as? Model.ManagedObject else {
				preconditionFailure("Not matching managed object in set: \(object)")
			}
			let mappedObjectModel: Model = mappedObject.asModel
			if mappedObjectModel[keyPath: listIndexKeyPath] >= index, mappedObjectModel != model {
				mappedObjectModel[keyPath: listIndexKeyPath] += 1
			}
		}
	}
}
