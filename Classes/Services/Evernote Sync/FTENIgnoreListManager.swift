//
//  FTENIgnoreListManager.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FirebaseCrashlytics

enum FTENIgnoreReasonType : Int {
    case dataLimitReached
    case fileNotFound
}

class FTENIgnoreEntry: NSObject {
    var title: String?
    var ignoreType: FTENIgnoreReasonType!
    var notebookID: String?
    var shouldDisplay = false
    
    convenience init(title:String,ignoreType:FTENIgnoreReasonType,notebookID:String,shouldDisplay:Bool = false) {
        self.init()
        self.title = title
        self.ignoreType = ignoreType
        self.notebookID = notebookID
        self.shouldDisplay = shouldDisplay
    }
    func description() -> String? {
        return "title:\(String(describing: title))" + "-> type:\(String(describing: ignoreType))" + "->id:\(String(describing: notebookID))"
    }
}

class FTENIgnoreListManager {
    
    private var ignoredNotebooksArray = [FTENIgnoreEntry]()
    static let shared = FTENIgnoreListManager()
    
    func removeNotebook(_ notebookID: String?) {
        
        ignoredNotebooksArray = ignoredNotebooksArray.filter({ (entry) -> Bool in
            return entry.notebookID == notebookID
        })
        postNotification()
    }
    func add(_ ignoreEntry: FTENIgnoreEntry?) {
        if let ignoreEntry = ignoreEntry {
            ignoredNotebooksArray.append(ignoreEntry)
        }
        postNotification()
    }
    
    func clearIgnoreList() {
        UserDefaults.standard.removeObject(forKey: "ENBusinessStoreSyncEnabledBooksCount")
        ignoredNotebooksArray.removeAll()
        postNotification()
    }
    
    func ignoredNotebooksID() -> [String] {
        var ignoreNotebooksID = [String]()
        ignoreNotebooksID = ignoredNotebooksArray.map({($0.notebookID ?? "")})
        return ignoreNotebooksID
    }
    
    func ignoredNotebooks() -> [FTENIgnoreEntry] {
        return ignoredNotebooksArray
    }
    // MARK: Private
    private func postNotification() {
        Crashlytics.crashlytics().setCustomValue(ignoredNotebooksArray.count, forKey: "en_ignored_books")
    }
}
