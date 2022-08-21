
# Usage Examples

## Set up

Create an instance of the manager:

```
import INCoreData

let manager: CoreDataManager = CoreDataManagerLogic()
```

This will use the data model named "DataModel" from the main bundle and use the path "CoreData" inside of the documents folder to persist the Core Data stack.

If the "xcdatamodelId" file differes, is not in the main bundle or a different folder name in the documents folder should be used then provide those information to the init method.

```
let manager: CoreDataManager = CoreDataManagerLogic(
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
		coreDataManager = CoreDataManagerLogic(inMemory: true)

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
			let manager = CoreDataManagerLogic(inMemory: true)
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

### Listening for any changes on a context when saves

To listen for any kind of changes on a context use the following publisher:

```
manager.publisher(
	context: manager.mainContext, // Listen for all changes on the main context
	changeTypes: .allCases // Any change is relevant, including insertion and deletion
)
.sink { (changes: [ManagedObjectsChange<NSManagedObject>]) in
	print("Change on main context: \(changes)")
}
.store(in: &cancellables)
```

This might be useful for logging any CoreData changes or when listening for changes on a specific background context.

## Other helper

### Retrieving an object from a context

There exists a `NSManagedObject` extension which makes it easy to retrieve a given object, but in a different context. This might be useful when an object has already been created or retrieved in a different context and now should be processed further in a new task or context:

```
let itemInMainContext: NSManagedObject!
try await manager.performTask { backgroundContext in
	let itemInBackgroundContext = itemInMainContext.inContext(backgroundContext)
	// Do something with itemInBackgroundContext...
}
```

The same can be done with a model:

```
let modelInMainContext: Model!
try await manager.performTask { backgroundContext in
	let modelInBackgroundContext = modelInMainContext.inContext(backgroundContext)
	// Do something with itemInBackgroundContext...
}
```

## Models

The managed objects from CoreData have mostly an awkward interface. Often the properties are optionals when they should not be, or they are of a type like `Int32` or a data object instead of a concrete type. That means, instead of usign the managed object directly it's often adviceable to wrap it by a facade or model.

To simplify this two protocols are provided by the framework which goes hand in hand: `ManagedObjectModelWrapping` and `ManagedObjectWrappingModel`.

For example, there is a managed object named `Foo` which has two properties `var title: String?` and `var number: Int32`. Now create a custom model for that managed object and make it conform to `ManagedObjectWrappingModel` and add also an extension to the managed Foo object to conform it to `ManagedObjectModelWrapping` and link it to the `FooModel`:

```
public struct FooModel: ManagedObjectWrappingModel {
	public let managedObject: Foo

	public init(managedObject: Foo) {
		self.managedObject = managedObject
	}

	public var title: String {
		get {
			guard let title = managedObject.title else {
				preconditionFailure("Title of MO is nil")
			}
			return title
		}
		set {
			managedObject.title = newValue
		}
	}

	public var number: Int {
		get {
			Int(managedObject.number)
		}
		set {
			managedObject.number = Int32(newValue)
		}
	}
}

extension Foo: ManagedObjectModelWrapping {
	public typealias Model = FooModel
}
```

### asModel

This will allow to get a model from that Foo object automatically and to access the properties in a type-safe way:

```
let foo: Foo
let model: FooModel = foo.asModel
let title: String = model.title
let number: Int = model.number
```

There is no casting or unwrapping necessary anymore, because that is done by the wrapping model.

Through the computed properties it's also possible to ensure some logical constraints via `preconditions` to detect programmer errors when assigning a forbidden value, for example. For example when number should always be a positive number or zero by design then we can't model it in CoreData or with a type in our model, but we can at least verify that during the getter and setters of the model:

```
	public var number: Int {
		get {
			let value = Int(managedObject.number)
			precondition(value >= 0)
			return value
		}
		set {
			precondition(newValue >= 0)
			managedObject.number = Int32(newValue)
		}
	}
```

Now when assigning a negative value in code then we notice that via a crash during testing:

```
model.number = 4 // fine
model.number = -4 // precondition triggers!
```

The model, therefore, works as a facade for the underlying managed object. When using a struct rahter than a class for the model then it's also light-weight without loosing the access to the managed object should it still be needed.

### addToContext & removeFromContext

Calling `model.addToContext()` will insert the wrapped managed object to the persistent store on save.

However, instead of calling this method manually it's recommended to add the insert already in an init method when creating a new model:

```
public struct FooModel: ManagedObjectWrappingModel {
	public let managedObject: Foo

	public init(managedObject: Foo) {
		self.managedObject = managedObject
	}

