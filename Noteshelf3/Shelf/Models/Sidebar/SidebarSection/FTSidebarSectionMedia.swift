//
//  FTSidebarSectionMedia.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionMedia: FTSidebarSection {
    override var type: FTSidebarSectionType {
        return .media;
    }
    
    required init() {
        super.init();
        self.prepareItems();
    }
}

private extension FTSidebarSectionMedia {
    func prepareItems() {
        let photos = FTSideBarItem(title: NSLocalizedString("sidebar.photos", comment: "Photos"), icon: FTIcon.photo, isEditable: true, isEditing: false, type: FTSideBarItemType.media, allowsItemDropping: false)
        let recordings = FTSideBarItem(title: NSLocalizedString("sidebar.recordings", comment: "Recordings"), icon: FTIcon.audioNote, isEditable: true, isEditing: false, type: FTSideBarItemType.audio, allowsItemDropping: false)
        let bookmarks = FTSideBarItem(title: NSLocalizedString("sidebar.bookmarks", comment: "Bookmarks"), icon: FTIcon.bookmark, isEditable: true, type: FTSideBarItemType.bookmark,allowsItemDropping: false)
        self.items = [photos,recordings,bookmarks];
    }
}
