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
            guard FTTagsProvider.shared.getTagsfor([newTitle], shouldCreate: false).isEmpty else {
                FTTagsProvider.shared.renameTag(ftTag, to: ftTag.tagName);
                return;
            }
            let loadingIndicator = self.delegate?.showIndicatorView("Renaming Tag");
            runInMainThread {
                let tagUpdated = FTDocumentTagUpdater();
                _ = tagUpdated.rename(tag: ftTag, to: newTitle) {
                    debugLog("tagUpdated: \(tagUpdated)");
                    loadingIndicator?.hide()
                }
            }
        }
    }

    func deleteTag(_ tag: FTSideBarItem) {
        if let ftTag = (tag as? FTSideBarItemTag)?.fttag
            , let tagSection = self.menuItems.first(where: {$0.type == .tags}) {
            var menuItems = tagSection.items;
            var index = -1;
            if self.selectedSideBarItem == tag {
                index = menuItems.firstIndex(of: tag) ?? 0;
            }
            let loadingIndicator = self.delegate?.showIndicatorView("Deleting Tag");
            runInMainThread {
                let tagUpdated = FTDocumentTagUpdater();
                _ = tagUpdated.delete(tag: ftTag) {
                    if index != -1 {
                        menuItems.remove(at: index);
                        let indexToSet = min(index,menuItems.count-1);
                        let newItemToSet = menuItems[indexToSet];
                        self.selectedSideBarItem = newItemToSet;
                        self.delegate?.didTapOnSidebarItem(newItemToSet)
                    }
                    debugLog("tagUpdated: \(tagUpdated)");
                    loadingIndicator?.hide()
                }
            }
        }
    }
}
