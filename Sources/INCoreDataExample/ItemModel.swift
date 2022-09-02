import CoreData
import INCoreData

public struct ItemModel: ManagedObjectWrappingModel {
	public let managedObject: Item

	public init(managedObject: Item) {
		self.managedObject = managedObject
	}

	init(context: NSManagedObjectContext) {
		managedObject = Item(context: context)
		context.insert(managedObject)
	}

	var timestamp: Date {
		get {
			guard let value = managedObject.timestamp else {
				preconditionFailure("Value is nil")
			}
			return value
		}
		nonmutating set {
			managedObject.timestamp = newValue
		}
	}

	public var id: Date { timestamp }
}

// MARK: - Queries

extension NSManagedObjectContext {
	func fetchItems() throws -> [ItemModel] {
		let fetchRequest = Item.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
		return try fetch(fetchRequest).map(\.asModel)
	}
}

// MARK: - MO Wrapping

extension Item: ManagedObjectModelWrapping {
	public typealias Model = ItemModel
}
