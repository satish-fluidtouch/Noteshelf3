//
//  FTFinderViewController+ContextMenu.swift
//  Noteshelf
//
//  Created by Mahesh on 03/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

extension FTFinderViewController {
    
    internal func prepareContextMenu(for indexPath: IndexPath) -> UIMenu? {
        selectedIndexPath = indexPath
        var modifyingActions = [UIMenuElement]()
        var addPageActions = [UIMenuElement]()
        var pageLevelActions = [UIMenuElement]()
        var staticActions = [UIMenuElement]()
        var otherActions = [UIMenuElement]()
        var actions = [UIMenuElement]()
        let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 15))
        
        //Copy
        let copyAction = UIAction(title: NSLocalizedString("Copy", comment: "Copy"),
                                    image: UIImage(systemName: "doc.on.doc", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.copyPages, indexPath: indexPath)
        }
        modifyingActions.append(copyAction)
        
        //Paste
        let pasteAction = UIAction(title: NSLocalizedString("PasteBelow", comment: "Paste"),
                                    image: UIImage(systemName: "doc.on.clipboard", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.pastePages, indexPath: indexPath)
        }
        if nil == FTPasteBoardManager.shared.getBookUrl()  || self.presentedForToolbarMode == .readonly {
            pasteAction.attributes = .disabled
        }
        modifyingActions.append(pasteAction)
        
        //Duplicate
        let duplicateAction = UIAction(title: NSLocalizedString("finder.duplicate", comment: "Duplicate"),
                                    image: UIImage(systemName: "plus.square.on.square", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.duplicatePages, indexPath: indexPath)
        }
        if self.presentedForToolbarMode == .readonly  {
            duplicateAction.attributes = .disabled
        }
        modifyingActions.append(duplicateAction)
        
        
        //Rotate
        let rotateAction = UIAction(title: NSLocalizedString("finder.rotate", comment: "Rotate"),
                                    image: UIImage(systemName: "rotate.right", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.rotatePages, indexPath: indexPath)
        }
        if self.presentedForToolbarMode == .readonly {
            rotateAction.attributes = .disabled
        }
        modifyingActions.append(rotateAction)
        
        
        var canInsertPage: Bool = true
        #if targetEnvironment(macCatalyst)
        canInsertPage = (self.selectedPages.count == 1)
        #endif
        
        if canInsertPage {
            let insertAboveAction = UIAction(title: NSLocalizedString("finder.addPageBefore", comment: "Add Page Before"),
                                        image: UIImage(systemName: "doc.badge.plus", withConfiguration: configuration),
                                        identifier: nil,
                                        discoverabilityTitle: nil,
                                        attributes: .standard,
                                      state: .off) { [weak self] _ in
                self?.performContextMenuOperation(.insertAbove, indexPath: indexPath)
            }
            
            if self.isBookMarkedOrTaggedFilteredScreen() || self.presentedForToolbarMode == .readonly || (selectedTab == .search && isSearching) {
                insertAboveAction.attributes = .disabled
            }
            addPageActions.append(insertAboveAction)
            
            let insertBelowAction = UIAction(title: NSLocalizedString("finder.addPageAfter", comment: "Add Page After"),
                                        image: UIImage(systemName: "doc.badge.plus", withConfiguration: configuration),
                                        identifier: nil,
                                        discoverabilityTitle: nil,
                                        attributes: .standard,
                                      state: .off) { [weak self] _ in
                self?.performContextMenuOperation(.insertBelow, indexPath: indexPath)
            }
            
            if self.isBookMarkedOrTaggedFilteredScreen() || self.presentedForToolbarMode == .readonly || (selectedTab == .search && isSearching) {
                insertBelowAction.attributes = .disabled
            }
            addPageActions.append(insertBelowAction)
        }
        
        //Tag
        let tagAction = UIAction(title: NSLocalizedString("finder.tag", comment: "Tag"),
                                    image: UIImage(systemName: "tag", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.tagPages, indexPath: indexPath)
        }
        pageLevelActions.append(tagAction)
        
        let bookmarkAction = UIAction(title: NSLocalizedString("Bookmark", comment: "Bookmark"),
                                    image: UIImage(systemName: "bookmark", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.bookmark, indexPath: indexPath)
        }
        pageLevelActions.append(bookmarkAction)
        
        //Move
        let moveAction = UIAction(title: NSLocalizedString("move", comment: "Move"),
                                    image: UIImage(systemName: "folder", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.movePages, indexPath: indexPath)
        }
        if self.presentedForToolbarMode == .readonly {
            moveAction.attributes = .disabled
        }
        staticActions.append(moveAction)
        
        //Share
        let shareAction = UIAction(title: NSLocalizedString("Share", comment: "Share"),
                                    image: UIImage(systemName: "square.and.arrow.up", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.sharePages, indexPath: indexPath)
        }
        staticActions.append(shareAction)
        
        //Delete
        let deleteAction = UIAction(title: NSLocalizedString("delete", comment: "Delete"),
                                    image: UIImage(systemName: "trash", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .destructive,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.deletePages, indexPath: indexPath)
        }
        if self.presentedForToolbarMode == .readonly {
            deleteAction.attributes = .disabled
        } else {
            deleteAction.attributes = .destructive
        }
        otherActions.append(deleteAction)
        #if targetEnvironment(macCatalyst)
        actions.append(contentsOf: modifyingActions)
        actions.append(contentsOf: pageLevelActions)
        actions.append(contentsOf: addPageActions)
        actions.append(contentsOf: staticActions)
        actions.append(contentsOf: otherActions)
        #else
        actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: modifyingActions))
        actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: pageLevelActions))
        actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: addPageActions))
        actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: staticActions))
        actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: otherActions))
        #endif
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        if self.mode == .selectPages {return nil}
        FTFinderEventTracker.trackFinderEvent(with: "finder_page_longpress", params: ["location": currentFinderLocation()])
        #if targetEnvironment(macCatalyst)
        let page = self.filteredPages[indexPath.item]
        
        if !selectedPages.contains(page) {
            
            self.selectedPages.forEach { page in
                if let thumbNailPage = page as? FTThumbnailable {
                    if let selectedItemIndex = indexForSelectedItem(thumbNailPage) {
                        if let collectionViewCell = collectionView.cellForItem(at: selectedItemIndex) as? FTFinderThumbnailViewCell {
                            collectionView.deselectItem(at: selectedItemIndex, animated: true);
//                            collectionViewCell.setIsSelected(false);
                        }
                    }
                }
            }
            self.selectedPages.removeAllObjects()
            
            if self.mode == .edit {
                if let collectionViewCell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell {
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    collectionViewCell.setIsSelected(true);
                }
                self.selectedPages.add(page)
            }
        }
        #endif
        
        var contextMenu : UIContextMenuConfiguration?
        let identifier = indexPath as NSIndexPath
        let item = snapshotItem(for: indexPath)
        if item is FTPlaceHolderThumbnail || item is FTOutline { return nil}

        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            return self.prepareContextMenu(for: indexPath)
        }
        contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: actionProvider)
        
        return contextMenu
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) as? FTFinderThumbnailViewCell {
                var visisblePathRect :CGRect?
                var itemBounds: CGRect = .zero
                
                if let bounds = cell.imageViewPage?.bounds {
                    itemBounds = bounds
                }
                itemBounds.origin.x += 3
                itemBounds.origin.y += 3
                itemBounds.size.width -= 6
                itemBounds.size.height -= 6
                
                visisblePathRect = cell.imageViewPage!.convert(itemBounds, to: cell)
                let parameters = UIPreviewParameters()
                parameters.backgroundColor = .clear
                let preview = UITargetedPreview.init(view: cell,parameters: parameters)
                preview.parameters.visiblePath = UIBezierPath.init(roundedRect: visisblePathRect!, cornerRadius: 4.0)
                return preview
            }
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) as? FTFinderThumbnailViewCell {
                let parameters = UIPreviewParameters()
                parameters.backgroundColor = .clear
                let preview = UITargetedPreview.init(view: cell,parameters: parameters)
                return preview
            }
        }
        return nil
    }
    
}
