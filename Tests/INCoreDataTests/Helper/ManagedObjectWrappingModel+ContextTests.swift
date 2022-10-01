import CoreData
import INCoreData
import XCTest

final class ManagedObjectWrappingModel_ContextTests: XCTestCase {
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

	func testModelInContext() {
		let title = UUID().uuidString

		let fooHolder = ObjectHolder<FooModel>()

		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let model = FooModel(context: context)
				model.title = title
				model.number = 1
				model.addToContext()
				fooHolder.object = model
			}
		}
		XCTAssertNotNil(fooHolder.object)

		let taskExpectation = expectation(description: "taskExpectation")
		performAsyncThrow {
			try await self.coreDataManager.performTask { context in
				let model = try XCTUnwrap(fooHolder.object?.inContext(context))
				XCTAssertEqual(model.title, title)
				XCTAssertEqual(model.number, 1)
				taskExpectation.fulfill()
			}
		}

		waitForExpectations()
	}
}
