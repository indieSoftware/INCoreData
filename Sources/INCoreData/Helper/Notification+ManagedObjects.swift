import CoreData

extension Notification {
	/**
	 Retrieves the `NSManagedObject`s from the notification's `userInfo` dictionary.

	 Usually such a `userInfo` is provided when a `NSManagedObjectContext.didChangeObjectsNotification`
	 or `NSManagedObjectContext.didSaveObjectsNotification` is sent.

	 - parameter changeType: The change type to look for.
	 Uses its notification key to retrieve the objects from the dictionary.
	 - returns: The managed objects provided by the notification.
	 */
	func managedObjects(changeType: ManagedObjectChangeType) -> Set<NSManagedObject>? {
		userInfo?[changeType.notificationKey] as? Set<NSManagedObject>
	}
}
