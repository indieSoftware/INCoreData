# INCoreData

A helper library to work with CoreData.

Good resources for the general usage of CoreData:

- [https://www.advancedswift.com/core-data-background-fetch-save-create](https://www.advancedswift.com/core-data-background-fetch-save-create)

## Feature overview

The main class is `CoreDataManager` which provides a manager to access the main context, get new background contexts and to persist any changes.

The idea is to have a main context which works on the main thread as the single source of truth.
However, for persisting any changes the main context only saves its changes to a background context which is then responsible for persisting the changes.
That prevents the main thread of being blocked when persisting changes, because that will be then outsourced to the background context.

When creating new contexts via `createNewContext` then they will be linked to the main context so that it's easy to apply some changes on a background thread and then push them back to the main context via `persist(fromBackgroundContext:)` when finished processing. 

## Installation
