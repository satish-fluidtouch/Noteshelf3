//
//  FTSearchResultBook.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 27/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchResultBook: NSObject, FTSearchResultBookProtocol {
    weak var parentSection: FTSearchSectionProtocol?
    var title: String {
        return shelfItem?.displayTitle ?? ""
    }
    weak var shelfItem: FTShelfItemProtocol?
    convenience init(with item:FTShelfItemProtocol) {
        self.init()
        self.shelfItem = item
    }
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
}
