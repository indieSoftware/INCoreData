import Combine
@testable import INCoreData
import XCTest

class CoreDataManager_PublisherTests: XCTestCase {
	private var subscriptions = Set<AnyCancellable>()

	override func setUp() {
		setUp()
		subscriptions.removeAll()
	}

	override func tearDown() {
		tearDown()
		subscriptions.removeAll()
	}

	// MARK: - publisher for object

	// MARK: - publisher for type

	/*
	 /// OnChange / Update
	 func testUpdateOnChangeProperty() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.updated])
	 			.sink(receiveValue: { project, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				XCTAssertEqual(project?.name, "New name")
	 				expectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Update
	 func testUpdateOnDidSaveProperty() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { project, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				XCTAssertEqual(project?.name, "New name")
	 				expectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"
	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Update - won't happen if not context saved
	 func testUpdateOnDidSavePropertyWontHappen() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()
	 	expectation.isInverted = true

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { project, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				XCTAssertEqual(project?.name, "New name")
	 				expectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// OnChange / Update - adding to relationship set
	 func testUpdateOnChangeRelationshipSet() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.updated])
	 			.sink(receiveValue: { project, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				XCTAssertEqual(project?.photoGalleryAssets?.count, 1)
	 				expectation.fulfill()
	 			})
	 	)

	 	// Create Digital Prints
	 	let galleryAsset = PhotoGalleryAsset(context: coreDataManager.mainContext)
	 	galleryAsset.localIdentifier = "123"
	 	galleryAsset.modificationDate = Date()
	 	galleryAsset.uniqueIdentifer = UUID()
	 	galleryAsset.originalImageUrl = URL(string: "/file")!
	 	try coreDataManager.mainContext.save()

	 	project.addToPhotoGalleryAssets(galleryAsset)

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 func testThatSavingOnBackgroundContextWillTriggerChangedNotificationOnMain() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let backgroundContext = coreDataManager.getAdditionalContext()
	 	let project = createDigitalPrintsProject(inContext: backgroundContext)

	 	let didSaveExpectation = XCTestExpectation()
	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: backgroundContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { _, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				didSaveExpectation.fulfill()
	 			})
	 	)

	 	let updateExpectation = XCTestExpectation()
	 	let projectInMainContext = project.inContext(coreDataManager.mainContext)
	 	subscriptions.insert(
	 		coreDataManager.publisher(for: projectInMainContext, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.updated])
	 			.sink(receiveValue: { _, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				updateExpectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"
	 	try backgroundContext.save()

	 	wait(for: [didSaveExpectation, updateExpectation], timeout: 0.5)
	 }

	 /// DidSave / Update - adding to relationship set won't happen if context not saved
	 func testUpdateOnDidSaveRelationshipSetWontHappen() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()
	 	expectation.isInverted = true

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { project, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				XCTAssertEqual(project?.photoGalleryAssets?.count, 1)
	 				expectation.fulfill()
	 			})
	 	)

	 	// Create Digital Prints
	 	let galleryAsset = PhotoGalleryAsset(context: coreDataManager.mainContext)
	 	galleryAsset.localIdentifier = "123"
	 	galleryAsset.modificationDate = Date()
	 	galleryAsset.uniqueIdentifer = UUID()
	 	galleryAsset.originalImageUrl = URL(string: "/file")!
	 	try coreDataManager.mainContext.save()

	 	project.addToPhotoGalleryAssets(galleryAsset)

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Update - adding to relationship set
	 func testUpdateOnDidSaveRelationshipSet() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { project, changeType in
	 				XCTAssertEqual(changeType, .updated)
	 				XCTAssertEqual(project?.photoGalleryAssets?.count, 1)
	 				expectation.fulfill()
	 			})
	 	)

	 	// Create Digital Prints
	 	let galleryAsset = PhotoGalleryAsset(context: coreDataManager.mainContext)
	 	galleryAsset.localIdentifier = "123"
	 	galleryAsset.modificationDate = Date()
	 	galleryAsset.uniqueIdentifer = UUID()
	 	galleryAsset.originalImageUrl = URL(string: "/file")!
	 	try coreDataManager.mainContext.save()

	 	project.addToPhotoGalleryAssets(galleryAsset)
	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DIdSave / Insert
	 func testInsertOnDidSave() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = DigitalPrintsProject(context: coreDataManager.mainContext)
	 	project.uniqueIdentifier = UUID()
	 	project.createdDate = Date()

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.inserted])
	 			.sink(receiveValue: { _, changeType in
	 				XCTAssertEqual(changeType, .inserted)
	 				expectation.fulfill()
	 			})
	 	)

	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// OnChange / Delete
	 func testDeleteOnChange() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.deleted])
	 			.sink(receiveValue: { _, changeType in
	 				XCTAssertEqual(changeType, .deleted)
	 				expectation.fulfill()
	 			})
	 	)

	 	coreDataManager.mainContext.delete(project)

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Delete - won't happen if context not saved
	 func testDeleteWontOccurOnDidSave() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()
	 	expectation.isInverted = true

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.deleted])
	 			.sink(receiveValue: { _, changeType in
	 				XCTAssertEqual(changeType, .deleted)
	 				expectation.fulfill()
	 			})
	 	)

	 	coreDataManager.mainContext.delete(project)

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Delete
	 func testDeleteDidSave() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.deleted])
	 			.sink(receiveValue: { _, changeType in
	 				XCTAssertEqual(changeType, .deleted)
	 				expectation.fulfill()
	 			})
	 	)

	 	coreDataManager.mainContext.delete(project)
	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 // MARK: Object type observing tests

	 /// OnChange / Insert - observing types
	 func testInsertOnChangeForType() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())

	 	let expectation = XCTestExpectation()
	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.inserted])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .inserted)
	 				expectation.fulfill()
	 			})
	 	)

	 	let project = DigitalPrintsProject(context: coreDataManager.mainContext)
	 	project.uniqueIdentifier = UUID()
	 	project.createdDate = Date()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Insert - observing types
	 func testInsertDidSaveForType() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())

	 	let expectation = XCTestExpectation()
	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.inserted])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .inserted)
	 				expectation.fulfill()
	 			})
	 	)

	 	let project = DigitalPrintsProject(context: coreDataManager.mainContext)
	 	project.uniqueIdentifier = UUID()
	 	project.createdDate = Date()
	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Insert - observing types won't happen when context is not saved
	 func testInsertDidSaveForTypeWontHappen() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())

	 	let expectation = XCTestExpectation()
	 	expectation.isInverted = true
	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.inserted])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .inserted)
	 				expectation.fulfill()
	 			})
	 	)

	 	let project = DigitalPrintsProject(context: coreDataManager.mainContext)
	 	project.uniqueIdentifier = UUID()
	 	project.createdDate = Date()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// OnChange / Update - observing types
	 func testUpdateOnUpdateForType() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.updated])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .updated)
	 				expectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Update - observing types
	 func testUpdateOnDidSaveForType() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .updated)
	 				expectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"
	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Update - observing types won't happen when context is not saved
	 func testUpdateOnDidSaveForTypeWontHappen() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()
	 	expectation.isInverted = true

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .updated)
	 				expectation.fulfill()
	 			})
	 	)

	 	project.name = "New name"

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// OnChange / Delete - observing types
	 func testDeleteOnUpdateForType() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .changed, changeTypes: [.deleted])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .deleted)
	 				expectation.fulfill()
	 			})
	 	)

	 	coreDataManager.mainContext.delete(project)

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Delete - observing types
	 func testDeleteOnDidSaveForType() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.deleted])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .deleted)
	 				expectation.fulfill()
	 			})
	 	)

	 	coreDataManager.mainContext.delete(project)
	 	try coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 /// DidSave / Delete- observing types won't happen when context is not saved
	 func testDeleteOnDidSaveForTypeWontHappen() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let expectation = XCTestExpectation()
	 	expectation.isInverted = true

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: DigitalPrintsProject.self, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.deleted])
	 			.sink(receiveValue: { changes in
	 				XCTAssertEqual(changes.first?.1, .updated)
	 				expectation.fulfill()
	 			})
	 	)

	 	coreDataManager.mainContext.delete(project)

	 	wait(for: [expectation], timeout: 0.5)
	 }

	 func testPhotoGalleryAssetRelationshipSetWorks() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let creationDate = Date()
	 	let originalImageUrl = URL(string: "/file")!
	 	let expectation = XCTestExpectation()

	 	subscriptions.insert(
	 		coreDataManager.publisher(for: project, in: coreDataManager.mainContext, notificationType: .didSave, changeTypes: [.updated])
	 			.sink(receiveValue: { project, _ in
	 				XCTAssertEqual(project?.photoGalleryAssets?.first?.creationDate, creationDate)
	 				XCTAssertEqual(project?.photoGalleryAssets?.first?.originalImageUrl, originalImageUrl)
	 				XCTAssertEqual(project?.photoGalleryAssets?.first?.project, project)
	 				expectation.fulfill()
	 			})
	 	)

	 	let photoGalleryAsset = PhotoGalleryAsset(context: coreDataManager.mainContext)
	 	photoGalleryAsset.uniqueIdentifer = UUID()
	 	photoGalleryAsset.creationDate = creationDate
	 	photoGalleryAsset.originalImageUrl = originalImageUrl
	 	photoGalleryAsset.localIdentifier = "123"
	 	photoGalleryAsset.modificationDate = Date()
	 	photoGalleryAsset.project = project
	 	try? coreDataManager.mainContext.save()

	 	wait(for: [expectation], timeout: 0.5)
	 }
	 */
}
