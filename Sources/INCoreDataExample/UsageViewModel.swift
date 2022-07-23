import Combine
import INCoreData

// Mark observable object as MainActor to ensure that all its
// Published properties and methods are queried on the main thread.
// Usually this is already given because only UI elements are
// processing them, but internal assignments like assigning
// new items after an async fetch request are now also ensured
// that they happen on the main thread.
@MainActor
final class UsageViewModel: ObservableObject {
	private let manager: CoreDataManager
	private var cancellables = Set<AnyCancellable>()

	enum ItemsState {
		case empty
		case data(_ items: [ItemModel])
		case error(_ message: String)
	}

	@Published var items: ItemsState = .empty

	init(manager: CoreDataManager) {
		self.manager = manager

		// Initially load the list's content.
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

	private func loadData() {
		Task {
			do {
				try await manager.performTask { context in
					let fetchRequest = Item.fetchRequest()
					fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
					let items = try context
						.fetch(fetchRequest)
						.map { ItemModel(timestamp: $0.timestamp ?? Date()) }
					// A Published property has to be set on the UI thread,
					// therefore, initiate a new Task from within this context.
					Task {
						if items.isEmpty {
							self.items = .empty
						} else {
							self.items = .data(items)
						}
					}
				}
			} catch {
				items = .error(error.localizedDescription)
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
				items = .error(error.localizedDescription)
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
						.fetch(fetchRequest) // Get sorted list of Items
						.enumeratedArray() // Map to (offset, element)
						.filter { offsets.contains($0.offset) } // Filter for selected items
						.map(\.element) // Map to element, omitting the offset
						.forEach(context.delete) // Pass element/item to delete method
				}
			} catch {
				items = .error(error.localizedDescription)
			}
		}
	}
}
