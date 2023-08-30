//
//  FTShelfBookmarksViewController+ContextMenu.swift
//  Noteshelf3
//
//  Created by Siva on 20/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit


// MARK: - contextMenuConfiguration
extension FTShelfBookmarksViewController {

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if let splitContorller = self.splitViewController as? FTShelfSplitViewController {
            splitContorller.shelfMenuDisplayInfo.isMenuShown = true
        }
        let cell = collectionView.cellForItem(at: indexPath)!
        var actions = [UIMenuElement]()
        let identifier = indexPath as NSIndexPath
        func pageActions() -> UIMenu {
            let openNewWindowAction = UIAction(title: "sidebar.bookmarks.contextualMenu.openInNewWindow".localized, image: UIImage(systemName: "square.split.2x1"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                let item = self.bookmarkItems[indexPath.row]
                self.openItemInNewWindow(item.shelfItem!, pageIndex: item.pageIndex)
            }
            actions.append(openNewWindowAction)

            let removeBookmarkAction = UIAction(title: "sidebar.bookmarks.contextualMenu.removeBookmark".localized, image: UIImage(systemName: "bookmark.slash"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                UIAlertController.showDeleteDialog(with: "sidebar.bookmarks.alert.message".localized, message: "", from: self) {
                    let item = self.bookmarkItems[indexPath.row]
                    self.removeBookmarkForItem(item: item, at: indexPath)
                }
            }
            removeBookmarkAction.attributes = .destructive
            actions.append(removeBookmarkAction)
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: { () -> UIViewController? in
            if let identifier = identifier as? IndexPath {
                if let cell = self.collectionView?.cellForItem(at: identifier) as? FTShelfBookmarkPageCell {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let previewVC = storyboard.instantiateViewController(identifier: "FTShelfPagePreviewController") as? FTShelfPagePreviewController
                    // previewVC?.preferredContentSize = FTPreviewDefaultSize.previewSize(for: (cell.thumbnail?.image)!);
                    previewVC?.previewImage = cell.thumbnail?.image;
                    previewVC?.imageView?.contentMode = .scaleAspectFit
                    return previewVC
                }
            }
            return nil
        }, actionProvider: { _ in
            let editActions = pageActions()
            return UIMenu(title: "",
                          children: [editActions])
        })
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) as? FTShelfBookmarkPageCell {
                var visisblePathRect :CGRect?
                var itemBounds: CGRect = .zero

                if let bounds = cell.thumbnail?.bounds {
                    itemBounds = bounds
                }
                visisblePathRect = cell.thumbnail!.convert(itemBounds, to: cell)
                let parameters = UIPreviewParameters()
                parameters.backgroundColor = .clear
                let preview = UITargetedPreview.init(view: cell,parameters: parameters)
                preview.parameters.visiblePath = UIBezierPath.init(roundedRect: visisblePathRect!, cornerRadius: 10.0)
                return preview
            }
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let splitContorller = self.splitViewController as? FTShelfSplitViewController {
            splitContorller.shelfMenuDisplayInfo.isMenuShown = false
        }
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) as? FTShelfBookmarkPageCell {
                let parameters = UIPreviewParameters()
                parameters.backgroundColor = .clear
                let preview = UITargetedPreview.init(view: cell,parameters: parameters)
                return preview
            }
        }
        return nil
    }

}
