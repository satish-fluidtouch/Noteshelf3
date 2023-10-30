//
//  FTShelfTagsBooksCell.swift
//  Noteshelf3
//
//  Created by Siva on 12/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShelfTagsBooksCell: UICollectionViewCell {
    weak var delegate: FTShelfTagsAndBooksDelegate?

    @IBOutlet weak var collectionView: UICollectionView!
    private var books = [FTShelfTagsItem]()
    private var viewState: FTShelfTagsPageState = .none
    var contextMenuSelectedIndexPath: IndexPath?
    weak var parentVC: UIViewController?

    override func awakeFromNib() {
        super.awakeFromNib()
        initializeCollectionView()
    }

    private func initializeCollectionView() {
        let layout = FTShelfPagesLayout()
        layout.scrollDirection = .horizontal
        self.collectionView.collectionViewLayout = layout
        self.collectionView.allowsMultipleSelection = true
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }

    func prepareCellWith(books: [FTShelfTagsItem], viewState: FTShelfTagsPageState, parentVC: UIViewController) {
        self.books = books
        self.viewState = viewState
        self.parentVC = parentVC

        collectionView.frame = self.bounds
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        let selection = collectionView.indexPathsForSelectedItems
        self.collectionView.reloadData()
        if books.count > 0, let items = selection {
            for selectedItem in items {
                self.collectionView.selectItem(at: selectedItem, animated: false, scrollPosition: [])
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension FTShelfTagsBooksCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTShelfTagsPageCell", for: indexPath) as? FTShelfTagsPageCell else {
            return UICollectionViewCell()
        }
        cell.selectionBadge?.isHidden = viewState == .none ? true : false

        let item = self.books[indexPath.row]
        cell.updateTagsItemCellContent(tagsItem: item, isRegular: self.traitCollection.isRegular)
        cell.isSelected = true
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.books[indexPath.row]
        let potraitSize = FTShelfTagsConstants.Book.potraitSize

        var size = CGSize(width: potraitSize.width, height: potraitSize.height + FTShelfTagsConstants.Book.extraHeightPadding)
        var token : String?
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item.documentItem!, onCompletion: { [weak self](image, imageToken) in
            if token == imageToken {
                if let img = image {
                    if  img.size.width > img.size.height  { // landscape
                        let landscapeSize = FTShelfTagsConstants.Book.landscapeSize
                        size = CGSize(width: landscapeSize.width, height: landscapeSize.height + FTShelfTagsConstants.Book.extraHeightPadding)
                    } else {
                        let potraitSize = FTShelfTagsConstants.Book.potraitSize
                        size = CGSize(width: potraitSize.width, height: potraitSize.height + FTShelfTagsConstants.Book.extraHeightPadding)
                    }
                }
            }
        })
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: FTShelfTagsConstants.Book.gridHorizontalPadding, bottom: 0, right: FTShelfTagsConstants.Book.gridHorizontalPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return FTShelfTagsConstants.Book.minInterItemSpacing
    }


    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if viewState == .none {
            return true
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? FTShelfTagsPageCell {
            cell.selectionBadge?.isHidden = viewState == .none ? true : false
        }

        if let selectedItems = collectionView.indexPathsForSelectedItems {
            if selectedItems.contains(indexPath) {
                collectionView.deselectItem(at: indexPath, animated: true)
                return false
            }
        }
        track(EventName.shelf_tag_select_book_tap, screenName: ScreenName.shelf_tags)
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.shouldEnableToolbarItems()
        if viewState == .none {
            let item = self.books[indexPath.row]
            if let shelf = item.documentItem {
                self.delegate?.openNotebook(shelfItem: shelf, page: 0)
                track(EventName.shelf_tag_book_tap, screenName: ScreenName.shelf_tags)
            }
        }

    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.delegate?.shouldEnableToolbarItems()
    }

}
