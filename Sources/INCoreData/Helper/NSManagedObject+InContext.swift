import CoreData

public extension NSManagedObject {
	/**
	 Get an object from a desired context using the `objectID` which
	 uniquely identifes the `NSManagedObject` through the peristent store.

	 The object with the same ID has to exist in the given context.

	 This method can be used to retrieve a managed object in the background context corresponding
	 to the given object from the main context.

	 Example of usage:
	 ```
	 let project = try! mainContext.fetch(fetch).first! // Project in main context
	 // Get a NSManagedObject that corresponds to the NSManagedObjectID instance
	 // in a different context (here the background context).
	 let projectInBackgroundContext = project.inContext(backgroundContext)
	 ```

	 - parameter context: Context from which to fetch the managed object.
	 - returns: The matching `NSManagedObject`.
	 */
	func inContext(_ context: NSManagedObjectContext) -> Self {
		guard let newObject = context.object(with: objectID) as? Self else {
			fatalError("None or unexpected object type received for '\(String(describing: Self.self))'")
		}
		return newObject
	}
}
