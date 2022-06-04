import CoreData

extension PersistenceStackLogic {
	/**
	 A convenience initializer for an in-memory CoreData persistance stack used in UnitTests.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file.
	 - parameter bundle: The bundle where to find the data model.
	 - parameter completion: The completion handler which gets called when the in-memory store has been created
	 and can be used.
	 - parameter persistentStoreCoordinator: The created persistent store coordinator.
	 - parameter mainContext: The created main context.
	 - parameter privateContext: The created private background context.
	 - parameter container: The created container.
	 */
	convenience init(
		dataModelName: String,
		bundle: Bundle,
		completion: @escaping (
			_ persistentStoreCoordinator: NSPersistentStoreCoordinator,
			_ mainContext: NSManagedObjectContext,
			_ privateContext: NSManagedObjectContext,
			_ container: NSPersistentContainer
		) -> Void
	) {
		guard let modelURL = bundle.url(forResource: dataModelName, withExtension: "momd"),
		      let objectModel = NSManagedObjectModel(contentsOf: modelURL)
		else {
			// If the MOM failed to be created then it's a programmer error
			// where the '.xcdatamodeld' file isn't in the provided bundle.
			fatalError("No data model found with name '\(dataModelName)' in bundle '\(bundle.bundlePath)'")
		}

		let container = NSPersistentContainer(name: "InMemoryModel", managedObjectModel: objectModel)

		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
		description.shouldMigrateStoreAutomatically = true
		description.shouldInferMappingModelAutomatically = true
		container.persistentStoreDescriptions = [description]

		let coordinator = container.persistentStoreCoordinator

		let privateMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateMoc.persistentStoreCoordinator = coordinator

		let mainMoc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		mainMoc.parent = privateMoc

		self.init(
			persistentStoreCoordinator: coordinator,
			mainConext: mainMoc,
			privateContext: privateMoc
		)

		container.loadPersistentStores { _, error in
			if let error = error {
				fatalError("Failed to set up in-memory store \(error.localizedDescription)")
			}
			completion(
				coordinator,
				mainMoc,
				privateMoc,
				container
			)
		}
	}
}
