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
    func rename(tag: FTTag
                , to newName: String
                ,onCompletion: (()->())?) -> Progress? {
        let operation = FTTagRename(tag: tag, newTitle: newName);
        return operation.perfomAction(onCompletion);
    }
    
    func delete(tag: FTTag
                ,onCompletion : (()->())?) -> Progress? {
        let operation = FTTagDelete(tag: tag);
        return operation.perfomAction(onCompletion);
    }
    

    //MARK:-  Shelf Tag Operation
    func updateTags(addedTags: [FTTagModel]
                    , removedTags: [FTTagModel]
                    , entities: [FTTaggedEntity]
                    , onCompletion: (()->())?) -> Progress? {
        let operation = FTTagUpdateTagEntities(addedTags, removedTags: removedTags, entities: entities)
        return operation.perfomAction(onCompletion);
    }

    func updateNotebookTags(addedTags: [FTTagModel]
                            , removedTags:[FTTagModel]
                            , documentIDs: [String]
                            , onCompletion: (()->())?) -> Progress? {
        let operation = FTTagUpdateNotebook(addedTags, removedTags: removedTags, docIDs: documentIDs)
        return operation.perfomAction(onCompletion);
    }
    
    func updatePageTags( addedTags: [FTTagModel],
                         removedTags: [FTTagModel],
                         document: FTDocumentProtocol,
                         pages: [FTPageProtocol]) {
        let documentName = document.URL.relativePathWRTCollection()
        
        let addedFTTags = FTTagsProvider.shared.getTagsfor(addedTags.map{$0.text});
        let removedFTTags = FTTagsProvider.shared.getTagsfor(removedTags.map{$0.text});
        
        pages.forEach { eachPage in
            let docProperties = FTTaggedPageProperties();
            docProperties.pageIndex = eachPage.pageIndex();
            docProperties.pageSize = eachPage.pdfPageRect;
            
            addedFTTags.forEach { eachTag in
                if let pageEntity = FTTagsProvider.shared.tagggedEntity(document.documentUUID
                                                                          , documentPath: documentName
                                                                          , pageID: eachPage.uuid
                                                                          , createIfNotPresent: true) as? FTPageTaggedEntity {
                    pageEntity.updatePageProties(docProperties);
                    eachTag.addTaggedItem(pageEntity);
                }
            }
            
            removedFTTags.forEach { eachTag in
                if let pageEntity = FTTagsProvider.shared.tagggedEntity(document.documentUUID
                                                                          , documentPath: documentName
                                                                          , pageID: eachPage.uuid) as? FTPageTaggedEntity {
                    eachTag.removeTaggedItem(pageEntity);
                    pageEntity.updatePageProties(docProperties);
                }
            }
        }
        FTTagsProvider.shared.saveCache();
    }
}
