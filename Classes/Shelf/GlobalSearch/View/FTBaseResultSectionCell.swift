//
//  FTBaseResultSectionCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTSearchResultActionDelegate: NSObjectProtocol {
    func didSelectItem(_ gridItem: FTSearchResultProtocol)
    func performContextMenuOperation(for item: FTDiskItemProtocol,
                                     pageIndex: Int?,
                                     type: FTShelfItemContexualOption)
    func performContextMenuPageShare(for page: FTPageProtocol, shelfItem: FTShelfItemProtocol)
    func performContextualMenuPin(for shelfItem: FTShelfItemProtocol, isToPin: Bool)
}

class FTBaseResultSectionCell: UICollectionViewCell {
    weak var delegate: FTSearchResultActionDelegate?
    @IBOutlet var collectionView: UICollectionView?

    var isRegular: Bool {
        var status = self.traitCollection.isRegular
        if nil != self.window {
            status = self.isRegularClass()
        }
        return status
    }

    var contentSection: FTSearchSectionProtocol! {
        didSet {
            self.collectionView?.reloadData()
        }
    }

    func updateContentSection(_ section: FTSearchSectionProtocol) {
        self.contentSection = section
    }

    func getAnimationInfo(for indexPath: IndexPath) -> FTOpenAnimationInfo? {
        //Subclass should override this
        return nil
    }
}

extension FTBaseResultSectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.1) {
                cell.contentView.alpha = 0.7
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.1) {
                cell.contentView.alpha = 1.0
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didSelectItem(self.contentSection.items[indexPath.row])
    }
}

extension FTBaseResultSectionCell {
    private func targetedPreview(for cell:UICollectionViewCell) -> UITargetedPreview? {
        guard let _ = cell.window else {
            return nil;
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        var view = cell.contentView
        var bezierPath: UIBezierPath?
        if let categoryCell = cell as? FTSearchResultCategoryCell, let imgView = categoryCell.folderImageView {
            view = imgView
        } else if let groupCell = cell as? FTSearchResultGroupCell {
            view = groupCell.stackPreview
        }
        else if let bookCell = cell as? FTSearchResultBookCell, let coverImgView = bookCell.coverPreviewContainer {
            view = coverImgView
            if bookCell.toShowEqualCorners {
                let shape = FTNotebookShape(raidus: GlobalSearchConstants.BookCoverThumbnailRadius.equiRadius)
                bezierPath = UIBezierPath(cgPath: shape.path(in: view.bounds).cgPath)
            } else {
                let shape = FTNotebookShape(leftRaidus: GlobalSearchConstants.BookCoverThumbnailRadius.left, rightRadius: GlobalSearchConstants.BookCoverThumbnailRadius.right)
                bezierPath = UIBezierPath(cgPath: shape.path(in: view.bounds).cgPath)
            }
        }
        else if let pageCell = cell as? FTSearchResultPageCell, let imgView = pageCell.imageViewPage {
            view = imgView
        }
        parameters.visiblePath = bezierPath
        let preview = UITargetedPreview.init(view: view, parameters: parameters)
        return preview
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let indexPath = configuration.identifier as? IndexPath, let cell = collectionView.cellForItem(at: indexPath){
            return self.targetedPreview(for: cell);
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) {
                return self.targetedPreview(for: cell);
            }
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .dismiss
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

        guard let section = self.contentSection else {
            return nil
        }
        //*********************
        let gridItem = self.contentSection.items[indexPath.row]
        var selectedShelfItem: FTShelfItemProtocol?
        if section.contentType == .page {
            selectedShelfItem = section.sectionHeaderItem as? FTShelfItemProtocol
        }
        else if let resultItem = gridItem as? FTSearchResultBookProtocol {
            selectedShelfItem = resultItem.shelfItem
        }
        guard let shelfItem = selectedShelfItem else {
            return nil
        }
        //*********************
        
        var isDownloaded : Bool = true
        if let item = shelfItem as? FTDocumentItemProtocol {
            isDownloaded = item.isDownloaded
        }
        var actions = [UIMenuElement]()
        var staticActions = [UIMenuElement]()
        let modifyingActions = [UIMenuElement]()
        var otherActions = [UIMenuElement]()

        var contextMenu : UIContextMenuConfiguration?;
        let identifier = indexPath as NSIndexPath
        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            //=========================================
            let openAction = UIAction(title: NSLocalizedString("Open", comment: "Open")) { [weak self] _ in
                self?.delegate?.didSelectItem(gridItem)
            }
            staticActions.append(openAction)

            if (isDownloaded && !(UIDevice.current.isIphone())) {
                let openInWindowAction = UIAction(title: FTShelfItemContexualOption.openInNewWindow.displayTitle) {[weak self] _ in
                    var pageIndex : Int?;
                    if let contentSection = section as? FTSearchSectionContentProtocol {
                        if let item = contentSection.items[indexPath.row] as? FTSearchResultPageProtocol {
                            pageIndex = item.searchingInfo?.pageIndex
                        }
                    }
                    self?.delegate?.performContextMenuOperation(for: shelfItem,
                                                                pageIndex: pageIndex,
                                                                type: .openInNewWindow)
                }
                staticActions.append(openInWindowAction)
            }
            
            let showEnclosingAction = UIAction(title: FTShelfItemContexualOption.showEnclosingFolder.displayTitle) {[weak self] _ in
                self?.delegate?.performContextMenuOperation(for: shelfItem,
                                                            pageIndex: nil,
                                                            type: .showEnclosingFolder)
            }
            staticActions.append(showEnclosingAction)

            //***************
            if (!(shelfItem is FTGroupItemProtocol) && (section.contentType == .book)) {
                var isToPin: Bool = true
                let isFavourite = FTRecentEntries.isFavorited(shelfItem.URL)
                var optionTitle = FTShelfItemContexualOption.addToStarred.displayTitle
                if isFavourite {
                    optionTitle = FTShelfItemContexualOption.removeFromStarred.displayTitle
                    isToPin = false
                }
                let pinUnPinAction = UIAction(title: optionTitle) { [weak self] _ in
                    self?.delegate?.performContextualMenuPin(for: shelfItem, isToPin: isToPin)
                }
                staticActions.append(pinUnPinAction)
            }
            //***************
            
            if !(shelfItem is FTGroupItemProtocol) {
                let shareAction = UIAction(title: FTShelfItemContexualOption.share.displayTitle) { [weak self] _ in
                    var pageIndex: Int?

                    if let contentSection = section as? FTSearchSectionContentProtocol {
                        if let item = contentSection.items[indexPath.row] as? FTSearchResultPageProtocol {
                            pageIndex = item.searchingInfo?.pageIndex
                        }
                    }

                    if let contentSection = section as? FTSearchSectionContentProtocol {
                        if let item = contentSection.items[indexPath.row] as? FTSearchResultPageProtocol {
                            if let associatedPage = contentSection.associatedPage(forItem: item) as? FTPageProtocol {
                                self?.delegate?.performContextMenuPageShare(for: associatedPage, shelfItem: shelfItem)
                            }
                        }
                    }
                    else {
                        self?.delegate?.performContextMenuOperation(for: shelfItem, pageIndex: pageIndex, type: .share)
                    }
                }
                otherActions.append(shareAction)
            }
            //=========================================

            actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: staticActions))
            actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: modifyingActions))
            actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: otherActions))
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
        contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: nil,  actionProvider: actionProvider)
        return contextMenu
    }
}
