
# Usage Examples

## Set up

Create an instance of the manager:

```
import INCoreData

let manager: CoreDataManager = CoreDataManagerLogic()
```

Call setup before using the manager:

```
manager.setup(storeFolder: storeFolder) { result in
	switch result {
		case let .failure(error):
			// Error handling
		case .success():
			// Core Data is set up, proceed with app flow
	}
}
```

This will use the data model named "DataModel" from the main bundle and use the path pointing at by `storeFolder` to persist the Core Data stack.

If the "xcdatamodelId" file differes then a model name needs to be provided to the setup method. Same when the data model is not defined in the main bundle.

### In-memory manager

When using the CoreDataManager for UnitTests or Previews then a lighter in-memory version is more desirable. For that either use the alternative convenience initializer which doesn't require setup to be called:

```
let inMemoryManager = CoreDataManagerLogic(
	dataModelName: myDataModelName
) { persistentStoreCoordinator, mainContext, privateContext, container in
	// ...
}
```

or use the standard initializer with the `useInMemory` parameter set to `true` to have no other change in the code flow:

```
let inMemoryManager = CoreDataManagerLogic(useInMemory: true)
inMemoryManager.setup(storeFolder: storeFolder) { result in
	// ...
}
```

## Creating Context

The default context is the main context which is also used by the UI. The main context can be used for any data manipulation and gets persisted when `persist` is called.

```
let context = manager.mainContext
// Modify the "context" or objects on it.
manager.persist()
```

Alternatively, create a new context which also can be used on a background thread when created there and later save and persist it back to the main context:

```
let backgroundContext = manager.createNewContext()
// Modify "contextOnABackground" or objects on it.
manager.persist(fromBackgroundContext: backgroundContext)
```

Usually it's recommended to use a new background context rather than using the main context because the main context acts on the main thread and thus might have a negative impact on the UI when doing heavy processing on it.

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

`item` is of type `Item` which is a `NSManagedObject`.

This will trigger an event immediately whenever a property of the item instance has been updated. 

To not get events for any change, but only when the item has been saved, then use `.contextSaved` as the `notificationType` instad.

And to get also events when the item instance has been inserted or deleted from the context, then provide these `changeTypes`, e.g. `[.updated, .inserted, .deleted]` or simply `.allCases`.

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
	// Each insertion, deletion and update will trigger its own event now.
}
.store(in: &cancellables)
```

This will create new events when a context gets saved. However, that might involve multiple different changes and even upon different objects, i.e. when modifying 2 different objects and deleting a third one will trigger only two events (updated and deleted), but with two objects in the list of the updated event.

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
	// All insertions, deletions and updates will now be representd by onle one single event.
}
.store(in: &cancellables)
```

This publisher is only applicable for `contextSaved` notifications (otherwise it won't be possible that multiple change types happen on the same time).

