//
//  FTFinderSearchOptions.swift
//  Noteshelf
//
//  Created by Siva on 20/07/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objcMembers class FTDocumentSearchResults : NSObject {
    var searchedKeyword: String?
    var searchPageResults : [FTPageSearchingInfo]?
}

enum FTFilterOptionMenuItem {
    case all
    case bookmarked
    case tagged
    case outlines
    
    var localizedTitle: String {
        var key = ""
        switch self {
        case .all:
            key = "AllPages"
        case .bookmarked:
            key = "Bookmarked_Filter"
        case .tagged:
            key = "Tagged"
        case .outlines:
            key = "PDFTableOfContents"
        }
        return NSLocalizedString(key, comment: "Filter Item Option Menu")
    }
    var caseName: String{
        var key = ""
        switch self {
        case .all:
            key = "all"
        case .bookmarked:
            key = "bookmarked"
        case .tagged:
            key = "tagged"
        case .outlines:
            key = "outlines"
        }
        return key
    }
}

@objc class FTFinderSearchOptions: NSObject {
    var filterOption: FTFilterOptionMenuItem = FTFilterOptionMenuItem.all
    var selectedTags = [FTTagModel]()
    @objc var documentSearchResults : FTDocumentSearchResults = FTDocumentSearchResults();
    
    @objc var searchedKeyword: String? {
        get {
            return self.documentSearchResults.searchedKeyword;
        }
        set {
            self.documentSearchResults.searchedKeyword = newValue;
        }
    }
    var searchPages : [FTThumbnailable]?;
    
    //for finding and completion callbacks
    var onFinding : (() -> ())?
    var onCompletion : (() -> ())?
    var hasAlreadyShownNS1ContentWarning: Bool = false
    
    @objc func populateSearchPagesIfNeeded(document : FTDocumentProtocol)
    {
        if(self.searchedKeyword?.isEmpty == true) {
            return;
        }
        if(nil != self.searchPages && (self.searchPages?.isEmpty == false)) {
            return;
        }
        let pages = document.pages();
        
        if let searchedUUIDs = self.documentSearchResults.searchPageResults?.map({$0.pageUUID}) {
            let set = Set.init(searchedUUIDs);
            self.searchPages = pages.filter {set.contains($0.uuid)} as? [FTThumbnailable]
        }
    }
    
    deinit {
         #if DEBUG
        debugPrint("\(type(of: self)) is deallocated")
        #endif
    }
}
