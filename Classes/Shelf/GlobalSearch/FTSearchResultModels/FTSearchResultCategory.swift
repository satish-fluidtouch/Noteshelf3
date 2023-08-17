//
//  FTSearchResultCategory.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 24/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchResultCategory: NSObject, FTSearchResultCategoryProtocol {
    var shelfItemCollection: FTShelfItemCollection?
    weak var parentSection: FTSearchSectionProtocol?
    
    var title: String {
        return shelfItemCollection?.displayTitle ?? ""
    }
    
    convenience init(with shelfCollection: FTShelfItemCollection) {
        self.init()
        self.shelfItemCollection = shelfCollection
    }
    
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
}
