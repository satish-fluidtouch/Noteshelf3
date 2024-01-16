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
    func remove(tags: [FTTag], entities: [FTTaggedEntity]) {
        
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
