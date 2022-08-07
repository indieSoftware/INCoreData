import CoreData

public extension ManagedObjectWrappingModel where ManagedObject.Model == Self {
	func addModel<Model: ManagedObjectWrappingModel>(
		_ model: Model,
		addingMethod: (Model.ManagedObject) -> Void,
		indexKeyPath: ReferenceWritableKeyPath<Model, Int>,
		countKeyPath: KeyPath<Self, Int>
	) {
		// Just append the new object.
		addingMethod(model.managedObject)
		model[keyPath: indexKeyPath] = self[keyPath: countKeyPath] - 1
	}

	func removeModel<Model: ManagedObjectWrappingModel>(
		_ model: Model,
		removingMethod: (Model.ManagedObject) -> Void,
		indexKeyPath: ReferenceWritableKeyPath<Model, Int>,
		objectSetKeyPath: KeyPath<ManagedObject, NSSet?>
	) where Model == Model.ManagedObject.Model {
		// Decrement index of all following objects.
		let modelIndex = model[keyPath: indexKeyPath]
		guard let objectSet = managedObject[keyPath: objectSetKeyPath] else {
			preconditionFailure("No set")
		}
		objectSet.forEach { (object: Any) in
			guard let mappedObject = object as? Model.ManagedObject else {
				preconditionFailure("Not matching managed object in set: \(object)")
			}
			let mappedObjectModel: Model = mappedObject.asModel
			if mappedObjectModel[keyPath: indexKeyPath] > modelIndex {
				mappedObjectModel[keyPath: indexKeyPath] -= 1
			}
		}

		// Finally remove the object.
		removingMethod(model.managedObject)
	}

	func insertModel<Model: ManagedObjectWrappingModel>(
		_ model: Model,
		index: Int,
		addingMethod: (Model.ManagedObject) -> Void,
		indexKeyPath: ReferenceWritableKeyPath<Model, Int>,
		objectSetKeyPath: KeyPath<ManagedObject, NSSet?>
	) where Model == Model.ManagedObject.Model {
		// Add first the object to respect any constraints.
		addingMethod(model.managedObject)
		model[keyPath: indexKeyPath] = index

		// Increase the index of all other objects from the index position.
		guard let objectSet = managedObject[keyPath: objectSetKeyPath] else {
			preconditionFailure("No set")
		}
		objectSet.forEach { (object: Any) in
			guard let mappedObject = object as? Model.ManagedObject else {
				preconditionFailure("Not matching managed object in set: \(object)")
			}
			let mappedObjectModel: Model = mappedObject.asModel
			if mappedObjectModel[keyPath: indexKeyPath] >= index, mappedObjectModel != model {
				mappedObjectModel[keyPath: indexKeyPath] += 1
			}
		}
	}
}
