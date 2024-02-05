//
//  FTShelfTagsBooksCell+ContextMenu.swift
//  Noteshelf3
//
//  Created by Siva on 14/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

// MARK: - contextMenuConfiguration
extension FTShelfTagsBooksCell {

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        track(EventName.shelf_tag_book_longpress, screenName: ScreenName.shelf_tags)
        if let splitContorller = self.parentVC?.splitViewController as? FTShelfSplitViewController {
            splitContorller.shelfMenuDisplayInfo.isMenuShown = true;
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? FTShelfTagsPageCell
                , let item = cell.taggedEntity else {
            return nil;
        }
        var actions = [UIMenuElement]()
        let identifier = indexPath as NSIndexPath
        func pageActions() -> UIMenu {
#if !targetEnvironment(macCatalyst)
            let openNewWindowAction = UIAction(title: "sidebar.allTags.contextualMenu.openInNewWindow".localized, image: UIImage(systemName: "square.split.2x1"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.openTaggedItemInNewWindow(item);
                track(EventName.shelf_tag_book_openinnewwindow_tap, screenName: ScreenName.shelf_tags)
            }
            actions.append(openNewWindowAction)
#endif
            let editAction = UIAction(title: "sidebar.allTags.contextualMenu.editTags".localized, image: UIImage(systemName: "tag"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.editTags([item])
                track(EventName.shelf_tag_book_edittags_tap, screenName: ScreenName.shelf_tags)
            }
            actions.append(editAction)

            let removeTagsAction = UIAction(title: "sidebar.allTags.contextualMenu.removeTags".localized, image: UIImage(systemName: "tag.slash"), identifier: nil) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.removeTags([item])
                track(EventName.shelf_tag_book_removetags_tap, screenName: ScreenName.shelf_tags)
            }
            removeTagsAction.attributes = .destructive
            actions.append(removeTagsAction)
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: { () -> UIViewController? in
            if let identifier = identifier as? IndexPath {
                if let cell = self.collectionView?.cellForItem(at: identifier) as? FTShelfTagsPageCell {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let previewVC = storyboard.instantiateViewController(identifier: "FTShelfPagePreviewController") as? FTShelfPagePreviewController
                     previewVC?.preferredContentSize = FTPreviewDefaultSize.previewSize(for: (cell.thumbnail?.image)!);
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
            if let cell = self.collectionView?.cellForItem(at: identifier) as? FTShelfTagsPageCell {
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
        if let splitContorller = self.parentVC?.splitViewController as? FTShelfSplitViewController {
            splitContorller.shelfMenuDisplayInfo.isMenuShown = false
        }
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) as? FTShelfTagsPageCell {
                let parameters = UIPreviewParameters()
                parameters.backgroundColor = .clear
                let preview = UITargetedPreview.init(view: cell,parameters: parameters)
                return preview
            }
        }
        return nil
    }

}
