import Combine
import CoreData

public extension CoreDataManager {
	/**
	 Returns a publisher which emits events for changes on a managed object.

	 For example, when registered for changes on object instance A then
	 an event is triggered either when a change on the instance A has been performed or
	 after A's context has been saved, depending on the notification type provided.

	 - parameter managedObject: The object for which to listen for changes.
	 The managed objects must have a managed object context assigned.
	 - parameter notificationType: The type of notification (change or save) to listen for.
	 - parameter changeTypes: The type of change (insert, delete, update) to listen for,
	 e.g. "`ManagedObjectChangeType.allCases`".
	 Only changes matching the provided types will trigger a published event.
	 - returns: The publisher.
	 */
	func publisher<ManagedObjectType: NSManagedObject>(
		managedObject: ManagedObjectType,
		notificationType: ManagedNotification,
		changeTypes: [ManagedObjectChangeType]
	) -> AnyPublisher<ManagedObjectChange<ManagedObjectType>, Never> {
		guard let context = managedObject.managedObjectContext else {
			preconditionFailure("Managed object has no context")
		}
		return NotificationCenter.default
			// The publisher emits the notification of the context.
			.publisher(for: notificationType.name, object: context)
			// Map the notification to the desired event and ignore nil values.
			.compactMap { notification -> ManagedObjectChange<ManagedObjectType>? in
				// Process only notifications for the change types we are interested in.
				for changeType in changeTypes {
					// The notification's userInfo contains all managed objects of the specific change type,
					if let objects = notification.managedObjects(changeType: changeType),
					   // but we are only interested in one managed object
					   objects.contains(where: { $0.objectID == managedObject.objectID }),
					   // and when we can retrieve an updated version from the context.
					   let object = context.object(with: managedObject.objectID) as? ManagedObjectType
					{ // swiftlint:disable:this opening_brace
						// Publish the object and its change type,
						// ignore the other change types because only one can be triggered at the same time.
						return ManagedObjectChange(object: object, type: changeType)
					}
				}
				// Change not of interest, skip event.
				return nil
			}
			.eraseToAnyPublisher()
	}

	/**
	 Returns a publisher which emits events for changes on any object
	 of a specifc type of a managed object inside of a given context.

	 Each change type will trigger a seperate event, but an event may contain multiple changes of the same type.

	 For example, when registered for changes on any object instance of type A then
	 an event is triggered either when a change on an instance of A has been performed or
	 after the context has been saved, depending on the notification type provided.
	 However, when also listening for insertions or deletions then they will emit their own events,
	 so one event only has one type of change.

	 - parameter managedObjectType: The type of the managed object for which to listen for changes.
	 - parameter context: The context on which to listen for the changes.
	 - parameter notificationType: The type of notification (change or save) to listen for.
	 - parameter changeTypes: The type of change (insert, delete, update) to listen for,
	 e.g. "`ManagedObjectChangeType.allCases`".
	 Only changes matching the provided types will trigger a published event.
	 The provided order is repsected when emitting new events when multiple change types are applied at once,
	 i.e. when using `ManagedNotification.contextSaved` as the notification type.
	 - returns: The publisher.
	 */
	func publisher<ManagedObjectType: NSManagedObject>(
		managedObjectType _: ManagedObjectType.Type,
		context: NSManagedObjectContext,
		notificationType: ManagedNotification,
		changeTypes: [ManagedObjectChangeType]
	) -> AnyPublisher<ManagedObjectsChange<ManagedObjectType>, Never> {
		NotificationCenter.default
			// The publisher emits the notifications of the context.
			.publisher(for: notificationType.name, object: context)
			// Map the notification to the desired events, but emit an event for each change type.
			.flatMap { notification in
				// We are only interested in specific change types.
				changeTypes.compactMap { changeType -> ManagedObjectsChange<ManagedObjectType>? in
					// The changed objects are provided in a set for each change type.
					guard let changes = notification.managedObjects(changeType: changeType) else {
						return nil
					}

					// Retrieve all objects corresponding to that change.
					let objects = changes
						// We are only interested in objects of a specific type
						.filter { object in
							// A cast is an expansive call, therefore, look for the entity first.
							object.entity == ManagedObjectType.entity()
						}
						// and when we can retrieve an updated version from the context.
						.compactMap { object in
							context.object(with: object.objectID) as? ManagedObjectType
						}
					// No changes in object types we are interested in?
					guard !objects.isEmpty else {
						return nil
					}
					// Publish the objects and its change type.
					return ManagedObjectsChange(objects: objects, type: changeType)
				}
				// Publish each change type separately.
				.publisher
			}
			.eraseToAnyPublisher()
	}

	/**
	 Returns a publisher which emits events for changes on any object
	 of a specifc type of a managed object inside of a given context.

	 Each notification will result in a single event emitted, even when multiple different types of changes have applied.
	 Only events of the notification type `contextSaved` are published.

	 This is similar to `publisher(managedObjectType:, context:, notificationType:, changeTypes:)`,
	 but here the notification type is always `contextSaved` and all changes will be summarized into a single event.
	 That means when new instances have been inserted and others have been deleted,
	 then this will lead to only one event which contains all changes for both,
	 the insertions and deletions.

	 - parameter managedObjectType: The type of the managed object for which to listen for changes.
	 - parameter context: The context on which to listen for the changes.
	 - parameter changeTypes: The type of change (insert, delete, update) to listen for,
	 e.g. "`ManagedObjectChangeType.allCases`".
	 Only changes matching the provided types will be passed to the published event.
	 The provided order is repsected when emitting new events when multiple change types are applied at once.
	 - returns: The publisher.
	 */
	func publisher<ManagedObjectType: NSManagedObject>(
		managedObjectType _: ManagedObjectType.Type,
		context: NSManagedObjectContext,
		changeTypes: [ManagedObjectChangeType]
	) -> AnyPublisher<[ManagedObjectsChange<ManagedObjectType>], Never> {
		NotificationCenter.default
			// The publisher emits the notifications of the context.
			.publisher(for: ManagedNotification.contextSaved.name, object: context)
			// Map the notification to the desired single event.
			.compactMap { notification -> [ManagedObjectsChange<ManagedObjectType>] in
				// We are only interested in specific change types.
				changeTypes.compactMap { changeType -> ManagedObjectsChange<ManagedObjectType>? in
					// The changed objects are provided in a set for each change type.
					guard let changes = notification.managedObjects(changeType: changeType) else {
						return nil
					}

					// Retrieve all objects corresponding to that change.
					let objects = changes
						// We are only interested in objects of a specific type
						.filter { object in
							// A cast is an expansive call, therefore, look for the entity first.
							object.entity == ManagedObjectType.entity()
						}
						// and when we can retrieve an updated version from the context.
						.compactMap { object in
							context.object(with: object.objectID) as? ManagedObjectType
						}
					// No changes in object types we are interested in?
					guard !objects.isEmpty else {
						return nil
					}
					// Return the objects and its change type.
					return ManagedObjectsChange(objects: objects, type: changeType)
				}
			}
			// Ignore empty events.
			.filter { managedObjectsChanges in
				!managedObjectsChanges.isEmpty
			}
			.eraseToAnyPublisher()
	}
}
