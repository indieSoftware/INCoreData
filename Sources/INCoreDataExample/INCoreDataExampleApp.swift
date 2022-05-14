import INCoreData
import SwiftUI

@main
struct INCoreDataExampleApp: App {
	var body: some Scene {
		WindowGroup {
			NavigationView {
				INCoreDataExampleView()
			}
			.environment(\.managedObjectContext, dataManager.viewContext)
		}
	}

	var dataManager: DataManager = {
		let container = DataManager(name: "Example")
		container.loadPersistentStores(completionHandler: { _, error in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()

	// If there will be any change this function save it
	func saveContext() {
		let context = dataManager.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
}
