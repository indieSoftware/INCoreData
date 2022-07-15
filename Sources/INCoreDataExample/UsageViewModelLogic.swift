import Combine
import INCoreData

class UsageViewModelLogic: UsageViewModel {
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
			// We can now inspect all changes via objectsChanges, but instead we simply reload all data.
			self?.loadData()
		}
		.store(in: &cancellables)
	}

	@Published var items: [ItemModel] = []

	private func loadData() {
		do {
			let fetchRequest = Item.fetchRequest()
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
			items = try manager.mainContext
				.fetch(fetchRequest)
				.map { ItemModel(timestamp: $0.timestamp ?? Date()) }
		} catch {
			print("Error: \(error)")
		}
	}

	func addItem() {
		let context = manager.mainContext
		let newItem = Item(context: context)
		newItem.timestamp = Date()

		do {
			try context.save()
		} catch {
			print("Error: \(error)")
		}
	}

	func deleteItems(offsets: IndexSet) {
		do {
			let context = manager.mainContext

			let fetchRequest = Item.fetchRequest()
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
			try manager.mainContext
				.fetch(fetchRequest)
				.enumeratedArray()
				.filter { offsets.contains($0.offset) }
				.map(\.element)
				.forEach(context.delete)

			try context.save()
		} catch {
			print("Error: \(error)")
		}
	}

	func persistItems() {
		Task {
			try! await manager.persist()
		}
	}
}
