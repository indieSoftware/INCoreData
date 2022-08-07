import INCommons
import INCoreData
import SwiftUI

struct UsageView: View {
	/// Use an injected view model for this view which handles all core data requests.
	@StateObject var viewModel: UsageViewModel

	var body: some View {
		VStack {
			Group {
				switch viewModel.items {
				case .empty:
					emptyContent
				case let .data(items):
					listContent(items)
				case let .error(message):
					errorContent(message)
				}
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					HStack {
						Button(action: {
							viewModel.addItem()
						}) {
							Label("Add Item", systemImage: "plus")
						}
					}
				}
			}
		}
		.navigationTitle("Usage Example")
	}

	private func listContent(_ items: [ItemViewModel]) -> some View {
		List {
			ForEach(items) { item in
				Text("\(item.timestamp)")
			}
			.onDelete {
				viewModel.deleteItems(offsets: $0)
			}
		}
	}

	private var emptyContent: some View {
		Text("No content")
	}

	private func errorContent(_ message: String) -> some View {
		Text(message)
	}
}

struct UsageView_Previews: PreviewProvider {
	static var previews: some View {
		// Use a preview container to inject the manager into the view.
		CoreDataPreview(PreviewData.managerWithSomeElements) { manager in
			NavigationView {
				UsageView(viewModel: UsageViewModel(manager: manager))
			}
		}
	}
}
