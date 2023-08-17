//
//  FTRecentSearchStorage.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSNotification.Name  {
    static let recentSearchesAdded = NSNotification.Name(rawValue: "FTRecentSearchesAddedNotification")
    static let recentSearchesRemoved = NSNotification.Name(rawValue: "FTRecentSearchesRemovedNotification")
    static let recentSearchesCleared = NSNotification.Name(rawValue: "FTRecentSearchesClearedNotification")
}

private let FTRecentSearchesKey = "FTRecentSearchesKey"
private let MAX_ALLOWED_RECENTS: Int = 5

class FTRecentSearchStorage: NSObject {
    static let shared = FTRecentSearchStorage()

    private var searchedRecents: [[FTRecentSearchedItem]] {
        get {
            let standardUserDefaults = UserDefaults.standard;
            if let recentsData = standardUserDefaults.value(forKey: FTRecentSearchesKey) as? Data {
                if let recents = try? JSONDecoder().decode([[FTRecentSearchedItem]].self, from: recentsData) {
                    return recents
                }
            }
            return []
        }
        set {
            if let recentsData = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(recentsData, forKey: FTRecentSearchesKey)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    func availableRecents() -> [[FTRecentSearchedItem]] {
        return self.searchedRecents
    }

    func clear(){
        objc_sync_enter(self)
        self.searchedRecents = []
        objc_sync_exit(self)
        NotificationCenter.default.post(name: .recentSearchesCleared, object: nil)
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
        if existingList.count > MAX_ALLOWED_RECENTS {
            existingList.removeLast()
        }
        self.searchedRecents = existingList
        objc_sync_exit(self)
        NotificationCenter.default.post(name: .recentSearchesAdded, object: item)
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
        NotificationCenter.default.post(name: .recentSearchesRemoved, object: item)
    }
}

class FTRecentSearchedItem: Codable {
    var type: FTSuggestionType = .text
    var name: String = ""
    
    init(type: FTSuggestionType, name: String) {
        self.type = type
        self.name = name
    }
    
    func isEqual(to obj: FTRecentSearchedItem) -> Bool {
        if self.type == obj.type && self.name == obj.name {
            return true
        }
        return false
    }
}
