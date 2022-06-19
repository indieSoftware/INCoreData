import Foundation

class UsageViewModelMock: UsageViewModel {
	var items: [ItemModel] = [
		ItemModel(timestamp: Date()),
		ItemModel(timestamp: Date())
	]

	func addItem() {}
	func deleteItems(offsets _: IndexSet) {}
	func persistItems() {}
}
