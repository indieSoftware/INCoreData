import Foundation
import XCTest

extension XCTestCase {
	/// The default time for expectations when they should time out.
	static let defaultExpectationTimeout: TimeInterval = 0.5

	/**
	 Waits until the test fulfills all expectations or until it times out.
	 */
	func waitForExpectations() {
		waitForExpectations(timeout: XCTestCase.defaultExpectationTimeout)
	}

	/// Calls an async throwing code block synchronously.
	///
	/// The synchronous execution is realized via an expectation and thus should NOT be called
	/// in an async test method.
	///
	/// Catches any throwing errors to show the failing error in a unit test in a more readable way.
	/// Instead of calling your code block directly in a unit test wrap it with `performAsyncThrow`:
	///
	/// ```
	/// performAsyncThrow {
	///   try await myAsyncThrowingMethod()
	/// }
	/// ```
	///
	/// - parameter block: The async throwing code block to test.
	func performAsyncThrow(_ block: @escaping () async throws -> Void, file: StaticString = #file, line: UInt = #line) {
		let asyncExpectation = expectation(description: "asyncExpectation")
		Task {
			do {
				try await block()
				asyncExpectation.fulfill()
			} catch {
				XCTFail("Catched throwing error: \(error)", file: file, line: line)
			}
		}
		wait(for: [asyncExpectation], timeout: XCTestCase.defaultExpectationTimeout)
	}
}
