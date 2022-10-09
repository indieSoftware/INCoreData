import CoreData
@testable import INCoreData
import XCTest

class CoreDataManager_loadStoreTests: XCTestCase {
	private var coreDataManager: CoreDataManager!

	override func setUpWithError() throws {
		try super.setUpWithError()

		coreDataManager = CoreDataManager(
			name: TestModel.name,
			bundle: Bundle(for: Self.self),
			inMemory: true
		)
	}

	override func tearDownWithError() throws {
		coreDataManager = nil

		// Prevents flaky tests
		yieldProcess()

		try super.tearDownWithError()
	}

	// MARK: - Tests

	func test_callingLoadStoreOnceWorks() async throws {
		XCTAssertNil(coreDataManager.container)
		try await coreDataManager.loadStore()
		XCTAssertNotNil(coreDataManager.container)
	}

	func test_callingMultipleTimesLoadStoreThrows() async throws {
		try await coreDataManager.loadStore()
		do {
			try await coreDataManager.loadStore()
			XCTFail("Throw expected")
		} catch {
			let error = try XCTUnwrap(error as? CoreDataManagerError)
			if case .multipleLoadStoreCalls = error {
				// Error matches, all good.
			} else {
				XCTFail("Thrown error is of wrong type: \(error)")
			}
		}
	}
}
