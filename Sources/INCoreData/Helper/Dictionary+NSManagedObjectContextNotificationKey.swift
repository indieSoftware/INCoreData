import CoreData

// TODO: Needs fine-tuning, see https://www.donnywals.com/responding-to-changes-in-a-managed-object-context/
extension Dictionary where Key == AnyHashable {
	/**
	 Retrieves the `NSManagedObject`s from a `userInfo` dictionary depending on the
	 `NSManagedObjectContext.NotificationKey`.

	 Usually such a `userInfo` is provided when a `NSManagedObjectContext.didChangeObjectsNotification`
	 or `NSManagedObjectContext.didSaveObjectsNotification` is sent.

	 - parameter key: The notification key.
	 - returns: The concrete managed object.
	 */
	func value<T>(for key: NSManagedObjectContext.NotificationKey) -> T? {
		self[key.rawValue] as? T
	}
}
