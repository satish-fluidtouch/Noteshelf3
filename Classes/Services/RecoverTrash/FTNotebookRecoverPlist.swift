//
//  FTNotebookRecoverPlist.swift
//  Noteshelf
//
//  Created by Mahesh on 08/07/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework
enum FTBookRecoveryType : Int {
    case pages,book;
}

class FTNotebookRecoverPlist: FTFileItemPlist {
    
    private  let documentUUIDKey = "documentUUID";
    private  let recoverPageIndicesKey = "recover_page_indices";
    private  let recoverLocationKey = "recover_Location";
    private  let bookRecoveryTypeKey = "book_recovery_type";

    var recovertType: FTBookRecoveryType {
        get {
            if let value = self.contentDictionary[bookRecoveryTypeKey] as? NSNumber {
                return FTBookRecoveryType(rawValue: value.intValue) ?? FTBookRecoveryType.pages;
            }
            return FTBookRecoveryType.pages;
         }
        set {
            self.setObject(NSNumber(integerLiteral: newValue.rawValue), forKey: bookRecoveryTypeKey);
        }
    }
    
    var documentUUID:String? {
        get {
            return self.contentDictionary[documentUUIDKey] as? String
        }
        
        set {
            if newValue != nil {
                self.setObject(newValue, forKey: documentUUIDKey)
            }
        }
    }
    
    var recoverLocation: String? {
        get {
            return self.contentDictionary[recoverLocationKey] as? String
        }
        set {
            if let value = newValue {
                self.setObject(value, forKey: recoverLocationKey)
            }
        }
    }
    
    private var pageIndices: [String:Int] {
        get {
            return self.contentDictionary[recoverPageIndicesKey] as? [String:Int] ?? [String:Int]();
        }
        set {
            self.setObject(newValue, forKey: recoverPageIndicesKey);
        }
    }
    
    func addPageIndex(_ index: Int,pageUUID: String) {
        var content = self.pageIndices;
        content[pageUUID] = index;
        self.pageIndices = content;
    }
    
    func pageIndex(pageUUID: String) -> Int? {
        let content = self.pageIndices;
        return content[pageUUID];
    }
}
