/// Errors which can occur while creating a CoreDataManager and its persistence stack.
public enum CoreDataManagerError: Error {
	case storeFolderCouldNotBeCreated(path: String)
	case persistentStoreCouldNotBeCreated(path: String)
}
