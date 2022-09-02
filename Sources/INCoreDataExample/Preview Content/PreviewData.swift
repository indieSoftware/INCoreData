import Foundation
import INCoreData

enum PreviewData {
	/// Creates an empty Core Data manager.
	static func manager() async -> CoreDataManager {
		do {
			let manager = CoreDataManagerLogic(inMemory: true)
			try await manager.loadStore()
			return manager
		} catch {
			fatalError("Error: \(error)")
		}
	}

	/// Creates a Core Data manager with some example items added.
	static func managerWithSomeElements() async -> CoreDataManager {
		do {
			let manager = await manager()
			try await manager.performTask { context in
				let dateFormatter = ISO8601DateFormatter()

				let newItem1 = Item(context: context)
				newItem1.timestamp = dateFormatter.date(from: "2022-06-01 15:50:00")
				context.insert(newItem1)

				let newItem2 = Item(context: context)
				newItem2.timestamp = dateFormatter.date(from: "2022-07-02 12:34:50")
				context.insert(newItem2)
			}
			return manager
		} catch {
			fatalError("Error: \(error)")
		}
	}
}
