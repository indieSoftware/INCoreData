import Foundation

struct ItemViewModel: Identifiable {
	init(model: ItemModel) {
		timestamp = model.timestamp
	}

	let timestamp: Date

	var id: Date { timestamp }
}
