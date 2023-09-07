//
//  FTSidebarViewModel+Tags.swift
//  Noteshelf3
//
//  Created by Siva on 13/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension FTSidebarViewModel {
    func renametag(_ tag: FTSideBarItem, toNewTitle newTitle: String) {
        Task.detached(operation: {
            do {
                try await FTShelfTagsUpdateHandler.shared.renameTag(tag: FTTagModel(id: tag.id, text: tag.title), with: FTTagModel(id: tag.id, text: newTitle), for: nil)
                await self.didUpdateRenameTag(tag: tag.title, with: newTitle)
                tag.title = newTitle
            } catch {

            }
        })
    }

    func deleteTag(_ tag: FTSideBarItem) {

        Task.detached(operation: {
            do {
                try await FTShelfTagsUpdateHandler.shared.deleteTag(tag: FTTagModel(text: tag.title), for: nil)
                await self.updateShelfTagsAndSideMenu()
            } catch {

            }
        })
    }

    @MainActor
    func didUpdateRenameTag(tag: String, with newTag: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil, userInfo: ["tag": tag])
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil, userInfo: ["tag": tag, "type": "rename", "renamedTag": newTag])
    }

    @MainActor
    func updateShelfTagsAndSideMenu() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShelfTags"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
    }

}