	public init(context: NSManagedObjectContext) {
		managedObject = Foo(context: context)
		context.insert(managedObject)
	}
}
```

When removing a model's reference or when deleting a model then it should also be deleted from its persistent store on save.
To do this just call `model.removeFromContext()`. 

### addModel, removeModel & insertModel

A common case is to add, remove or insert managed objects in a sorted list. 
However, CoreData's support for sorted lists is kind of limited.
To support sorted lists the model has to follow some pattern, but then the model can be easily updated to provide a better interface for adding, removing and inserting.

#### CoreData model

To support sorted lists we are using typical one-to-many relationships with an index property on the second model.
That means the managed object to which the other needs multiple references needs an index property.

For example, `Foo` has a one-to-many relationship to `Bar`. Therefore, `Foo` has a `barRelationship` and `Bar` a reverse `fooRelationship`. To hold the index of `Bar` in the list hold by `Foo` we need to introduce `fooIndex` of a scalar `Int32` type to `Bar`.
 
Not required, but recommended is to add the delete rule `Nullify` to `fooRelationship`and `Cascade` to `barRelationship` to make `Bar` to be deleted when `Foo` gets deleted, but the `Bar` reference in `Foo` gets only removed from the list when deleting a `Bar` instance.

#### Model wrappers

With the Core Data models set up we need to provide the references to the wrapping models.

To `BarModel` we can simply provide the index and the back-reference:

```
var fooIndex: Int {
	Int(managedObject.fooIndex)
}

func setFooIndex(_ newValue: Int) throws {
	precondition(newValue >= 0, "Negative index")
	precondition(newValue < foo.barCount, "Index out of bounds")
	managedObject.fooIndex = Int32(newValue)
}

var foo: FooModel {
	guard let model = managedObject.fooRelationship?.asModel else {
		preconditionFailure("No reference model")
	}
	return model
}
```

Here the `fooIndex` accessors are split into a computed getter property and a setter method. The reason is to be able to throw an exception when setting a value. That way it's possible to throw an error when a precondition is not valid instead of crashing the app. In that case simply replace the precondition calls with a throwing error statement.

In `FooModel` we need to provide the accessor to the bar list:

```
var bars: [BarModel] {
	guard let barSet = managedObject.barRelationship else {
		preconditionFailure("No set")
	}
	let models = barSet.compactMap {
		($0 as? Bar)?.asModel
	}.sorted()
	return models
}
```

And because the `fooIndex` of `BarModel` has a precondition which assures that the index is in bounds we need to provide in `FooModel` the property which returns the number of `BarModel` objects in the list of `FooModel`.
However, we can't simply use `bars` from `FooModel` because that uses the `sorted` method and thus a `Comparable` conformance which will rely on the `fooIndex`.
So, when setting the `fooIndex` it would query the `bars` which will query the `fooIndex` and that multiple times which is quite unnecessary.
Therefore, we are providing the count in a loop-safe way to `FooModel`: 

```
var barCount: Int {
	guard let count = managedObject.barRelationship?.count else {
		preconditionFailure("No set")
	}
	return count
}
```

And as alreay mentioned the `FooModel`'s `bars` property needs to sort the `BarModel`s via the `sorted()` method.
That means we have to add to `BarModel` the `Comparable` conformance:

```
extension BarModel: Comparable {
	public static func < (lhs: BarModel, rhs: BarModel) -> Bool {
		lhs.fooIndex < rhs.fooIndex
	}
}
```

#### add, remove & insert

Now with everything set up we can easily support for adding, removing and inserting of `BarModel`s to a `FooModel`'s list by simply adding the following to `FooModel`:

```
func addBar(_ model: BarModel) throws {
	managedObject.addToBarRelationship(model.managedObject)
	try model.setFooIndex(barCount - 1)
}

func removeBar(_ model: BarModel) throws {
	try model.removeIndex(
		fromModels: bars,
		indexKeyPath: \.fooIndex,
		indexSetter: BarModel.setFooIndex
	)
	managedObject.removeFromBarRelationship(model.managedObject)
}

func insertBar(_ model: BarModel, index: Int) throws {
	managedObject.addToBarRelationship(model.managedObject)
	try model.insertIndex(
		index: index,
		intoModels: bars,
		indexKeyPath: \.fooIndex,
		indexSetter: BarModel.setFooIndex
	)
}
```

We are relying here on a protocol extension of `ManagedObjectWrappingModel` which takes some key paths and method references to provide the logics to insert or remove an index to keep its consistency. 

However, the model's object still needs to be added or removed from the relationship reference. And after removing an object it's highly likely that the object needs also be deleted from the context, which also has to be done manually after removing the object (and its index).

#### Usage

With everything ready we can now easily use this:

```
fooModel.addBar(barModel)
fooModel.removeBar(barModel)
fooModel.insertBar(barModel, index: 0)
```

However, keep in mind that accessing the models needs to be done in a `context.perform {}` block (or a `coreDataManager.performTask {}` block).
That means they should be queried on a view model or additional layer to gather the data, but then the models need to be converted into simpler view models specific for the view which holds only the corresponding data without the need to query the managed objects on their context when accessing the properties.
