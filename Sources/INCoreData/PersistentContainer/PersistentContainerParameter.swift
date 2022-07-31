import Foundation

/// The parameter for the persistent container.
struct PersistentContainerParameter {
	/// The CoreData model's name.
	let modelName: String
	/// The bundle where to find the CoreData model.
	let modelBundle: Bundle
	/// Flag indicating whether to use an in-memory store or not.
	let inMemory: Bool
	/// Flag to sync the model scheme with CloudKit during loading.
	let syncSchemeWithCloudKit: Bool
}
