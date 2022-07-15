import CoreData

/// Programmer errors which can be thrown while creating a `PersistentContainer`.
public enum PersistentContainerError: Error {
	/// The model's "momd" resource couldn't be found in the bundle.
	/// Probably the "xcdatamodel" file hasn't been added to the project.
	case modelNotFound
	/// The model couldn't be loaded.
	/// Probably the bundle's model file is corrupt.
	case modelNotReadable
	/// The underlying `NSPersistentStore` should provide at least
	/// one `persistentStoreDescriptions`, but actually doesn't.
	case noDefaultStoreConfigurationFound
	/// Loading the persistent store failed.
	/// This happens by the underlying `loadPersistentStores(completionHandler:)` call
	/// and contains the return values by that method.
	case loadingPersistentStoreFailed(_ description: NSPersistentStoreDescription, _ error: Error)
}
