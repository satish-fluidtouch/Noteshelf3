//
//  FTTagsView+ContextMenu.swift
//  Noteshelf3
//
//  Created by Siva on 18/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

extension FTTagsView {
   public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
       if self.tagConfiguration.showContextMenu == false {
           return nil
       }
        var actions = [UIMenuElement]()
        let identifier = indexPath as NSIndexPath
       let tag = self.items[indexPath.row]
        func pageActions() -> UIMenu {
            let renameAction = UIAction(title: "tags.contextualMenu.renameTag".localized, image: UIImage(systemName: "pencil"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                    self.delegate?.didRenameTag(tag: tag)
            }
            actions.append(renameAction)
            let deleteAction = UIAction(title: "tags.contextualMenu.deleteTag".localized, image: UIImage(systemName: "trash"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                    self.delegate?.didDeleteTag(tag: tag)
            }
            deleteAction.attributes = .destructive
            actions.append(deleteAction)
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: { () -> UIViewController? in
            return nil
        }, actionProvider: { _ in
            let editActions = pageActions()
            return UIMenu(title: "",
                          children: [editActions])
        })
    }

}
