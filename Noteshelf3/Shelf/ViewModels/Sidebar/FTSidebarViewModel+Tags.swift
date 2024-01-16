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
        if let ftTag = (tag as? FTSideBarItemTag)?.fttag {
            let tagUpdated = FTDocumentTagUpdater();
            let progress = tagUpdated.rename(tag: ftTag, to: newTitle) { success in
                debugLog("tagUpdated: \(tagUpdated)");
            }
        }
    }

    func deleteTag(_ tag: FTSideBarItem) {
        if let ftTag = (tag as? FTSideBarItemTag)?.fttag {
            let tagUpdated = FTDocumentTagUpdater();
            tagUpdated.delete(tag: ftTag) { success in
                debugLog("tagUpdated: \(tagUpdated)");
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
