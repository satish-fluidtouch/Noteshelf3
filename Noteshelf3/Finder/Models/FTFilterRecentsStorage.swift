//
//  FTFilterRecentsStorage.swift
//  Noteshelf3
//
//  Created by Sameer on 05/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension NSNotification.Name  {
    static let filterRecentSearchesAdded = NSNotification.Name(rawValue: "FTRecentSearchesAddedNotification")
    static let filterRecentSearchesRemoved = NSNotification.Name(rawValue: "FTRecentSearchesRemovedNotification")
    static let filterRecentSearchesCleared = NSNotification.Name(rawValue: "FTRecentSearchesClearedNotification")
}

private let MAX_ALLOWED_FILTER_RECENTS: Int = 10

class FTFilterRecentsStorage: NSObject {
    static let shared = FTFilterRecentsStorage()
    var documentUUID = ""
    private var key: String {
        return "FTFilterRecentSearchesKey_\(documentUUID)"
    }
    
    private var searchedRecents: [[FTRecentSearchedItem]] {
        get {
            let standardUserDefaults = UserDefaults.standard;
            if let recentsData = standardUserDefaults.value(forKey: key) as? Data {
                if let recents = try? JSONDecoder().decode([[FTRecentSearchedItem]].self, from: recentsData) {
                    return recents
                }
            }
            return []
        }
        set {
            if let recentsData = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(recentsData, forKey: key);
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    func availableRecents() -> [[FTRecentSearchedItem]] {
        return self.searchedRecents
    }
    
    func clear() {
        objc_sync_enter(self)
        self.searchedRecents.removeAll()
        objc_sync_exit(self)
        NotificationCenter.default.post(name: .filterRecentSearchesCleared, object: nil)
    }
    
    func addNewSearchItem(_ item: [FTRecentSearchedItem]) {
        objc_sync_enter(self)
        var existingList = self.searchedRecents
        existingList.removeAll { (recentItem) -> Bool in
            if recentItem.count == item.count {
                return isRecentEqual(currentItem: item, existingItem: recentItem)
            }
            return false
        }
        
        existingList.insert(item, at: 0)
        if existingList.count > MAX_ALLOWED_FILTER_RECENTS {
            existingList.removeLast()
        }
        self.searchedRecents = existingList
        objc_sync_exit(self)
        NotificationCenter.default.post(name: .filterRecentSearchesAdded, object: nil)
    }
    
    private func isRecentEqual(currentItem: [FTRecentSearchedItem], existingItem: [FTRecentSearchedItem]) -> Bool {
        var isEqual = true
        for (index,eachItem) in currentItem.enumerated() {
            let item  = existingItem[index]
            if !eachItem.isEqual(to: item) {
                isEqual = false
            }
        }
        return isEqual
    }
    
    func removeSearchKeyword(_ item: [FTRecentSearchedItem]) {
        objc_sync_enter(self)
        var existingList = self.searchedRecents
        existingList.removeAll { (recentItem) -> Bool in
            return isRecentEqual(currentItem: item, existingItem: recentItem)
        }
        self.searchedRecents = existingList
        objc_sync_exit(self)
        
        NotificationCenter.default.post(name: .filterRecentSearchesRemoved, object: nil)
    }
}
