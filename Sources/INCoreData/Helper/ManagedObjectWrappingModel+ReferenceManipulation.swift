import CoreData

public extension ManagedObjectWrappingModel where Self == ManagedObject.Model {
	/**
	 Removes a model's index by decrementing the index of all following models.

	 - warning: This doesn't remove the model from the list nor deletes it,
	 this has to be done manually after calling this method.

	 - parameter models: The list of models which contains this model and where
	 the other model's index has to be decremented.
	 - parameter indexKeyPath: A key-path to the model's index value.
	 - parameter indexSetter: A setter method which to call to set the new index on a model.
	 */
	func removeIndex(
		fromModels models: [Self],
		indexKeyPath: KeyPath<Self, Int>,
		indexSetter: (Self) -> (Int) throws -> Void
	) throws {
		for model in models {
			let objectIndex = model[keyPath: indexKeyPath]
			if objectIndex > self[keyPath: indexKeyPath] {
				try indexSetter(model)(objectIndex - 1)
			}
		}
	}

	/**
	 Inserts a new model's index into the list of models.

	 - warning: The object needs to be added to the relationship manually before calling this method.

	 - parameter index: The zero-based index at which position to add the model.
	 - parameter models: The list of models which also contains this object, but where the index has to be updated.
	 - parameter indexKeyPath: A key-path to the model's index value.
	 - parameter indexSetter: A setter method which to call to set the new index on a model.
	 */
	func insertIndex(
		index: Int,
		intoModels models: [Self],
		indexKeyPath: KeyPath<Self, Int>,
		indexSetter: (Self) -> (Int) throws -> Void
	) throws {
		try indexSetter(self)(index)
		for model in models {
			let objectIndex = model[keyPath: indexKeyPath]
			if model[keyPath: indexKeyPath] >= index, model != self {
				try indexSetter(model)(objectIndex + 1)
			}
		}
	}
}
