import CoreData
import INCoreData
import XCTest

final class ManagedObjectWrappingModelTests: XCTestCase {
	var coreDataManager: CoreDataManager!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = CoreDataManager(
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
}
