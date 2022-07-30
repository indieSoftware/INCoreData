@testable import INCoreData
import XCTest

class PersistentContainer_initTests: XCTestCase {
	override func setUpWithError() throws {
		try super.setUpWithError()

		PersistentContainer.persistentStoreDirectoryName = "test"
		try deletePersistentDirectory()
	}

	override func tearDownWithError() throws {
		try deletePersistentDirectory()

		// Prevents flaky tests
		yieldProcess()

		try super.tearDownWithError()
	}

	private func deletePersistentDirectory() throws {
		let urlPath = PersistentContainer.defaultDirectoryURL().path
		if FileManager.default.fileExists(atPath: urlPath) {
			try FileManager.default.removeItem(atPath: urlPath)
		}
	}

	// MARK: - persistentStoreDirectoryName

	func testDefaultDirectoryUrlRemainsUnchanged() {
		PersistentContainer.persistentStoreDirectoryName = nil
		let originalUrl = PersistentContainer.defaultDirectoryURL()

		let result = PersistentContainer.defaultDirectoryURL()

		XCTAssertEqual(result, originalUrl)
	}

	func testDefaultDirectoryUrlContainsDirectoryName() {
		let directoryName = "Foo"
		PersistentContainer.persistentStoreDirectoryName = directoryName

		let result = PersistentContainer.defaultDirectoryURL()

		let containsDirectoryName = result.absoluteString.contains(directoryName)
		XCTAssertTrue(containsDirectoryName)
	}

	func testDefaultDirectoryUrlContainsMultiPartDirectoryName() {
		let directoryName = "Foo/Bar"
		PersistentContainer.persistentStoreDirectoryName = directoryName

		let result = PersistentContainer.defaultDirectoryURL()

		let containsDirectoryName = result.absoluteString.contains(directoryName)
		XCTAssertTrue(containsDirectoryName)
	}

	// MARK: - loadPersistentStore

	func testLoadPersistentStoreCreatesFolderWithStore() throws {
		// Prepare path
		let urlPath = PersistentContainer.defaultDirectoryURL().path
		let folderExists = FileManager.default.fileExists(atPath: urlPath)
		XCTAssertFalse(folderExists, "Sanity check")

		let container = try PersistentContainer(name: TestModel.name, bundle: Bundle(for: Self.self), inMemory: false)
		performAsyncThrow {
			try await container.loadPersistentStore()
		}

		let result = FileManager.default.fileExists(atPath: urlPath)
		XCTAssertTrue(result)
	}

	func testLoadPersistentStoreInMemoryDoesNotCreateFolder() throws {
		// Prepare path
		let urlPath = PersistentContainer.defaultDirectoryURL().path
		let folderExists = FileManager.default.fileExists(atPath: urlPath)
		XCTAssertFalse(folderExists, "Sanity check")

		let container = try PersistentContainer(name: TestModel.name, bundle: Bundle(for: Self.self), inMemory: true)
		performAsyncThrow {
			try await container.loadPersistentStore()
		}

		let result = FileManager.default.fileExists(atPath: urlPath)
		XCTAssertFalse(result)
	}
}
