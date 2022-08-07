import CoreData
import INCoreData

public struct FooModel: ManagedObjectWrappingModel {
	public let managedObject: Foo

	public init(managedObject: Foo) {
		self.managedObject = managedObject
	}

	init(context: NSManagedObjectContext) {
		managedObject = Foo(context: context)
	}

	// MARK: - Properties

	var title: String {
		get {
			guard let title = managedObject.title else {
				preconditionFailure("String is nil")
			}
			return title
		}
		nonmutating set {
			managedObject.title = newValue
		}
	}

	var number: Int {
		get {
			Int(managedObject.number)
		}
		nonmutating set {
			// We can verify some more constraints,
			// i.e. when number should never be a negative value.
			precondition(newValue >= 0)
			managedObject.number = Int32(newValue)
		}
	}

	// MARK: - References

	var bars: [BarModel] {
		guard let barSet = managedObject.barRelationship else {
			preconditionFailure("No set")
		}
		let models = barSet.compactMap {
			($0 as? Bar)?.asModel
		}.sorted() // BarModel needs to conform to Comparable.
		return models
	}

	/// Returns the number of associated bars in a loop-safe way.
	/// This is necessary for a preconditions in Bar to verify an index
	/// because using `bars` would leed to a high load because of recursive loops.
	var barCount: Int {
		guard let count = managedObject.barRelationship?.count else {
			preconditionFailure("No set")
		}
		return count
	}

	func addBar(_ model: BarModel) {
		addModel(
			model,
			addingMethod: managedObject.addToBarRelationship,
			indexKeyPath: \BarModel.fooIndex,
			countKeyPath: \.barCount
		)
	}

	func removeBar(_ model: BarModel) {
		removeModel(
			model,
			removingMethod: managedObject.removeFromBarRelationship,
			indexKeyPath: \BarModel.fooIndex,
			objectSetKeyPath: \.barRelationship
		)
	}

	func insertBar(_ model: BarModel, index: Int) {
		insertModel(
			model,
			index: index,
			addingMethod: managedObject.addToBarRelationship,
			indexKeyPath: \BarModel.fooIndex,
			objectSetKeyPath: \.barRelationship
		)
	}
}

// MARK: - Queries

extension NSManagedObjectContext {
	func fetchFoos() throws -> [FooModel] {
		try fetch(Foo.fetchRequest())
			.map(\.asModel)
			.sorted {
				$0.number < $1.number
			}
	}
}

// MARK: - MO Wrapping

extension Foo: ManagedObjectModelWrapping {
	public typealias Model = FooModel
}
