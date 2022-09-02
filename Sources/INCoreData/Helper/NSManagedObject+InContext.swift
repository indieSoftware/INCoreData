import CoreData

public extension NSManagedObject {
	/**
	 Get an object from a desired context using the `objectID` which
	 uniquely identifes the `NSManagedObject` through the peristent store.

	 If the object with the same ID does not exist in the given context then a fault one will be returned.

	 This method can be used to retrieve a managed object in the background context corresponding
	 to the given object from the main context.

	 Example of usage:
	 ```
	  await backgroundContext.perform {
	    let objectInBackgroundContext = objectInMainContext.inContext(backgroundContext)
	    // do something with `objectInBackgroundContext`
	  }
	 ```

	 - parameter context: Context from which to fetch the managed object.
	 - returns: The matching `NSManagedObject`.
	 */
	func inContext(_ context: NSManagedObjectContext) -> Self {
		guard let newObject = context.object(with: objectID) as? Self else {
			fatalError("Unexpected object type received for '\(String(describing: Self.self))'")
		}
		return newObject
	}
}
