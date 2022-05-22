import CoreData
@testable import INCoreData
import XCTest

class CoreDataManagerTests: XCTestCase {
	/*
	 func testThatAdditionalContextParentIsMainContext() {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let backgroundContext = coreDataManager.getAdditionalContext()

	 	XCTAssertEqual(backgroundContext.parent, coreDataManager.mainContext)
	 }

	 func testThatObjectsArePushedToPrivateContextFromMain() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let project = createDigitalPrintsProject(inContext: coreDataManager.mainContext)

	 	let fetchRequest: NSFetchRequest<DigitalPrintsProject> = DigitalPrintsProject.fetchRequest()
	 	let projectInMainContext = try coreDataManager.mainContext.fetch(fetchRequest).first
	 	XCTAssertEqual(project.objectID, projectInMainContext?.objectID)

	 	let projectInPrivateContext = try coreDataManager.mainContext.fetch(fetchRequest).first
	 	XCTAssertEqual(project.objectID, projectInPrivateContext?.objectID)
	 }

	 func testThatObjectsArePushedToMainContextFromBackroundContext() throws {
	 	let coreDataManager = CoreDataManager(persistenceStack: PersistenceStack())
	 	let backgroundContext = coreDataManager.getAdditionalContext()

	 	let project = createDigitalPrintsProject(inContext: backgroundContext)

	 	let fetchRequest: NSFetchRequest<DigitalPrintsProject> = DigitalPrintsProject.fetchRequest()
	 	let projectInMainContext = try coreDataManager.mainContext.fetch(fetchRequest).first
	 	XCTAssertEqual(project.objectID, projectInMainContext?.objectID)

	 	let projectInPrivateContext = try backgroundContext.fetch(fetchRequest).first
	 	XCTAssertEqual(project.objectID, projectInPrivateContext?.objectID)
	 }
	 */
}
