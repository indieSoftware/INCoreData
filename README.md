# INCoreData

A helper library to work with CoreData.

Good resources for the general usage of CoreData:

- [https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html)
- [https://developer.apple.com/documentation/coredata](https://developer.apple.com/documentation/coredata)
- [https://www.advancedswift.com/core-data-background-fetch-save-create](https://www.advancedswift.com/core-data-background-fetch-save-create)
- [https://cocoacasts.com/building-the-perfect-core-data-stack-with-nspersistentcontainer/](https://cocoacasts.com/building-the-perfect-core-data-stack-with-nspersistentcontainer/)

## Feature overview

The main class is `CoreDataManager` which provides a manager as a fascade to the underlying `PersistentContainer` which simplifies the correct usage of Core Data in an application.


## Advices

It's recommended to add `-com.apple.CoreData.ConcurrencyDebug 1` as a runtime argument to the scheme to get Xcode errors when using Core Data wrongly and to get hints about potential undetected issues.
 

## Example of usage

[Examples how to use INCoreData](https://github.com/indieSoftware/INCoreData/blob/master/docu/UsageExamples.md)

