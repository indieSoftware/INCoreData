import CoreData
import INCoreData
import XCTest

final class ManagedObjectWrappingModel_ReferenceManipulationTests: XCTestCase {
	private var coreDataManager: CoreDataManager!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = CoreDataManager(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)

		performAsyncThrow {
			// Prepare manager.
			try await self.coreDataManager.loadStore()
		}
	}

	override func tearDownWithError() throws {
		weak var weakManager: CoreDataManager? = coreDataManager

		coreDataManager = nil

		// Prevents flaky tests
		yieldProcess()

		XCTAssertNil(weakManager)

		try super.tearDownWithError()
	}

	// MARK: - Tests

	func testAddModel() async throws {
		try await coreDataManager.performTask { context in
			// Create Foo.
			let fooModel = FooModel(context: context)
			fooModel.title = "Title"
			fooModel.number = 1
			XCTAssertEqual(fooModel.barCount, 0)

			// Add one bar.
			let barModel1 = BarModel(context: context)
			try fooModel.addBar(barModel1)

			// Add second bar.
			let barModel2 = BarModel(context: context)
			try fooModel.addBar(barModel2)

			// Add third bar.
			let barModel3 = BarModel(context: context)
			try fooModel.addBar(barModel3)

			// Assure three bars in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 3)
			XCTAssertEqual(fooModel.bars, [barModel1, barModel2, barModel3])
			XCTAssertEqual(barModel1.fooIndex, 0)
			XCTAssertEqual(barModel2.fooIndex, 1)
			XCTAssertEqual(barModel3.fooIndex, 2)
		}
	}

	func testRemoveModel() async throws {
		try await coreDataManager.performTask { context in
			// Create Foo with some bars.
			let fooModel = FooModel(context: context)
			fooModel.title = "Title"
			fooModel.number = 1
			XCTAssertEqual(fooModel.barCount, 0)

			let barModel1 = BarModel(context: context)
			try fooModel.addBar(barModel1)
			let barModel2 = BarModel(context: context)
			try fooModel.addBar(barModel2)
			let barModel3 = BarModel(context: context)
			try fooModel.addBar(barModel3)

			// Remove second bar.
			try fooModel.removeBar(barModel2)

			// Assure two bar in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 2)
			XCTAssertEqual(fooModel.bars, [barModel1, barModel3])
			XCTAssertEqual(barModel1.fooIndex, 0)
			XCTAssertEqual(barModel3.fooIndex, 1)

			// Remove first bar.
			try fooModel.removeBar(barModel1)

			// Assure last bar is remaining.
			XCTAssertEqual(fooModel.barCount, 1)
			XCTAssertEqual(fooModel.bars, [barModel3])
			XCTAssertEqual(barModel3.fooIndex, 0)

			// Remove last bar.
			try fooModel.removeBar(barModel3)

			// Assure no bars are remaining.
			XCTAssertEqual(fooModel.barCount, 0)
			XCTAssertEqual(fooModel.bars, [])
		}
	}

	func testInsertModel() async throws {
		try await coreDataManager.performTask { context in
			// Create Foo with some bars.
			let fooModel = FooModel(context: context)
			fooModel.title = "Title"
			fooModel.number = 1
			XCTAssertEqual(fooModel.barCount, 0)

			let barModel1 = BarModel(context: context)
			try fooModel.addBar(barModel1)
			let barModel2 = BarModel(context: context)
			try fooModel.addBar(barModel2)
			let barModel3 = BarModel(context: context)
			try fooModel.addBar(barModel3)

			// Insert some bars.
			let barModel4 = BarModel(context: context)
			try fooModel.insertBar(barModel4, index: 0)
			let barModel5 = BarModel(context: context)
			try fooModel.insertBar(barModel5, index: fooModel.barCount)
			let barModel6 = BarModel(context: context)
			try fooModel.insertBar(barModel6, index: 2)

			// Assure bars have been inserted into correct position.
			XCTAssertEqual(fooModel.barCount, 6)
			XCTAssertEqual(fooModel.bars, [barModel4, barModel1, barModel6, barModel2, barModel3, barModel5])
			XCTAssertEqual(barModel4.fooIndex, 0)
			XCTAssertEqual(barModel1.fooIndex, 1)
			XCTAssertEqual(barModel6.fooIndex, 2)
			XCTAssertEqual(barModel2.fooIndex, 3)
			XCTAssertEqual(barModel3.fooIndex, 4)
			XCTAssertEqual(barModel5.fooIndex, 5)
		}
	}

	func testManipulationMix() async throws {
		try await coreDataManager.performTask { context in
			// Create Foo.
			let fooModel = FooModel(context: context)
			fooModel.title = "Title"
			fooModel.number = 1
			XCTAssertEqual(fooModel.barCount, 0)

			// Add one bar.
			let barModel1 = BarModel(context: context)
			try fooModel.addBar(barModel1)

			// Add second bar.
			let barModel2 = BarModel(context: context)
			try fooModel.addBar(barModel2)

			// Add third bar.
			let barModel3 = BarModel(context: context)
			try fooModel.addBar(barModel3)

			// Assure three bars in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 3)
			XCTAssertEqual(fooModel.bars, [barModel1, barModel2, barModel3])
			XCTAssertEqual(barModel1.fooIndex, 0)
			XCTAssertEqual(barModel2.fooIndex, 1)
			XCTAssertEqual(barModel3.fooIndex, 2)

			// Remove second bar.
			try fooModel.removeBar(barModel2)

			// Assure two bar in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 2)
			XCTAssertEqual(fooModel.bars, [barModel1, barModel3])
			XCTAssertEqual(barModel1.fooIndex, 0)
			XCTAssertEqual(barModel3.fooIndex, 1)

			// Insert fourth bar.
			let barModel4 = BarModel(context: context)
			try fooModel.insertBar(barModel4, index: 1)

			// Assure three bars in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 3)
			XCTAssertEqual(fooModel.bars, [barModel1, barModel4, barModel3])
			XCTAssertEqual(barModel1.fooIndex, 0)
			XCTAssertEqual(barModel4.fooIndex, 1)
			XCTAssertEqual(barModel3.fooIndex, 2)

			// Remove first bar.
			try fooModel.removeBar(barModel1)

			// Assure two bars in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 2)
			XCTAssertEqual(fooModel.bars, [barModel4, barModel3])
			XCTAssertEqual(barModel4.fooIndex, 0)
			XCTAssertEqual(barModel3.fooIndex, 1)

			// Add first bar again.
			try fooModel.addBar(barModel1)

			// Assure three bars in correct order are added to foo.
			XCTAssertEqual(fooModel.barCount, 3)
			XCTAssertEqual(fooModel.bars, [barModel4, barModel3, barModel1])
			XCTAssertEqual(barModel4.fooIndex, 0)
			XCTAssertEqual(barModel3.fooIndex, 1)
			XCTAssertEqual(barModel1.fooIndex, 2)
		}
	}
}
