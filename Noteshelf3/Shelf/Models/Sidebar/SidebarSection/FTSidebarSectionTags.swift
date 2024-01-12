//
//  FTSidebarSectionTags.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionTags: FTSidebarSection {
    override var supportsRearrangeOfItems: Bool {
        get {
            return false
        }
        set {
        }
    }
    
    override var type: FTSidebarSectionType {
        get {
            .tags;
        }
        set {
            
        }
    }
    
    init() {
        super.init(type: .media, items: [], supportsRearrangeOfItems: false);
        self.prepareItems();
    }
    
    required init(type: FTSidebarSectionType, items: [FTSideBarItem], supportsRearrangeOfItems: Bool) {
        fatalError("init(type:items:supportsRearrangeOfItems:) has not been implemented")
    }
    
    func prepareItems() {
        var sideBartags = [FTSideBarItem]();
        
        let tags = FTTagsProviderV1.shared.getTags(true, sort: true);
        tags.forEach { eachTag in
            let item = FTSideBarItem(id: eachTag.id
                                     , title: eachTag.tagDisplayName
                                     , icon: .number
                                     , isEditable: true
                                     , isEditing: false
                                     , type: (eachTag.tagType == .allTag) ? .allTags : .tag
                                     , allowsItemDropping: false)
            sideBartags.append(item);
        }
        self.items = sideBartags;
    }

}
