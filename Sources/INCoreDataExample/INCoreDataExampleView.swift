import INCoreData
import SwiftUI
struct INCoreDataExampleView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        List {
            ForEach(items) { item in
                Text("Item at \(item.timestamp ?? Date())")
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }
    
    private func addItem() {
        let newItem = Item(context: viewContext)
        newItem.timestamp = Date()

        do {
            try viewContext.save()
        } catch {
            // Error handling
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.map { items[$0] }.forEach(viewContext.delete)

        do {
            try viewContext.save()
        } catch {
            // Error handling
        }
    }
}

struct INCoreDataExampleView_Previews: PreviewProvider {
	static var previews: some View {
		INCoreDataExampleView()
	}
}
