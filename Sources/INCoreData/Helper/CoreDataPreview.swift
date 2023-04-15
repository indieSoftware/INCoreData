import SwiftUI

/// A view which wraps any view which is depending ona `CoreDataManager` instance
/// to render in a SwiftUI preview.
/// A `CoreDataManager` instance needs to be loaded asynchronously before
/// it can be used in a preview, but the preview is static and can't wait.
/// Therefore, this view wraps and delays the creation of the depending view
/// until the manager has been created and then swaps the placeholder with the
/// real view.
/// However, to make this work the preview has to be run and the button
/// in the placeholder view has to be pressed to initiate the factory call.
public struct CoreDataPreview<Content: View>: View {
	private let content: (CoreDataManager) -> Content

	private let factory: () async -> CoreDataManager

	@MainActor
	@State
	private var coreDataManager: CoreDataManager?

	/**
	 Initializes a preview container.

	 - parameter coreDataManagerFactory: The factory closure which creates the `CoreDataManager`.
	 The factory method will be run asynchronously so it can also be filled with example data.
	 - parameter content: The actual view to render in the preview.
	 This view will be shown after the factory has returned a manager which then will be passed to the content view.
	 */
	public init(
		_ coreDataManagerFactory: @escaping () async -> CoreDataManager,
		@ViewBuilder content: @escaping (CoreDataManager) -> Content
	) {
		self.content = content
		factory = coreDataManagerFactory
	}

	public var body: some View {
		if let manager = coreDataManager {
			content(manager)
		} else {
			Button {
				Task {
					let manager = await factory()
					await MainActor.run {
						coreDataManager = manager
					}
				}
			} label: {
				Text("Run preview and tap here")
					.padding()
					.background(Color.yellow.cornerRadius(16))
			}
		}
	}
}
