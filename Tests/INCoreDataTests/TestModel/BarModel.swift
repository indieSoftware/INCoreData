import CoreData
import INCoreData

public struct BarModel: ManagedObjectWrappingModel {
	public let managedObject: Bar

	public init(managedObject: Bar) {
		self.managedObject = managedObject
	}

	init(context: NSManagedObjectContext) {
		managedObject = Bar(context: context)
	}

	// MARK: - Properties

	var name: String {
		get {
			guard let value = managedObject.name else {
				preconditionFailure("String is nil")
			}
			return value
		}
		nonmutating set {
			managedObject.name = newValue
		}
	}

	var fooIndex: Int {
		Int(managedObject.fooIndex)
	}

	func setFooIndex(_ newValue: Int) throws {
		precondition(newValue >= 0, "Negative index") // We could also throw an error here instead
		precondition(newValue < foo.barCount, "Index out of bounds")
		managedObject.fooIndex = Int32(newValue)
	}

	// MARK: - References

	/// The back-reference to Foo.
	var foo: FooModel {
		guard let model = managedObject.fooRelationship?.asModel else {
			preconditionFailure("No reference model")
		}
		return model
	}
}

extension BarModel: Comparable {
	public static func < (lhs: BarModel, rhs: BarModel) -> Bool {
		lhs.fooIndex < rhs.fooIndex
	}
}

// MARK: - MO Wrapping

extension Bar: ManagedObjectModelWrapping {
	public typealias Model = BarModel
}
