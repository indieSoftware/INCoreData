import INCoreData
import SwiftUI

@main
struct INCoreDataExampleApp: App {
	var body: some Scene {
		WindowGroup {
			NavigationView {
				// Inject a default core data manager.
				let coreDataManager = try! CoreDataManagerLogic()
				StartView(manager: coreDataManager)
			}
		}
	}
}
