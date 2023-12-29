//
//  FTSearchable.swift
//  Noteshelf
//
//  Created by Amar on 15/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTPageSearchProtocol : NSObjectProtocol
{
    var searchingInfo : FTPageSearchingInfo? {get set};
    
    @objc @discardableResult func searchFor(_ searchKey : String,tags : [String],isGlobalSearch: Bool) -> Bool;
}


@objc protocol FTDocumentSearchProtocol : NSObjectProtocol
{
    //search key/tag
    func searchDocumentsForKey(_ searchKey : String,
                               tags : [String],
                               isGlobalSearch: Bool,
                               onFinding : @escaping (_ page : FTPageProtocol,_ cancelled : Bool) -> Void,
                               onCompletion : @escaping (_ cancelled : Bool) -> Void) -> Progress;
    
    func cancelSearchOperation(onCompletion: (() -> ())?);
}

@objc protocol FTSearchableItem : NSObjectProtocol {
    var selectionRect : CGRect {get set};
    var searchType : FTSearchableItemType {get set};
}

@objc enum FTSearchableItemType : Int {
    case none
    case annotation
    case pdfText
    case handWritten
}

@objc class FTSearchItem: NSObject,FTSearchableItem
{
    var selectionRect: CGRect;
    var searchType : FTSearchableItemType = .none
    init(withRect rect : CGRect,type : FTSearchableItemType) {
        self.selectionRect = rect;
        self.searchType = type;
    }
}
