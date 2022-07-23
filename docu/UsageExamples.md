
# Usage Examples

## Set up

Create an instance of the manager:

```
import INCoreData

let manager: CoreDataManager = try! CoreDataManagerLogic()
```

This will use the data model named "DataModel" from the main bundle and use the path "CoreData" inside of the documents folder to persist the Core Data stack.

If the "xcdatamodelId" file differes, is not in the main bundle or a different folder name in the documents folder should be used then provide those information to the init method.

```
let manager: CoreDataManager = try! CoreDataManagerLogic(
	name: "MyModel", 
	bundle: Bundle(for: Model.self), 
	storeDirectoryName: "DataStack"
)
```

Call `loadStore` before using the manager:

```
Task {
	try! await manager.loadStore()
	// Core Data is set up, proceed with app flow
}
```

### In-memory manager

When using the CoreDataManager for UnitTests or Previews then a lighter in-memory version is more desirable. For that simply pass `true` for the `inMemory` parameter in the init method.

```
class MyTests: XCTestCase {
	private var coreDataManager: CoreDataManagerLogic!

	override func setUpWithError() throws {
		try super.setUpWithError()

		// Create in-memory manager.
		coreDataManager = try CoreDataManagerLogic(inMemory: true)

		let asyncExpectation = expectation(description: "asyncExpectation")
		Task {
			do {
				// Prepare manager.
				try await self.coreDataManager.loadStore()
				asyncExpectation.fulfill()
			} catch {
				XCTFail("Catched throwing error: \(error)")
			}
		}
		// Wait for the async preparation to finish 
		// before proceeding with the unit test.
		wait(for: [asyncExpectation], timeout: 0.5)
	}
}
```

### Previews

To use a `CoreDataManager` in a preview it's recommended to use an in-memory version and to pre-fill it with some example data to show them in the preview. However, since the manager needs to be initialized asynchronously it might become tricky to prepare that for a preview. That's where `CoreDataPreview` can help.

First create a namespace and a factory method which creates an instance of `CoreDataManager` with some pre-filled data:

```
enum PreviewData {
	/// Creates an empty Core Data manager.
	static func managerWithSomeElements() async -> CoreDataManager {
		do {
			// Initialize an in-memory manager.
			let manager = try CoreDataManagerLogic(inMemory: true)
			try await manager.loadStore()
			
			// Pre-fill it with some example data.
			try await manager.performTask { context in
				let newItem = Item(context: context)
				context.insert(newItem)
			}

			return manager
		} catch {
			fatalError("Error: \(error)")
		}
	}
}
```

Now use that factory and the `CoreDataPreview` in a preview to embed the custom view to preview:

```
struct MyView_Previews: PreviewProvider {
	static var previews: some View {
		// Use a preview container to inject the manager into the view.
		CoreDataPreview(PreviewData.managerWithSomeElements) { manager in
			MyView(viewModel: MyViewModel(manager: manager))
		}
	}
}
```

The preview will now only render a placeholder view. To see the real view simply run the preview and then tap on the button. This will execute the factory asynchronously and inject the created manager into the view to preview.

## Creating Context

The default context is the main context which is also used by the UI. To access it:

```
let mainContext = manager.mainContext
```

However, ususally it's not recommended to use the main context to retrieve or change elements. Use a background context for that:

```
let backgroundContext = manager.createNewContext()
try await backgroundContext.perform {
	// Do somethong on backgroundContext ...
	try backgroundContext.save()
}
```

Alternatively, use `performTask` to further simplify this process. This will create a new temporary background context on which any operations can be performed and which will automatically save any changes when finished. The above example would then be replaced by:

```
try await manager.performTask { backgroundContext in
	// Do something on backgroundContext ...
}
```

## Listen for changes with Publishers

There are three different publishers suitable for listening for changes via Combine.

### Listening for changes on a given object

When interested in changes applied on a given managed object then use the following publisher:

```
manager.publisher(
	managedObject: item, // Listen for changes on this specific item instance
	notificationType: .objectChanged, // Each object modification will instantly trigger an event
	changeTypes: [.updated] // Only updates are of interest here
)
.sink { [weak self] (objectChange: ManagedObjectChange<Item>) in
	// The item instance has been updated, do something with this information.
	// objectChange.type == .updated
	// objectChange.object == item
}
.store(in: &cancellables)
```

Note: `item` is of type `Item` here which is a `NSManagedObject`.

This will trigger an event immediately whenever a property of the item instance has been changed. 

Use `.contextSaved` instead of `.objectChanged` as the `notificationType` to get only notified via events when the changes have been saved rather than immediately and directly on each assignment.

And to get also events when the item instance has been inserted or deleted from the context, then provide these `changeTypes`: `[.updated, .inserted, .deleted]` or simply `.allCases` or a mix of them when interested only in some.

### Listening for changes on an object type

To get notified when new items has been added to the context or old ones have been deleted it's required to listen for changes of a type rather than concrete instances (which we don't know, yet).


```
manager.publisher(
	managedObjectType: Item.self, // Listen for changes related to any "Item" object
	context: manager.mainContext, // The change has to happen on the main context
	notificationType: .contextSaved // Only when saving new events will be emitted
	changeTypes: .allCases // Any change is relevant, including insertion and deletion
)
.sink { [weak self] (objectsChange: ManagedObjectsChange<Item>) in
	// Each insertion, deletion and update of any Item instance
	// will trigger its own event now.
}
.store(in: &cancellables)
```

This will create new events when a context gets saved. However, that might involve multiple different changes and even upon different objects, i.e. when modifying 2 different objects and deleting a third then this will trigger only two events (updated and deleted), but with two objects in the list of the updated event.

Of course, it's also possible to listen for any immediate changes rather than only when the context gets saved, but that's usually not the preferred way.

### Listening for changes on an object type, but published by a single event

While the previous publisher will create a new event for each different change type it might be sometimes more practical to get only one single event with an array of all changes.

This can be done with the following publisher:

```
manager.publisher(
	managedObjectType: Item.self, // Listen for changes related to any "Item" object
	context: manager.mainContext, // The change has to happen on the main context
	changeTypes: .allCases // Any change is relevant, including insertion and deletion
)
.sink { [weak self] (objectsChanges: [ManagedObjectsChange<Item>]) in
	// All insertions, deletions and updates will now be representd 
	// by only one single event.
}
.store(in: &cancellables)
```

This publisher is only applicable for `contextSaved` notifications (otherwise it won't be technically possible that multiple change types happen on the same time, so that the second publisher would be more applicable in that situation).

## Other helper

### Retrieving an object from a context

There exists a `NSManagedObject` extension which makes it easy to retrieve a given object, but in a different context. This might be useful when an object has already been created or retrieved in a different context and now should be processed further in a new task or context:

```
try await manager.performTask { backgroundContext in
	let itemInBackgroundContext = itemInMainContext.inContext(backgroundContext)
	// Do something with itemInBackgroundContext...
}
```
