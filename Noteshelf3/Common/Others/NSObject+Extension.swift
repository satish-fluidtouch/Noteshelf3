//
//  NSObject+Extension.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/06/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSObject {
    enum FTNoteshelfSessionID: Int {
        case openNotebook, openGroup, openShelf, openContent, openTag;
        
        var activityIdentifier: String {
            guard let bundleID = Bundle.main.bundleIdentifier else {
                fatalError("Where's the bundle id?")
            }
            var identifier = bundleID;
            switch self {
            case .openNotebook:
                identifier = identifier.appending(".openNotebook.newSession")
            case .openGroup:
                identifier = identifier.appending(".openGroup.newSession")
            case .openShelf:
                identifier = identifier.appending(".openShelf.newSession")
            case .openContent:
                identifier = identifier.appending(".openContent.newSession")
            case .openTag:
                identifier = identifier.appending(".openTag.newSession")
            }
            return identifier;
        }
    }
    
    func openItemInNewWindow(_ item: FTDiskItemProtocol,pageIndex : Int?, pageUUID: String? = nil, docPin: String? = nil, createWithAudio: Bool = false, isQuickCreate: Bool = false) {
        if let shelf = item as? FTShelfItemCollection {
            self.openShelfInNewWindow(shelf)
        }
        else if let groupItem = item as? FTGroupItemProtocol {
            self.openGroupInNewWindow(groupItem)
        }
        else if let shelfItem = item as? FTDocumentItemProtocol {
            self.openNotebookItemInNewWindow(shelfItem,pageIndex: pageIndex,pageUUID: pageUUID, docPin: docPin, createWithAudio: createWithAudio, isQuickCreate: isQuickCreate)
        }
        FTFinderEventTracker.trackFinderEvent(with: "quickaccess_book_openinnewwindow_tap")
    }
    
    func openContentItemInNewWindow(_ contentType: FTSideBarItemType){
        self.openNonCollectionTypeInNewWindow(contentType: contentType,selectedTag:"")
    }
    
    func openTagItemInNewWindow(selectedTag: String){
        self.openNonCollectionTypeInNewWindow(contentType: .tag,selectedTag:selectedTag)
    }
    
    private func openNotebookItemInNewWindow(_ shelfItem: FTShelfItemProtocol,pageIndex : Int?, pageUUID: String? = nil, docPin: String?, createWithAudio: Bool, isQuickCreate: Bool)
    {
        let sourceURL = shelfItem.URL
        let userActivityID = FTNoteshelfSessionID.openNotebook.activityIdentifier;
        let title = sourceURL.deletingPathExtension().lastPathComponent
        let userActivity = NSUserActivity(activityType: userActivityID)
        userActivity.title = title
        userActivity.isAllNotesMode = false
        userActivity.isInNonCollectionMode = false
        // To find the index of page especially during linking
        if let pageId = pageUUID {
            let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
            if let passcode = docPin {
                request.pin = passcode
            }
            FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                if let doc = document {
                    if let index = doc.pages().firstIndex(where: {$0.uuid == pageId}) {
                        userActivity.currentPageIndex = index;
                    } else if let pgIndex = pageIndex {
                        userActivity.currentPageIndex = pgIndex;
                    }
                    FTNoteshelfDocumentManager.shared.closeDocument(document: doc, token: token, onCompletion: nil)
                    handleBookOpen()
                }
            }
        }
        else if let pgIndex = pageIndex {
            userActivity.currentPageIndex = pgIndex
            handleBookOpen()
        } else {
            handleBookOpen()
        }

        func handleBookOpen() {
            var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
            let docPath = sourceURL.relativePathWRTCollection();
            userInfo[LastOpenedDocumentKey] = docPath;

            if let collectionName = docPath.collectionName() {
                userInfo[LastSelectedCollectionKey] = collectionName;
            }
            if docPath.deletingLastPathComponent.pathExtension == FTFileExtension.group {
                userInfo[LastOpenedGroupKey] = docPath.deletingLastPathComponent
            }
            if let _docPin = docPin {
                userInfo["docPin"] = _docPin;
            }
            userActivity.userInfo = userInfo
            userActivity.createWithAudio = createWithAudio
            userActivity.isQuickCreate = isQuickCreate
#if targetEnvironment(macCatalyst)
            if let sesssion = UIApplication.shared.sessionForDocument(docPath) {
                sesssion.scene?.userActivity?.currentPageIndex = userActivity.currentPageIndex
                UIApplication.shared.requestSceneSessionActivation(sesssion
                                                                   , userActivity: userActivity
                                                                   , options: nil
                                                                   , errorHandler: nil)
            }
            else {
                userActivity.becomeCurrent();
                UIApplication.shared.requestSceneSessionActivation(nil
                                                                   , userActivity: userActivity
                                                                   , options: nil
                                                                   , errorHandler: nil)
            }
#else
            userActivity.becomeCurrent();
            UIApplication.shared.requestSceneSessionActivation(nil
                                                               , userActivity: userActivity
                                                               , options: nil
                                                               , errorHandler: nil)
#endif
        }
    }

    private func openShelfInNewWindow(_ shelf: FTShelfItemCollection) {
        let userActivityID = FTNoteshelfSessionID.openShelf.activityIdentifier;
        let userActivity = NSUserActivity(activityType: userActivityID)
        userActivity.title = shelf.displayTitle
        userActivity.isAllNotesMode = false
        userActivity.isInNonCollectionMode = false
        var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
        if let collectionName = shelf.URL.path.collectionName() {
            userInfo[LastSelectedCollectionKey] = collectionName
            userActivity.lastSelectedCollection = collectionName
        }
        userActivity.userInfo = userInfo
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
    }

    private func openGroupInNewWindow(_ groupItem : FTGroupItemProtocol) {
        let userActivityID = FTNoteshelfSessionID.openGroup.activityIdentifier;
        let userActivity = NSUserActivity(activityType: userActivityID)
        userActivity.isAllNotesMode = false
        userActivity.isInNonCollectionMode = false
        userActivity.title = groupItem.displayTitle
        var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
        if let collectionName = groupItem.URL.path.collectionName() {
            userInfo[LastSelectedCollectionKey] = collectionName
            userActivity.lastSelectedCollection = collectionName
        }
        userInfo[LastOpenedGroupKey] = groupItem.URL.relativePathWRTCollection()
        userActivity.userInfo = userInfo
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
    }
    
    private func openNonCollectionTypeInNewWindow(contentType: FTSideBarItemType,selectedTag:String){
        let userActivityID = contentType == .tag ?  FTNoteshelfSessionID.openTag.activityIdentifier : FTNoteshelfSessionID.openContent.activityIdentifier;
        let userActivity = NSUserActivity(activityType: userActivityID)
        userActivity.isInNonCollectionMode = true
        var userInfo = userActivity.userInfo ?? [AnyHashable : Any]();
        userInfo[LastSelectedNonCollectionTypeKey] = contentType.rawValue
        userActivity.lastSelectedNonCollectionType = contentType.rawValue
        if contentType == .tag {
            userInfo[LastSelectedTagKey] = selectedTag
            userActivity.lastSelectedTag = selectedTag
        }
        userActivity.userInfo = userInfo
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
    }
}
