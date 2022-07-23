import Combine
import INCoreData

@MainActor
final class UsageViewModel: ObservableObject {
	private let manager: CoreDataManager
	private var cancellables = Set<AnyCancellable>()

	init(manager: CoreDataManager) {
		self.manager = manager

		loadData()

		manager.publisher(
			managedObjectType: Item.self, // Listen for changes related to any Item
			context: manager.mainContext, // happening on the main context
			changeTypes: .allCases // and for any type of change (insert, delete and update)
		)
		.sink { [weak self] (_: [ManagedObjectsChange<Item>]) in
			// We can now inspect all changes,
			// but instead we simply reload all data.
			self?.loadData()
		}
		.store(in: &cancellables)
	}

	@Published var items: [ItemModel] = []

	private func loadData() {
		Task {
			do {
				try await manager.performTask { context in
					let fetchRequest = Item.fetchRequest()
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
					let items = try context
						.fetch(fetchRequest)
						.map { ItemModel(timestamp: $0.timestamp ?? Date()) }
					// Create a new task which will run on the main thread
					// because of the MainActor annotation of the properties class.
					Task {
						// A Published property has to be set on the UI thread.
						self.items = items
					}
				}
			} catch {
				print("Error: \(error)")
			}
		}
	}

	func addItem() {
		Task {
			do {
				try await manager.performTask { context in
					let newItem = Item(context: context)
					newItem.timestamp = Date()
					context.insert(newItem)
				}
			} catch {
				print("Error: \(error)")
			}
		}
	}

	func deleteItems(offsets: IndexSet) {
		Task {
			do {
				try await manager.performTask { context in
					let fetchRequest = Item.fetchRequest()
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
					try context
						.fetch(fetchRequest)
						.enumeratedArray()
						.filter { offsets.contains($0.offset) }
						.map(\.element)
						.forEach {
							context.delete($0)
						}
				}
			} catch {
				print("Error: \(error)")
			}
		}
	}
}
