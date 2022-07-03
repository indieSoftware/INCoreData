/// Errors which can occur while creating a CoreDataManager and its persistence stack.
public enum CoreDataManagerError: Error {
	/// The folder for the given path could not be created.
	case storeFolderCouldNotBeCreated(path: String)
	/// The persistent store could not be created at the given path.
	case persistentStoreCouldNotBeCreated(path: String)
}
