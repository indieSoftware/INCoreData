import INCoreData
import SwiftUI

@main
struct INCoreDataExampleApp: App {
	var body: some Scene {
		WindowGroup {
			NavigationView {
				// Creating and inject a concrete core data manager instance.
				let coreDataManager = CoreDataManagerLogic()
				StartView(manager: coreDataManager)
			}
		}
	}
}
