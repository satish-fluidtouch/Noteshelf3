//
//  FTDocumentTagUpdater.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

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
    
    func removeAllTags(_ entities:[FTTaggedEntity]) {
        
    }
    
    //MARK:-  Pop UP
    func addNotebookTags( tags: [FTTag], documentID: [String]) {
        
    }
    
    func removeNotebookTags( tags: [FTTag], documentID: [String]) {
        
    }
    
    func addPageTags( tags: [FTTag], documentID: String,pageID: [String]) {
        
    }
    
    func removePageTags( tags: [FTTag], documentID: String,pageID: [String]) {
        
    }
}
