![iOS Version](https://img.shields.io/badge/iOS-16.0+-brightgreen) [![Documentation Coverage](https://indiesoftware.github.io/INCoreData/badge.svg)](https://indiesoftware.github.io/INCoreData)
[![License](https://img.shields.io/github/license/indieSoftware/INCoreData)](https://github.com/indieSoftware/INCoreData/blob/master/LICENSE)
[![GitHub Tag](https://img.shields.io/github/v/tag/indieSoftware/INCoreData?label=version)](https://github.com/indieSoftware/INCoreData)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-success.svg)](https://github.com/apple/swift-package-manager)

[GitHub Page](https://github.com/indieSoftware/INCoreData)

[Documentation](https://indiesoftware.github.io/INCoreData)

**Deprecated: Not maintained anymore**

Because of too many concurrency issues this library is not maintained anymore and will be removed soon.

# INCoreData

A helper library to work with CoreData.

## Overview

The main class is `CoreDataManager` which provides a manager as a fascade to the underlying `PersistentContainer` which simplifies the correct usage of Core Data in an application.
The `PersistentContainer` is deriving from `NSPersistentCloudKitContainer` and thus `CoreDataManager` supports Core Data in the iCloud.

## Installation

### SPM

To include via [SwiftPackageManager](https://swift.org/package-manager) add the repository:

```
https://github.com/indieSoftware/INCoreData.git
```

## Usage

How to use INCoreData: [Usage](https://github.com/indieSoftware/INCoreData/blob/master/docu/UsageExamples.md)

## Advices

### Debug flag

It's recommended to add `-com.apple.CoreData.ConcurrencyDebug 1` as a runtime argument to the scheme to get Xcode errors when using Core Data wrongly and to get hints about potential undetected issues.

### Yield process

Use Xcode 14+ with Swift 5.7 or higher because that fixed some memory issues with Core Data and the async/await concurrency feature. As `CoreDataManager_MemoryLeakTests` shows the contexts and some referenced managed objects are not properly released. 

However, even with Xcode 14 and Swift 5.7 be aware that tests might become flaky, that means they might sometimes pass and sometimes fail because a context or object is not released in time. For the objects to get released it's necessary to yield the main queue to give the system the chance to clean up those release pools. For that the lib's project uses a `XCTestCase.yieldProcess()` method which just sleeps for one nanosecond. 

Just keep that in mind for own app tests when using Core Data.

## Further documentation

Good resources for the general usage of CoreData:

- [https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html)
- [https://developer.apple.com/documentation/coredata](https://developer.apple.com/documentation/coredata)
- [https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/creating_a_core_data_model_for_cloudkit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/creating_a_core_data_model_for_cloudkit)
- [https://www.advancedswift.com/core-data-background-fetch-save-create](https://www.advancedswift.com/core-data-background-fetch-save-create)
- [https://cocoacasts.com/building-the-perfect-core-data-stack-with-nspersistentcontainer/](https://cocoacasts.com/building-the-perfect-core-data-stack-with-nspersistentcontainer/)
