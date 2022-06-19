import Combine
import Foundation

protocol UsageViewModel: ObservableObject {
	var items: [ItemModel] { get }

	func addItem()
	func deleteItems(offsets: IndexSet)
	func persistItems()
}
