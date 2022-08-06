import CoreData
import INCoreData
import XCTest

final class ManagedObjectWrappingModelTests: XCTestCase {
	var coreDataManager: CoreDataManagerLogic!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = CoreDataManagerLogic(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)
		performAsyncThrow {
			try await self.coreDataManager.loadStore()
		}
	}

	override func tearDownWithError() throws {
		try super.tearDownWithError()

		coreDataManager = nil
	}

	func testAsModel() {
		let title = UUID().uuidString

		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let object = Foo(context: context)
				let model = object.asModel
				model.title = title
				model.number = 88
				context.insert(object)
			}
		}

		let taskExpectation = expectation(description: "taskExpectation")
		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let result = try context.fetch(Foo.fetchRequest())
				XCTAssertEqual(result.count, 1)
				let object = try XCTUnwrap(result.first)
				let model = object.asModel
				XCTAssertEqual(object, model.managedObject)
				XCTAssertEqual(model.title, title)
				XCTAssertEqual(model.number, 88)
				taskExpectation.fulfill()
			}
		}

		waitForExpectations()
	}

	func testModelInContext() {
		let title = UUID().uuidString
		var foo: FooModel?

		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let model = FooModel(context: context)
				model.title = title
				model.number = 1
				model.addToContext()
				foo = model
			}
		}
		XCTAssertNotNil(foo)

		let taskExpectation = expectation(description: "taskExpectation")
		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let model = try XCTUnwrap(foo?.inContext(context))
				XCTAssertEqual(model.title, title)
				XCTAssertEqual(model.number, 1)
				taskExpectation.fulfill()
			}
		}

		waitForExpectations()
	}
}

public struct FooModel: ManagedObjectWrappingModel {
	public let managedObject: Foo

	public init(managedObject: Foo) {
		self.managedObject = managedObject
	}

	public init(context: NSManagedObjectContext) {
		managedObject = Foo(context: context)
	}

	public var title: String {
		get {
			guard let title = managedObject.title else {
				preconditionFailure("Title of MO is nil")
			}
			return title
		}
		nonmutating set {
			managedObject.title = newValue
		}
	}

	public var number: Int {
		get {
			Int(managedObject.number)
		}
		nonmutating set {
			managedObject.number = Int32(newValue)
		}
	}
}

extension Foo: ManagedObjectModelWrapping {
	public typealias Model = FooModel
}
