//
//  FTSidebarSectionMedia.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionMedia: FTSidebarSection {
    
    override var supportsRearrangeOfItems: Bool {
        get {
            return false
        }
        set {
        }
    }
    
    override var type: FTSidebarSectionType {
        get {
            .media;
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
        let photos = FTSideBarItem(title: NSLocalizedString("sidebar.photos", comment: "Photos"), icon: FTIcon.photo, isEditable: true, isEditing: false, type: FTSideBarItemType.media, allowsItemDropping: false)
        let recordings = FTSideBarItem(title: NSLocalizedString("sidebar.recordings", comment: "Recordings"), icon: FTIcon.audioNote, isEditable: true, isEditing: false, type: FTSideBarItemType.audio, allowsItemDropping: false)
        let bookmarks = FTSideBarItem(title: NSLocalizedString("sidebar.bookmarks", comment: "Bookmarks"), icon: FTIcon.bookmark, isEditable: true, type: FTSideBarItemType.bookmark,allowsItemDropping: false)
        self.items = [photos,recordings,bookmarks];
    }
}
