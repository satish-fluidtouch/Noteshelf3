//
//  FTSearchResultPage.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchResultPage: NSObject, FTSearchResultPageProtocol {
    weak var parentSection: FTSearchSectionProtocol?
    var title: String {
        return shelfItem?.displayTitle ?? ""
    }
    weak var shelfItem: FTShelfItemProtocol?
    var searchingInfo: FTPageSearchingInfo?
    convenience init(with searchInfo: FTPageSearchingInfo, item:FTShelfItemProtocol) {
        self.init()
        self.searchingInfo = searchInfo
        self.shelfItem = item
    }
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
}
