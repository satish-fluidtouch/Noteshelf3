//
//  FTDocumentTagUpdater.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTDocumentTagUpdater: NSObject {
    //MARK:-  Shelf Side bar Operations
    func rename(tag: FTTag, to newName: String,onCompletion: ((_ success: Bool)->())?) -> Progress? {
        let operation = FTTagRename(tag: tag, newTitle: newName);
        return operation.perfomAction(onCompletion);
    }
    
    func delete(tag: FTTag,onCompletion : ((_ success: Bool)->())?) -> Progress? {
        let operation = FTTagDelete(tag: tag);
        return operation.perfomAction(onCompletion);
    }
    

    //MARK:-  Shelf Tag Operation
    func updateTags(_ addedTags: [FTTagModel]
                    , removedTags: [FTTagModel]
                    , entities: [FTTaggedEntity]
                    , onCompletion: @escaping ()->()) -> Progress {
        let progress = Progress();
        var tagGrouped = [String: [FTTaggedEntity]] ();
        entities.forEach { eachEntity in
            var item = tagGrouped[eachEntity.documentUUID] ?? [FTTaggedEntity]();
            item.append(eachEntity);
            tagGrouped[eachEntity.documentUUID] = item;
        }
        progress.totalUnitCount = Int64(tagGrouped.keys.count);

        func performAction(_ oncompeltion: @escaping ()->()) -> Progress? {
            guard let item = tagGrouped.first else {
                oncompeltion();
                return nil;
            }
            
            let subProgress = Progress();
            subProgress.totalUnitCount = 1;
            
            let docID = item.key;
            let taggedEntities = item.value;
            tagGrouped.removeValue(forKey: docID);
            
            FTNoteshelfDocumentProvider.shared.document(with: docID) { documentItem in
                if let docItem = documentItem {
                    subProgress.localizedDescription = "Updating: " + docItem.displayTitle
                    let request = FTDocumentOpenRequest(url: docItem.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            let docPages =  document.pages()
                            taggedEntities.forEach { eachItem in
                                if eachItem.tagType == .book {
                                    addedTags.forEach { eachTag in
                                        document.addTag(eachTag.text)
                                    }
                                    document.removeTags(removedTags.map{$0.text})
                                } else if eachItem.tagType == .page, let pageUUOD = (eachItem as? FTPageTaggedEntity)?.pageUUID {
                                    if let page = docPages.first(where: {$0.uuid == pageUUOD}) as? FTPageTagsProtocol{
                                        addedTags.forEach { eachTag in
                                            page.addTag(eachTag.text)
                                        }
                                        removedTags.forEach { eachTag in
                                            page.removeTag(eachTag.text);
                                        }
                                    }
                                }
                            }
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                                let tagsToAdd = FTTagsProviderV1.shared.getTagsfor(addedTags.map{$0.text});
                                let tagsToRemove = FTTagsProviderV1.shared.getTagsfor(removedTags.map{$0.text});
                                
                                entities.forEach { eachEntity in
                                    tagsToAdd.forEach { eachTag in
                                        eachTag.addTaggedItem(eachEntity);
                                    }
                                    tagsToRemove.forEach { eachTag in
                                        eachTag.removeTaggedItem(eachEntity);
                                    }
                                }
                                FTTagsProviderV1.shared.saveCache();
                                if let subprogress = performAction(oncompeltion) {
                                    progress.addChild(subprogress, withPendingUnitCount: 1);
                                }
                            }
                        }
                        else {
                            if let subprogress = performAction(oncompeltion) {
                                progress.addChild(subprogress, withPendingUnitCount: 1);
                            }
                        }
                    }
                }
                else {
                    progress.completedUnitCount += 1;
                    if let subprogress = performAction(oncompeltion) {
                        progress.addChild(subprogress, withPendingUnitCount: 1);
                    }
                }
            }
            return subProgress;
        }
        
        FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
        DispatchQueue.global().async {
            let subprogress = performAction({
                FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                runInMainThread {
                    onCompletion();
                }
            })
            if let _subProgress = subprogress {
                progress.addChild(_subProgress, withPendingUnitCount: 1);
            }
        }
        return progress;
    }
        
    //MARK:-  Pop UP
    func updateNotebookTags( addedTags: [FTTagModel]
                             , removedTags:[FTTagModel]
                             , documentID: [String]
                             ,onCompletion: (()->())?) -> Progress {
        let progress = Progress();
        progress.totalUnitCount = Int64(documentID.count);
        
        var documentUUIDToProcess = documentID;
        func performAction(_ onCompletion: @escaping ()->()) {
            guard !documentUUIDToProcess.isEmpty else {
                onCompletion();
                return;
            }
            let docID = documentUUIDToProcess.removeFirst();
            FTNoteshelfDocumentProvider.shared.document(with: docID) { documentItem in
                if let docItem = documentItem {
                    progress.localizedDescription = "Updating: " + docItem.displayTitle
                    let request = FTDocumentOpenRequest(url: docItem.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            addedTags.forEach { eachTag in
                                document.addTag(eachTag.text);
                            }
                            document.removeTags(removedTags.map{$0.text})
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: document, token: token) { _ in
                                let tagsToAdd = FTTagsProviderV1.shared.getTagsfor(addedTags.map{$0.text});
                                let tagsToRemove = FTTagsProviderV1.shared.getTagsfor(removedTags.map{$0.text});
                                
                                let docName = document.URL.deletingPathExtension().lastPathComponent;
                                var item: FTTaggedEntity?;
                                if let taggedEntity = FTTagsProviderV1.shared.tagggedEntity(docID, pageID: nil) {
                                    item = taggedEntity;
                                    item?.documentName = docName;
                                }
                                else if !tagsToAdd.isEmpty {
                                    item = FTTagsProviderV1.shared.createTaggedEntity(docID, documentName: docName);
                                }

                                if let eachEntity = item {
                                    tagsToAdd.forEach { eachTag in
                                        eachTag.addTaggedItem(eachEntity);
                                    }
                                    tagsToRemove.forEach { eachTag in
                                        eachTag.removeTaggedItem(eachEntity);
                                    }
                                }
                                FTTagsProviderV1.shared.saveCache();
                                progress.completedUnitCount += 1;
                                performAction(onCompletion)
                            }
                        }
                        else {
                            progress.completedUnitCount += 1;
                            performAction(onCompletion)
                        }
                    }
                }
                else {
                    progress.completedUnitCount += 1;
                    performAction(onCompletion)
                }
            }
        }
        
        runInMainThread {
            FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
            performAction({
                FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                onCompletion?();
            })
        }
        return progress;
    }
        
    
    func updatePageTags( addedTags: [FTTagModel],
                         removedTags: [FTTagModel],
                         document: FTDocumentProtocol,
                         pages: [FTPageProtocol]) {
        let documentName = document.URL.deletingPathExtension().lastPathComponent
        addedTags.forEach { eachTag in
            if let tag = FTTagsProviderV1.shared.getTagsfor([eachTag.text]).first {
                pages.forEach { eachPage in
                    let docProperties = FTTaggedPageProperties();
                    docProperties.pageIndex = eachPage.pageIndex();
                    docProperties.pageSize = eachPage.pdfPageRect;
                    
                    let item: FTTaggedEntity
                    if let pageEntity = FTTagsProviderV1.shared.tagggedEntity(document.documentUUID, pageID: eachPage.uuid) as? FTPageTaggedEntity {
                        item = pageEntity;
                        
                        pageEntity.documentName = documentName
                        pageEntity.updatePageProties(docProperties);
                    }
                    else {
                        item = FTTagsProviderV1.shared.createTaggedEntity(document.documentUUID
                                                                          , documentName: documentName
                                                                          , pageID: eachPage.uuid
                                                                          , pageProperties: docProperties);
                    }
                    tag.addTaggedItem(item);
                }
            }
        }
        
        removedTags.forEach { eachTag in
            if let tag = FTTagsProviderV1.shared.getTagsfor([eachTag.text]).first {
                pages.forEach { eachPage in
                    if let pageEntity = FTTagsProviderV1.shared.tagggedEntity(document.documentUUID, pageID: eachPage.uuid) as? FTPageTaggedEntity {
                        tag.removeTaggedItem(pageEntity);
                        pageEntity.documentName = documentName

                        let docProperties = FTTaggedPageProperties();
                        docProperties.pageIndex = eachPage.pageIndex();
                        docProperties.pageSize = eachPage.pdfPageRect;
                        
                        pageEntity.updatePageProties(docProperties);
                    }
                }
            }
        }
    }
}
