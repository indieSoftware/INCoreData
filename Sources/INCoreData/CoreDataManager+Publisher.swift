import Combine
import CoreData

public extension CoreDataManager {
	/// Helper method that allows us to subscribe to any changes on a ManagedObject inside a specific context
	func publisher<ManagedObjectType: NSManagedObject>(
		managedObject: ManagedObjectType,
		context: NSManagedObjectContext,
		notificationType: ManagedNotification,
		changeTypes: [ChangeType]
	) -> AnyPublisher<(object: ManagedObjectType?, type: ChangeType), Never> {
		let notification = notificationType.notificationName
		return NotificationCenter.default
			.publisher(for: notification, object: context)
			.compactMap { notification in
				for type in changeTypes {
					if let object = self.managedObject(
						objectId: managedObject.objectID,
						changeType: type,
						notification: notification,
						context: context
					) as? ManagedObjectType {
						return (object, type)
					}
				}

				return nil
			}
			.eraseToAnyPublisher()
	}

	private func managedObject(
		objectId: NSManagedObjectID,
		changeType: ChangeType,
		notification: Notification,
		context: NSManagedObjectContext
	) -> NSManagedObject? {
		guard let objects = notification.userInfo?[changeType.rawValue] as? Set<NSManagedObject>,
		      objects.contains(where: { $0.objectID == objectId })
		else {
			return nil
		}

		return context.object(with: objectId)
	}

	/// Helper method that allows us to subscribe to any changes on a type of ManagedObject inside a specific context
	func publisher<ManagedObjectType: NSManagedObject>(
		type: ManagedObjectType.Type,
		context: NSManagedObjectContext,
		notificationType: ManagedNotification,
		changeTypes: [ChangeType]
	) -> AnyPublisher<[([ManagedObjectType], ChangeType)], Never> {
		let notification = notificationType.notificationName
		return NotificationCenter.default
			.publisher(for: notification, object: context)
			.compactMap { notification in
				changeTypes.compactMap { type -> ([ManagedObjectType], ChangeType)? in
					guard let changes = notification.userInfo?[type.rawValue] as? Set<NSManagedObject> else {
						return nil
					}

					let objects = changes
						.filter { object in
							object.entity == ManagedObjectType.entity()
						}
						.compactMap { object in
							context.object(with: object.objectID) as? ManagedObjectType
						}
					return (objects, type)
				}
			}
			.eraseToAnyPublisher()
	}
}

public enum ChangeType: String, CaseIterable, Equatable {
	case inserted, deleted, updated
}

public enum ManagedNotification {
	case changed, didSave

	var notificationName: Notification.Name {
		switch self {
		case .changed:
			return NSManagedObjectContext.didChangeObjectsNotification
		case .didSave:
			return NSManagedObjectContext.didSaveObjectsNotification
		}
	}
}
