//
//  FTSidebarViewModel+Tags.swift
//  Noteshelf3
//
//  Created by Siva on 13/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
extension FTSidebarViewModel {
    func renametag(_ tag: FTSideBarItem, newTitle: String) {
        if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag.title) {
            let oldTitle = tag.title;
            tagItem.renameTagItemWith(renamedString: newTitle)
            self.didUpdateRenameTag(tag: oldTitle, with: newTitle)

            FTShelfTagsUpdateHandler.shared.renameTag(tag: oldTitle, with: newTitle) { success in
                if success ?? false {
                    if let tagItem = (tag as? FTSideBarItemTag)?.fttag {
                        FTTagsProviderV1.shared.renameTag(tagItem, to: newTitle);
                    }
                }
            }
        }
    }

    func deleteTag(_ tag: FTSideBarItem) {
        if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag.title) {
            FTShelfTagsUpdateHandler.shared.deleteTag(tag: tagItem.tag) { success in
                if success ?? false {
                    if let tagItem = (tag as? FTSideBarItemTag)?.fttag {
                        FTTagsProviderV1.shared.deleteTags([tagItem]);
                    }
                    tagItem.deleteTagItem()
                    self.updateShelfTagsAndSideMenu()
                }
            }
        }
    }

    func didUpdateRenameTag(tag: String, with newTag: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil, userInfo: ["tag": newTag])
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tag, "type": "rename", "renamedTag": newTag])
    }

    func updateShelfTagsAndSideMenu() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
    }

}
