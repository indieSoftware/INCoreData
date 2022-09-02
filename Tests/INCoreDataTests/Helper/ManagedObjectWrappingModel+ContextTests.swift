import CoreData
import INCoreData
import XCTest

final class ManagedObjectWrappingModel_ContextTests: XCTestCase {
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
