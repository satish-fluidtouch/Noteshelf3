//
//  FTSearchSectionTitles.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchSectionTitles: NSObject, FTSearchSectionProtocol {
    var uuid = UUID().uuidString
    var searchKey: String = ""
    var onStatusChange: ((_ section: FTSearchSectionProtocol?, _ isActive: Bool) -> Void)?
    
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
    var contentType: FTSearchContentType {
        return .book
    }
    var title: String {
        return NSLocalizedString("NotebooksAndGroups", comment: "Notebooks and Groups")
    }
    var items: [FTSearchResultProtocol] = [FTSearchResultBookProtocol]()
    weak var sectionHeaderItem: FTDiskItemProtocol?//FTShelfItemCollection
}
