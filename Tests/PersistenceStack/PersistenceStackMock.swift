import CoreData
@testable import INCoreData

class PersistenceStackMock: PersistenceStack {
	private var initializeCompletionHandler: (() -> Void)?

	/**
	 Call this initializer to set up the in-memory stack.

	 - parameter completion: The completion handler which will be called when the stack has been created.
	 */
	func initialize(completion: @escaping () -> Void) {
		initializeCompletionHandler = completion
		_ = persistenceStackInMemory
	}

	/// The in-memory stack used by this mock to provide a main context back.
	lazy var persistenceStackInMemory = PersistenceStackLogic(
		dataModelName: "TestModel",
		bundle: Bundle(for: Self.self),
		completion: { _, mainContext, _, _ in
			self.mainContextInMemory = mainContext
			self.initializeCompletionHandler?()
		}
	)

	/// The in-memory main context.
	var mainContextInMemory: NSManagedObjectContext?

	lazy var mainContextMock: () -> NSManagedObjectContext = { [unowned self] in
		self.mainContextInMemory ?? NSManagedObjectContext(.mainQueue)
	}

	var mainContext: NSManagedObjectContext {
		mainContextMock()
	}

	lazy var persistMock: () -> Void = { [unowned self] in
		self.persistenceStackInMemory.persist()
	}

	func persist() {
		persistMock()
	}

	lazy var createNewContextMock: () -> NSManagedObjectContext = { [unowned self] in
		self.persistenceStackInMemory.createNewContext()
	}

	func createNewContext() -> NSManagedObjectContext {
		createNewContextMock()
	}
}
