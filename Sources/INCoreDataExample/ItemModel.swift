import Foundation

struct ItemModel: Identifiable {
	let timestamp: Date

	var id: Date { timestamp }
}
