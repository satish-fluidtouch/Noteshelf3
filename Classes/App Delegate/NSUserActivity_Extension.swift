//
//  NSUserActivity_Extension.swift
//  StateRestore
//
//  Created by Akshay on 04/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSUserActivity {

    var lastSelectedCollection : String? {
        get {
            let collection = self.userInfo?[LastSelectedCollectionKey] as? String
            return collection;
        }
        set {
            self.userInfo?[LastSelectedCollectionKey] = newValue;
        }
    }

    var lastOpenedGroup : String? {
        get {
            let group = self.userInfo?[LastOpenedGroupKey] as? String;
            return group
        }
        set {
            self.userInfo?[LastOpenedGroupKey] = newValue;
        }
    }

    @objc var lastOpenedDocument : String? {
        get {
            let book = self.userInfo?[LastOpenedDocumentKey] as? String;
            return book
        }
        set {
            self.userInfo?[LastOpenedDocumentKey] = newValue;
        }
    }

    override open var description: String {
        let type = self.activityType
        let title = self.title ?? "nil"
        let userInfo = self.userInfo?.description ?? "nil"
        return "♻️ \(super.description) - Type: \(type) Title: \(title) userinfo:\(userInfo)"
    }
    
    var createWithAudio: Bool {
        get {
            let createWithAudio = self.userInfo?[createWithAudioKey] as? Bool;
            return createWithAudio ?? false
        }
        set {
            self.userInfo?[createWithAudioKey] = newValue;
        }
    }
}

extension NSUserActivity {
    @objc dynamic var sortOrder: FTShelfSortOrder {
        get {
            if let sortBy = self.userInfo?[SortOrderKey] as? Int, let sortByOrder = FTShelfSortOrder(rawValue: sortBy) {
                return sortByOrder
            }
            self.userInfo?[SortOrderKey] = FTUserDefaults.sortOrder().rawValue
            return FTUserDefaults.sortOrder()
        }
        set {
            FTUserDefaults.setSortOrder(newValue)
            self.userInfo?[SortOrderKey] = newValue.rawValue;
        }
    }
    var isAllNotesMode: Bool {
        get {
            if let isAllNotesMode = self.userInfo?[AllNotesModeKey] as? Bool {
                return isAllNotesMode
            }
            self.userInfo?[AllNotesModeKey] = FTUserDefaults.isAllNotesMode()
            return FTUserDefaults.isAllNotesMode()
        }
        set {
            FTUserDefaults.setAllNotesMode(newValue)
            self.userInfo?[AllNotesModeKey] = newValue;
        }
    }
    //This is useful only when using "open in new window" option from Global Search Page Results
    var currentPageIndex: Int? {
        get {
            if let pageIndex = self.userInfo?[CurrentPageIndexKey] as? Int {
                return pageIndex
            }
            return nil;
        }
        set {
            self.userInfo?[CurrentPageIndexKey] = newValue;
        }
    }
}
extension NSUserActivity {
    var lastSelectedTag : String? {
        get {
            let tag = self.userInfo?[LastSelectedTagKey] as? String
            return tag;
        }
        set {
            self.userInfo?[LastSelectedTagKey] = newValue;
        }
    }
    var lastSelectedNonCollectionType : String? {
        get {
            let contentType = self.userInfo?[LastSelectedNonCollectionTypeKey] as? String
            return contentType;
        }
        set {
            self.userInfo?[LastSelectedNonCollectionTypeKey] = newValue;
        }
    }
    var isInNonCollectionMode: Bool {
        get {
            if let isInContentMode = self.userInfo?[NonCollectionModeKey] as? Bool {
                return isInContentMode
            }
            self.userInfo?[NonCollectionModeKey] = FTUserDefaults.isInNonCollectionMode()
            return FTUserDefaults.isInNonCollectionMode()
        }
        set {
            self.userInfo?[NonCollectionModeKey] = newValue;
        }
    }
}
