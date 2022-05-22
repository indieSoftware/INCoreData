import CoreData

class PersistenceStackLogic: PersistenceStack {
	/// The coordinator which is used for binding the main MOC with the persistent store.
	private let persistentStoreCoordinator: NSPersistentStoreCoordinator

	/// This is MOC which will run on a private queue so that any saves don't block the UI.
	/// The MOC's responsibility is to handle all presistances, no matter how many other MOCs were created.
	private let privateContext: NSManagedObjectContext

	private(set) var mainContext: NSManagedObjectContext

	/**
	 Initializes the persistence stack.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file.
	 Defaults to "DataModel".
	 - parameter bundle: The bundle where to find the data model.
	 - parameter storeFolder: The relative folder path where to persist the store.
	 - parameter completion: The completion block which will be called on the main thread
	 when the stack has been initialized and any data model potentially migrated.
	 The returned `Result` will indicate a success when the model could be created or a failure with the error.
	 */
	init(
		dataModelName: String,
		bundle: Bundle,
		storeFolder: URL,
		completion: @escaping (Result<Void, CoreDataManagerError>) -> Void
	) {
		guard let modelUrl = bundle.url(forResource: dataModelName, withExtension: "momd"),
		      let objectModel = NSManagedObjectModel(contentsOf: modelUrl)
		else {
			// If the MOM failed to be created then it's a programmer error
			// where the '.xcdatamodeld' file isn't in the provided bundle.
			fatalError("No data model found with name '\(dataModelName)' in bundle '\(bundle.bundlePath)'")
		}

		persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)

		// Creating and setting up the private background MOC.
		let localPrivateMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		localPrivateMoc.persistentStoreCoordinator = persistentStoreCoordinator
		privateContext = localPrivateMoc

		// Create the main MOC on the main queue and make the private MOC its parent.
		// Any changes will automatically be propagated to the background MOC to
		// not block the main thread when persisting the context.
		let localMainMoc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		localMainMoc.parent = privateContext
		mainContext = localMainMoc

		// It's unknown how long it will take to create the store
		// because of potential migrations and we don't want to block the UI,
		// so we do this on a background queue.
		DispatchQueue.global().async { [self] in
			// Make sure the folder for the SQLite database exists.
			do {
				try FileManager.default.createDirectory(
					at: storeFolder,
					withIntermediateDirectories: true,
					attributes: nil
				)
			} catch {
				Self.performCallback(completion, result: .failure(.storeFolderCouldNotBeCreated(path: storeFolder.absoluteString)))
				return
			}

			// Create or open the SQLite database.
			let databaseUrl = storeFolder.appendingPathComponent("\(dataModelName).sqlite")
			let storeOptions = [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true
			]
			do {
				try persistentStoreCoordinator.addPersistentStore(
					ofType: NSSQLiteStoreType,
					configurationName: nil,
					at: databaseUrl,
					options: storeOptions
				)
				Self.performCallback(completion, result: .success(()))
			} catch {
				Self.performCallback(completion, result: .failure(.persistentStoreCouldNotBeCreated(path: databaseUrl.absoluteString)))
			}
		}
	}

	private static func performCallback(_ callback: @escaping (Result<Void, CoreDataManagerError>) -> Void, result: Result<Void, CoreDataManagerError>) {
		DispatchQueue.main.async {
			callback(result)
		}
	}

	/// Alternative initializer when the contexts and store coordinare shoud be injected, i.e. for UnitTests.
	init(
		persistentStoreCoordinator: NSPersistentStoreCoordinator,
		mainConext: NSManagedObjectContext,
		privateContext: NSManagedObjectContext
	) {
		self.persistentStoreCoordinator = persistentStoreCoordinator
		mainContext = mainConext
		self.privateContext = privateContext
	}

	func persist() {
		// Save the main context content to the private context.
		mainContext.performAndWait {
			do {
				if mainContext.hasChanges {
					try mainContext.save()
				}
			} catch {
				fatalError(error.localizedDescription)
			}
		}

		// Persistance will happen on the background by the private context,
		// so we don't wait for that.
		privateContext.perform {
			do {
				if self.privateContext.hasChanges {
					try self.privateContext.save()
				}
			} catch {
				fatalError(error.localizedDescription)
			}
		}
	}

	func createNewContext() -> NSManagedObjectContext {
		let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		// We set the parent of the new MOC to be the main MOC,
		// that means any changes and saves will be propagate up to the parent and occur there.
		// The new context and the main MOC do not handle any persistances,
		// it just funnels up to the private MOC which will do the persistance.
		newContext.parent = mainContext
		newContext.automaticallyMergesChangesFromParent = true

		return newContext
	}
}
