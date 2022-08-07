import CoreData

public extension ManagedObjectWrappingModel where ManagedObject.Model == Self {
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
