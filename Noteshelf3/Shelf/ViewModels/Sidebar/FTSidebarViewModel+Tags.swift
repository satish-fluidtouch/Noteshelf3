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
                if newTitle.compare(ftTag.tagName, options: [.caseInsensitive,.numeric], range: nil, locale: nil) == .orderedSame {
                    FTTagsProvider.shared.renameTag(ftTag, to: newTitle);
                }
                else {
                    FTTagsProvider.shared.renameTag(ftTag, to: ftTag.tagName);
                }
                return;
            }
            let loadingIndicator = self.delegate?.showIndicatorView("");
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
        if let ftTag = (tag as? FTSideBarItemTag)?.fttag {
            let tagSection = self.section(type: .tags)
            
            var itemToSelect: FTSideBarItem?
            if self.selectedSideBarItem == tag, let index = tagSection.items.firstIndex(of: tag) {
                var menuItems = tagSection.items;
                menuItems.remove(at: index)
                let indexToSet = min(index,menuItems.count-1);
                itemToSelect = menuItems[indexToSet];
            }

            let loadingIndicator = self.delegate?.showIndicatorView("");
            runInMainThread {
                let tagUpdated = FTDocumentTagUpdater();
                _ = tagUpdated.delete(tag: ftTag) {
                    if let index = tagSection.items.firstIndex(of: tag) {
                        tagSection.removeItem(at: index)
                    }
                    if let _item = itemToSelect {
                        self.selectedSideBarItem = _item;
                        self.delegate?.didTapOnSidebarItem(_item)
                    }
                    debugLog("tagUpdated: \(tagUpdated)");
                    loadingIndicator?.hide()
                }
            }
        }
    }
}
