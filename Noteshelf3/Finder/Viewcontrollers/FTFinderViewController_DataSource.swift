
//
//  FTFinderViewController_Search.swift
//  Noteshelf3
//
//  Created by Sameer on 07/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

extension FTFinderViewController {
    func collectionView(_ collectionView: UICollectionView, thumbnailsCellForRowAt indexPath: IndexPath) -> UICollectionViewCell {
        let page = self.filteredPages[indexPath.item];
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCellPDFFinderPage", for: indexPath) as! FTFinderThumbnailViewCell;
        collectionViewCell.selectedTab = selectedTab
        if self.mode == .edit || mode == .selectPages {
            collectionViewCell.editing = true;
                        let isCellSelected = self.selectedPages.contains(where: { (element) -> Bool in
                let pageElemenet = element as! FTThumbnailable
                return pageElemenet.uuid == page.uuid;
            });
            collectionViewCell.setIsSelected(isCellSelected);
        }
        else {
            collectionViewCell.editing = false;
            collectionViewCell.setIsSelected(false);
        }
        collectionViewCell.selectionBadge?.isHidden = (self.mode == .none)
        if let currentPage = self.delegate?.currentPage(in: self), currentPage.uuid == page.uuid, self.mode == .none {
            collectionViewCell.setAsCurrentVisiblePage()
        }
        collectionViewCell.buttonBookmark?.tag = indexPath.item;
        collectionViewCell.buttonBookmark?.isSelected = false;
        let imageName = "bookmark.fill"
        collectionViewCell.buttonBookmark?.setImage(UIImage(systemName: imageName), for: .normal)
        let bookmarkColor = (!page.bookmarkColor.isEmpty) ? UIColor(hexString: page.bookmarkColor) : .appColor(.gray9)
        collectionViewCell.buttonBookmark?.tintColor = page.isBookmarked ? bookmarkColor : .appColor(.gray9)
        let size = AVMakeRect(aspectRatio: page.pdfPageRect.size, insideRect: CGRect(origin: CGPoint.zero, size: self.cellSize)).size
        collectionViewCell.pdfSize = size;
        collectionViewCell.pageSize = self.cellSize
        collectionViewCell.labelPageNumber?.text = "\(page.pageIndex() + 1)";
        collectionViewCell.setThumbnailImage(usingPage: page);
        collectionViewCell.shouldShowVerticalDivider = self.view.frame.width <= supplimentaryFinderVcWidth
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        collectionViewCell.buttonBookmark?.tag = indexPath.item;
        if mode != .selectPages {
            collectionViewCell.buttonBookmark?.addGestureRecognizer(longPress)
        }
        collectionViewCell.updateTagsPill()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTagspill(_:)))
        collectionViewCell.stackView.addGestureRecognizer(tapGesture)
        collectionViewCell.stackView.tag = indexPath.item
        if nil != self.draggingIndexPath
            && indexPath == self.draggingIndexPath {
            collectionViewCell.isHidden = true;
        }
        else {
            collectionViewCell.isHidden = false;
        }
        return collectionViewCell;
    }
    
    func collectionView(_ collectionView: UICollectionView, placeHolderCellForRowAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTPlaceHolderThumbnailCell", for: indexPath) as! FTPlaceHolderThumbnailCell
        var bounds = UIScreen.main.bounds
        if bounds.width > bounds.height {
            bounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.height, height: bounds.width))
        }
        collectionViewCell.isDisabled = (mode == .edit)
        let size = AVMakeRect(aspectRatio: bounds.size, insideRect: CGRect(origin: CGPoint.zero, size: self.cellSize)).size
        collectionViewCell.imageSize = size
        collectionViewCell.moreOptionsButton.addTarget(self, action: #selector(didTapAddPageOption(_:)), for: .touchUpInside)
        return collectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, outLineCellForRowAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTOutlineCollectionViewCell", for: indexPath) as! FTOutlineCollectionViewCell
        if let view = self.outlinesContainerView {
            collectionViewCell.configureWith(outlinesView: view)
        }
        return collectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, bookmarkCellForRowAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTBookmarkCollectionViewCell", for: indexPath) as! FTBookmarkCollectionViewCell
        let page = filteredPages[indexPath.row]
        if self.mode == .edit || mode == .selectPages {
                let isCellSelected = self.selectedPages.contains(where: { (element) -> Bool in
                let pageElemenet = element as! FTThumbnailable
                return pageElemenet.uuid == page.uuid;
            });
            collectionViewCell.setIsSelected(isCellSelected);
        }
        else {
            collectionViewCell.setIsSelected(false);
        }
        collectionViewCell.isEditMode = (self.mode == .edit || self.mode == .selectPages)
        let size = AVMakeRect(aspectRatio: page.pdfPageRect.size, insideRect: CGRect(origin: CGPoint.zero, size: self.bookMarkThumbSize)).size
        collectionViewCell.thumbImageSize = size
        collectionViewCell.confiureCell(with: page)
        return collectionViewCell
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if let sender: UIButton = gesture.view as? UIButton {
            let page = self.filteredPages[sender.tag]
            if let newPage = page as? FTPageProtocol {
                FTBookmarkViewController.showBookmarkController(fromSourceView: sender, onController: self, pages: [newPage])
            }
        }
    }
    
    @objc func didTapAddPageOption(_ sender: UIButton) {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let pageViewController = storyboard.instantiateViewController(withIdentifier: "FTAddMenuPageViewController") as? FTAddMenuPageViewController else {
            fatalError("Document Entities Viewcontroller not found")
        }
        pageViewController.delegate = self
        pageViewController.dataManager = AddMenuDataManager()
        pageViewController.ftPresentationDelegate.source = sender
        self.ftPresentPopover(vcToPresent: pageViewController, contentSize: CGSize(width: 320, height: 400), hideNavBar: true)
    }
    
    @objc func didTapTagspill(_ gesture: UITapGestureRecognizer) {
        if let sender = gesture.view as? UIStackView, gesture.state == .ended, let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as? FTFinderThumbnailViewCell  {
            let page = self.filteredPages[sender.tag]
            if let newPage = page as? FTPageProtocol {
                let set =  NSSet(array: [newPage]) as Set<NSObject> as NSSet
                self.tagPages(withSelectedPages: set, targetView: cell)
                contextMenuActivePages = [page]
            }
        }
    }
}

