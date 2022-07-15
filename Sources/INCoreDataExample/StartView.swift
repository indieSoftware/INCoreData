import INCommons
import INCoreData
import SwiftUI

struct StartView: View {
	enum StartViewState {
		case uninitialized
		case initializing
		case initialized
	}

	/// The core data manager to be injected.
	let manager: CoreDataManagerLogic

	@State private var state: StartViewState = .uninitialized
	@State private var usageViewShown = false

	private let storeFolder = FileManager.default.documentDirectory.appendingPathComponent("model")

	var body: some View {
		ZStack {
			NavigationLink(isActive: $usageViewShown) {
				UsageView(viewModel: UsageViewModelLogic(manager: manager))
			} label: {
				EmptyView()
			}

			VStack {
				switch state {
				case .uninitialized:
					Text("CoreData not ready, yet")
					Button {
						state = .initializing
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							// Load manager.
							Task {
								try! await manager.loadStore()
								state = .initialized
							}
						}
					} label: {
						Text("Initialize CoreData")
					}
				case .initializing:
					Text("CoreData initializing")
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
		}
	}
}

struct StartView_Previews: PreviewProvider {
	static var previews: some View {
		// Inject an in-memory manager for the preview.
		StartView(manager: try! CoreDataManagerLogic(inMemory: true))
	}
}
