import INCommons
import INCoreData
import SwiftUI

struct StartView: View {
	enum StartViewState {
		case uninitialized
		case loading
		case initialized
	}

	/// The core data manager to be injected.
	let manager: CoreDataManager

	@State private var state: StartViewState = .uninitialized
	@State private var usageViewShown = false

	private let storeFolder = FileManager.documentsDirectory.appendingPathComponent("model")

	var body: some View {
		NavigationStack {
			VStack {
				switch state {
				case .uninitialized:
					Text("CoreData not ready, yet")
					Button {
						state = .loading
						// Load manager.
						Task {
							try? await Task.sleep(seconds: 0.5)
							try? await manager.loadStore()
							state = .initialized
						}
					} label: {
						Text("Initialize CoreData")
					}
				case .loading:
					Text("CoreData loading")
					ProgressView()
				case .initialized:
					Text("CoreData ready")
					Button {
						usageViewShown = true
					} label: {
						Text("Continue to next screen")
					}
				}
			}
			.navigationTitle("StartView")
			.navigationDestination(isPresented: $usageViewShown) {
				UsageView(viewModel: UsageViewModel(manager: manager))
			}
		}
	}
}

struct StartView_Previews: PreviewProvider {
	static var previews: some View {
		// Inject an in-memory manager for the preview.
		StartView(manager: CoreDataManager(inMemory: true))
	}
}
