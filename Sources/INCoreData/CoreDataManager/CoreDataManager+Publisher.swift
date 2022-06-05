import Combine
import CoreData

public extension CoreDataManager {
	/**
	 Returns a publisher which emits events for changes on a managed object.

	 - parameter managedObject: The object for which to listen for changes.
	 - parameter context: The context of the managed object.
	 - parameter notificationType: The type of notification (change or save) to listen for.
	 - parameter changeTypes: The type of change (insert, delete, update) to listen for.
	 - returns: The publisher.
	 */
	func publisher<ManagedObjectType: NSManagedObject>(
		managedObject: ManagedObjectType,
		context: NSManagedObjectContext, // TODO: Is this really needed?
		notificationType: ManagedNotification,
		changeTypes: [ChangeType]
	) -> AnyPublisher<ManagedObjectChange<ManagedObjectType>, Never> {
		NotificationCenter.default
			// The publisher emits the notification of the context.
			.publisher(for: notificationType.name, object: context)
			// Map the notification to the desired event and ignore nil values.
			.compactMap { notification -> ManagedObjectChange<ManagedObjectType>? in
				// Process only notifications for the change types we are interested in.
				for changeType in changeTypes {
					// The notification's userInfo contains all managed objects of the specific change type,
					if let objects = notification.userInfo?[changeType.rawValue] as? Set<NSManagedObject>,
					   // but we are only interested in one managed object
					   objects.contains(where: { $0.objectID == managedObject.objectID }),
					   // and when we can retrieve an updated version from the context.
					   let object = context.object(with: managedObject.objectID) as? ManagedObjectType
					{
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
	 Returns a publisher which emits events for changes on any object of a specifc type of a managed object inside of a given context.

	 - parameter managedObjectType: The type of managed object for which to listen for changes.
	 - parameter context: The context on which to listen for the changes.
	 - parameter notificationType: The type of notification (change or save) to listen for.
	 - parameter changeTypes: The type of change (insert, delete, update) to listen for.
	 The provided order is repsected when emitting new events when multiple change types are applied at once.
	 - returns: The publisher.
	 */
	func publisher<ManagedObjectType: NSManagedObject>(
		managedObjectType _: ManagedObjectType.Type, // TODO: Is this really needed?
		context: NSManagedObjectContext,
		notificationType: ManagedNotification,
		changeTypes: [ChangeType]
	) -> AnyPublisher<ManagedObjectsChange<ManagedObjectType>, Never> {
		NotificationCenter.default
			// The publisher emits the notifications of the context.
			.publisher(for: notificationType.name, object: context)
			// Map the notification to the desired events, but emit an event for each change type.
			.flatMap { notification -> AnyPublisher<ManagedObjectsChange<ManagedObjectType>, Never> in
				// We are only interested in specific change types.
				changeTypes.compactMap { type -> ManagedObjectsChange<ManagedObjectType>? in
					// The changed objects are provided in a set for each change type.
					guard let changes = notification.userInfo?[type.rawValue] as? Set<NSManagedObject> else {
						return nil
					}

					// Retrieve all objects corresponding to that change.
					let objects = changes
						// We are only interested in objects of a specific type
						.filter { object in
							object.entity == ManagedObjectType.entity()
						}
						// and when we can retrieve an updated version from the context.
						.compactMap { object in
							context.object(with: object.objectID) as? ManagedObjectType
						}
					// Publish the objects and its change type.
					return ManagedObjectsChange(objects: objects, type: type)
				}
				// Publish each change type separately.
				.publisher
				.eraseToAnyPublisher()
			}
			.eraseToAnyPublisher()
	}

	/**
	 Returns a publisher which emits events for changes on any object of a specifc type of a managed object inside of a given context.

	 - parameter managedObjectType: The type of managed object for which to listen for changes.
	 - parameter context: The context on which to listen for the changes.
	 - parameter notificationType: The type of notification (change or save) to listen for.
	 - parameter changeTypes: The type of change (insert, delete, update) to listen for.
	 - returns: The publisher.
	 */
	/*    func publisher<ManagedObjectType: NSManagedObject>(
	     managedObjectType _: ManagedObjectType.Type, // TODO: Is this really needed?
	     context: NSManagedObjectContext,
	     notificationType: ManagedNotification,
	     changeTypes: [ChangeType]
	 ) -> AnyPublisher<[ManagedObjectsChange<ManagedObjectType>], Never> {
	     NotificationCenter.default
	         // The publisher emits the notifications of the context.
	         .publisher(for: notificationType.name, object: context)
	         // Map the notification to the desired event and ignore nil values.
	         .compactMap { notification -> [ManagedObjectsChange<ManagedObjectType>] in
	             // We are only interested in specific change types.
	             changeTypes.compactMap { type -> ManagedObjectsChange<ManagedObjectType>? in
	                 // The changed objects are provided in a set for each change type.
	                 guard let changes = notification.userInfo?[type.rawValue] as? Set<NSManagedObject> else {
	                     return nil
	                 }

	                 // Retrieve all objects corresponding to that change.
	                 let objects = changes
	                     // We are only interested in objects of a specific type
	                     .filter { object in
	                         object.entity == ManagedObjectType.entity()
	                     }
	                     // and when we can retrieve an updated version from the context.
	                     .compactMap { object in
	                         context.object(with: object.objectID) as? ManagedObjectType
	                     }
	                 // Publish the objects and its change type.
	                 return ManagedObjectsChange(objects: objects, type: type)
	             }
	         }
	         .eraseToAnyPublisher()
	 }
	 */
}

/// The published event when a managed object might change.
public struct ManagedObjectChange<ManagedObjectType: NSManagedObject> {
	/// The managed object which has been changed.
	let object: ManagedObjectType
	/// The type of change.
	let type: ChangeType
}

/// The published event when multiple managed objects might change.
public struct ManagedObjectsChange<ManagedObjectType: NSManagedObject> {
	/// The managed objects which have been changed.
	let objects: [ManagedObjectType]
	/// The type of change.
	let type: ChangeType
}

// TODO: Make a struct of this
public enum ChangeType: String, Equatable {
	/// An object has been added to a context.
	case inserted // NSManagedObjectContext.NotificationKey.insertedObjects.rawValue
	/// An object has been deleted from a context.
	case deleted // deletedObjects
	/// An object has been modified / changed.
	case updated // updatedObjects
}
