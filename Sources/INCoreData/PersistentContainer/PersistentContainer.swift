import CoreData

/**
 The underlying persistent container which derives from `NSPersistentCloudKitContainer` to support iCloud sharing.
 */
public class PersistentContainer: NSPersistentCloudKitContainer, @unchecked Sendable {
	/// The directory's name of the persistent store, where the SQLite DB has to be written to.
	/// Any provided name will be treated as a relative path from the app's document folder.
	/// When `nil` then the default path will be used which is directly the app's document folder.
	/// Has to be set before calling `loadPersistentStores()`.
	nonisolated(unsafe) static var persistentStoreDirectoryName: String?

	/// Returns the location of the directory that contains the persistent stores.
	override open class func defaultDirectoryURL() -> URL {
		guard let pathComponent = persistentStoreDirectoryName else {
			return super.defaultDirectoryURL()
		}
		return super.defaultDirectoryURL().appendingPathComponent(pathComponent)
	}

	/// Flag to sync the scheme with CloudKit during loading the persistent store.
	private let syncSchemeWithCloudKit: Bool

	/**
	 Initializes the container.

	 If the store should be put into a sub-folder of the documents folder then assign
	 a value to `persistentStoreDirectoryName`.
	 To finalize the container's setup call `try await loadPersistentStores()`.

	 - parameter name: The model's name, which should be the `xcdatamodel` in the project.
	 - parameter bundle: The bundle where the data model can be found, defaults to the main bundle.
	 - parameter inMemory: Set to `true` when an in-memory store should be used, e.g. for UnitTests.
	 Defaults to `false` to have a persistent SQLite store in the app's document folder.
	 - parameter syncSchemeWithCloudKit: Set to `true` to sync the scheme
	 with CloutKit during loading the persistent store.
	 Will only be respected in a debug build for a non-in-memory store.
	 Defaults to `false`.
	 - throws: A `CoreDataManagerError` when initializing the container failed.
	 */
	public init(
		name: String,
		bundle: Bundle = .main,
		inMemory: Bool = false,
		syncSchemeWithCloudKit: Bool = false
	) throws {
		guard let modelUrl = bundle.url(forResource: name, withExtension: "momd") else {
			throw CoreDataManagerError.modelNotFound
		}
		guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
			throw CoreDataManagerError.modelNotReadable
		}
		self.syncSchemeWithCloudKit = inMemory ? false : syncSchemeWithCloudKit
		super.init(name: name, managedObjectModel: model)

		try configureStoreDescriptions(inMemory: inMemory)
	}

	/**
	 Configures the first store description found.

	 - parameter inMemory: Provide `true` to use an in-memory store, otherwise `false`.
	 */
	private func configureStoreDescriptions(inMemory: Bool) throws {
		guard let storeDescription = persistentStoreDescriptions.first else {
			throw CoreDataManagerError.noDefaultStoreConfigurationFound
		}

		if inMemory {
			// According to WWDC 2018 an in-memory store should point to /dev/null:
			// https://developer.apple.com/videos/play/wwdc2018/224/?time=1838
			storeDescription.url = URL(fileURLWithPath: "/dev/null")
			// When using an in-memory store a migration is never happening,
			// therefore, we can do it synchronously.
			storeDescription.shouldAddStoreAsynchronously = false
		} else {
			// The store should be loaded asynchronously so that any migration
			// happens on the background and doesn't block the UI.
			storeDescription.shouldAddStoreAsynchronously = true
		}
	}

	/**
	 Loads the persistent store.

	 Has to be called as part of the set up before interacting with the Core Data stack.

	 This calls `loadPersistentStores(completionHandler:)`.
	 */
	func loadPersistentStore() async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			self.loadPersistentStores { (description: NSPersistentStoreDescription, error: Error?) in
				if let error {
					/*
					 Typical reasons for an error here include:
					 - The parent directory does not exist, cannot be created, or disallows writing.
					 - The persistent store is not accessible, due to permissions or data protection when the device is locked.
					 - The device is out of space.
					 - The store could not be migrated to the current model version.

					 Check the error message to determine what the actual problem was.
					 */
					continuation
						.resume(
							throwing: CoreDataManagerError
								.loadingPersistentStoreFailed(description.description, error)
						)
					return
				}
				// Make sure the local stack gets updated when any changes in iCloud happens.
				self.viewContext.automaticallyMergesChangesFromParent = true
#if DEBUG
				if self.syncSchemeWithCloudKit {
					do {
						// Initialize the development schema (debug build only).
						try self.initializeCloudKitSchema(options: [])
					} catch {
						continuation
							.resume(throwing: CoreDataManagerError.initializeCloudKitSchemaFailed(error))
						return
					}
				}
#endif
				continuation.resume(with: Result.success(()))
			}
		}
	}

	/**
	 Creates a new managed object context for background tasks.
	 The new MOC is intended to be used on a background thread
	 and has its parent set to be the main context (`viewContext`).

	 - returns: The new background MOC.
	 */
	func createNewContext() -> NSManagedObjectContext {
		let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		newContext.parent = viewContext
		newContext.automaticallyMergesChangesFromParent = true

		return newContext
	}

	/**
	 Saves any changes of the main context.

	 The save is wrapped by an async `perform(_:)` call on the main context.
	 Use this method to save a context which received some changes from a child context's save.
	 Usually saving a background context leads to unsaved changes on the main context, thus,
	 to persist those changes either call `save` on the main context or use this method.

	 Does nothing if the context has no pending changes.
	 */
	func persist() async throws {
		let context = viewContext
		try await context.perform {
			guard context.hasChanges else { return }
			try context.save()
		}
	}
}
