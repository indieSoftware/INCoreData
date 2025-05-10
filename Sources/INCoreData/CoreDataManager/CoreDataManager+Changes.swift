import CoreData

public extension CoreDataManager {
	/// Executes an async action on a new context and persist it afterwards.
	///
	/// 1. Creates a new context.
	/// 2.  Performs the passed task on the context passing it through.
	/// 3. Calls `persist` if the context has any changes.
	/// 4. Returns the result of the task.
	///
	/// - parameter task: The task to execute on a passed through context.
	/// - returns: The result of the task.
	func performTask<T>(_ task: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
		let context = createNewContext()
		let result = try await context.perform {
			let result = try task(context)
			if context.hasChanges {
				try context.save()
			}
			return result
		}
		try await persist()
		return result
	}
}