extension FTFinderViewController: FTBookmarkPageViewControllerDelegate, FTAddMenuPageViewControllerDelegate {
    func refreshBookmarkButton(for pages:[ FTPageProtocol]) {
        pages.forEach { page in
            if let index = self.filteredPages.firstIndex(where: {$0.uuid == page.uuid}) {
                let bookmarkColor = (!page.bookmarkColor.isEmpty) ? UIColor(hexString: page.bookmarkColor) : .appColor(.gray9)
                if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFinderThumbnailViewCell {
                    let imageName = "bookmark.fill"
                    cell.buttonBookmark?.setImage(UIImage(systemName: imageName), for: .normal)
                    cell.buttonBookmark?.tintColor = page.isBookmarked ? bookmarkColor : .appColor(.gray9)
                } else if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTBookmarkCollectionViewCell {
                    cell.bookmarkButton.tintColor = page.isBookmarked ? bookmarkColor : UIColor.appColor(.black20)
                    cell.bookmarkTitle?.text = page.bookmarkTitle == "" ? NSLocalizedString("Untitled", comment: "Untitled") : page.bookmarkTitle
                }
            }
        }
        if let _pages = pages as? [FTThumbnailable], let shelfItem = self.delegate?.currentShelfItemInShelfItemsViewController() as? FTDocumentItemProtocol {
            FTBookmarksProvider.shared.updateBoodmarkItemFor(pages: _pages, shelfItem: shelfItem)
        }
    }
    
    func removeBookMark(for pages: [FTPageProtocol]) {
        pages.forEach { page in
            page.isBookmarked = false
            page.bookmarkColor = ""
            page.bookmarkTitle = ""
        }
        reloadFilteredItems()
        if selectedSegment == .bookmark {
            deselectAll()
            let bookmarkedPages = self.document.documentPages().filter{$0.isBookmarked};
            if bookmarkedPages.isEmpty {
                mode = .none
                validateHeaderView()
            }
        }
        if let _pages = pages as? [FTThumbnailable], let shelfItem = self.delegate?.currentShelfItemInShelfItemsViewController() as? FTDocumentItemProtocol {
            FTBookmarksProvider.shared.updateBoodmarkItemFor(pages: _pages, shelfItem: shelfItem)
        }
    }
    
    func didTapPageItem(_ type: FTPageType) {
        if !(self.delegate?._isRegularClass() ?? false) {
            self.delegate?.didTapOnDismissButton()
        } else {
            if screenMode == .fullScreen {
                self.delegate?.didTapOnExpandButton()
                self.splitViewController?.preferredDisplayMode = .secondaryOnly
            } else {
                if self.splitViewController?.displayMode == .oneOverSecondary || self.splitViewController?.displayMode == .twoOverSecondary {
                    self.splitViewController?.preferredDisplayMode = .secondaryOnly
                }
            }
        }
        self.delegate?.didInsertPageFromFinder(type)
    }
}
