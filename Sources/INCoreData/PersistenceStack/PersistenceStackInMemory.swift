import CoreData

extension PersistenceStackLogic {
	/**
	 Initializes an in-memory CoreData persistance stack, usable for UnitTests.

	 - parameter dataModelName: The name of the CoreData model which is the file name of the `xcdatamodeld` file.
	 - parameter bundle: The bundle where to find the data model.
	 - parameter completion: The completion handler which gets called when the in-memory store has been created
	 and can be used.
	 */
	convenience init(
		dataModelName: String,
		bundle: Bundle,
		completion: @escaping () -> Void
	) {
		guard let modelURL = bundle.url(forResource: dataModelName, withExtension: "momd"),
		      let objectModel = NSManagedObjectModel(contentsOf: modelURL)
		else {
			// If the MOM failed to be created then it's a programmer error
			// where the '.xcdatamodeld' file isn't in the provided bundle.
			fatalError("No data model found with name '\(dataModelName)' in bundle '\(bundle.bundlePath)'")
		}

		let container = NSPersistentContainer(name: "InMemoryModel", managedObjectModel: objectModel)

		let privateMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateMoc.persistentStoreCoordinator = container.persistentStoreCoordinator

		let mainMoc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		mainMoc.parent = privateMoc

		self.init(
			persistentStoreCoordinator: container.persistentStoreCoordinator,
			mainConext: mainMoc,
			privateContext: privateMoc
		)

		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
		container.persistentStoreDescriptions = [description]

		container.loadPersistentStores { _, error in
			if let error = error {
				fatalError("Failed to set up in-memory store \(error.localizedDescription)")
			}
			completion()
		}
	}
}
