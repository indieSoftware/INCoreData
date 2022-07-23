import INCommons
import INCoreData
import SwiftUI

struct UsageView: View {
	/// Use an injected view model for this view which handles all core data requests.
	@StateObject var viewModel: UsageViewModel

	var body: some View {
		VStack {
			List {
				ForEach(viewModel.items) { item in
					Text("\(item.timestamp)")
				}
				.onDelete {
					viewModel.deleteItems(offsets: $0)
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
}

struct UsageView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			// Inject a view model mock so we don't have to mess around with Core Data here.
			UsageView(viewModel: UsageViewModel(manager: try! CoreDataManagerLogic(inMemory: true)))
		}
	}
}
