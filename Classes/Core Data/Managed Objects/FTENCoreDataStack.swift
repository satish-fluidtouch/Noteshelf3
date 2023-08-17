//
//  FTENCoreDataStack.swift
//  Noteshelf
//
//  Created by Akshay on 11/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objcMembers class FTENCoreDataStack: NSObject {
    static let shared = FTENCoreDataStack()
    private override init() {

    }
    //MARK: - Core Data
    lazy var managedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        context.undoManager = nil
        return context
    }()

    lazy var managedObjectModel: NSManagedObjectModel? = {
        let path = Bundle.main.path(forResource: "Noteshelf", ofType: "momd")
        let momURL = URL(fileURLWithPath: path ?? "")
        return NSManagedObjectModel(contentsOf: momURL)
    }()

    @objc lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {

        guard let model = managedObjectModel else { return nil }

        let storeUrl = URL(fileURLWithPath: FTUtils.noteshelfDocumentsDirectory().path).appendingPathComponent("Noteshelf.sqlite")
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: storeUrl.path) {

            if let defaultStoreURL = Bundle.main.url(forResource: "Noteshelf", withExtension: "sqlite") {
                try? fileManager.copyItem(at: defaultStoreURL, to: storeUrl)
            }
        }
        let options = [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferMappingModelAutomaticallyOption : true
        ]
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        do {
            try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        } catch {
            print("Unresolved Core data error \(error)")
            exit(-1)
        }
        return storeCoordinator
    }()

}
