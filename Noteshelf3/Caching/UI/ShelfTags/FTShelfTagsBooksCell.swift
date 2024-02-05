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
    private var viewState: FTShelfTagsPageState = .none
    weak var parentVC: UIViewController?
    private var tagCategory = FTShelfTagCategory()

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

    func prepareCell(tagCategory: FTShelfTagCategory
                     , viewState: FTShelfTagsPageState
                     , parentVC: UIViewController) {
        self.tagCategory = tagCategory
        self.viewState = viewState
        self.parentVC = parentVC

        collectionView.frame = self.bounds
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        self.collectionView.reloadData()
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
        return self.tagCategory.books.count;
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTShelfTagsPageCell", for: indexPath) as? FTShelfTagsPageCell else {
            return UICollectionViewCell()
        }
        cell.selectionBadge?.isHidden = viewState == .none ? true : false

        let item = self.tagCategory.books[indexPath.row]
        cell.updateTaggedEntity(taggedEntity: item, isRegular: self.traitCollection.isRegular);
        if viewState == .edit, self.tagCategory.selectedEntities.contains(item) {
            cell.isItemSelected = true;
        }
        else {
            cell.isItemSelected = false;
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let potraitSize = FTShelfTagsConstants.Book.potraitSize

        var size = CGSize(width: potraitSize.width, height: potraitSize.height + FTShelfTagsConstants.Book.extraHeightPadding)
        var token : String?
        let item = self.tagCategory.books[indexPath.row];
        token = item.thumbnail { (image, inToken) in
            if token == inToken,let img = image {
                if  img.size.width > img.size.height  { // landscape
                    let landscapeSize = FTShelfTagsConstants.Book.landscapeSize
                    size = CGSize(width: landscapeSize.width, height: landscapeSize.height + FTShelfTagsConstants.Book.extraHeightPadding)
                } else {
                    let potraitSize = FTShelfTagsConstants.Book.potraitSize
                    size = CGSize(width: potraitSize.width, height: potraitSize.height + FTShelfTagsConstants.Book.extraHeightPadding)
                }
            }
        }

        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: FTShelfTagsConstants.Book.gridHorizontalPadding, bottom: 0, right: FTShelfTagsConstants.Book.gridHorizontalPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return FTShelfTagsConstants.Book.minInterItemSpacing
    }


//    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        if viewState == .none {
//            return true
//        }
//        if let cell = collectionView.cellForItem(at: indexPath) as? FTShelfTagsPageCell {
//            cell.selectionBadge?.isHidden = viewState == .none ? true : false
//        }
//
//        if let selectedItems = collectionView.indexPathsForSelectedItems {
//            if selectedItems.contains(indexPath) {
//                collectionView.deselectItem(at: indexPath, animated: true)
//                return false
//            }
//        }
//        track(EventName.shelf_tag_select_book_tap, screenName: ScreenName.shelf_tags)
//        return true
//    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.tagCategory.books[indexPath.row]
        if viewState == .none {
            FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
                if let shelfItem = allItems.first(where: { ($0 as? FTDocumentItemProtocol)?.documentUUID == item.documentUUID}) as? FTDocumentItemProtocol {
                    self.delegate?.openNotebook(shelfItem: shelfItem, page: 0)
                    track(EventName.shelf_tag_book_tap, screenName: ScreenName.shelf_tags)
                }
            }
        }
        else if viewState == .edit {
            if self.tagCategory.selectedEntities.contains(item) {
                self.tagCategory.setSelected(item, selected: false);
            }
            else {
                self.tagCategory.setSelected(item, selected: true);
            }
            collectionView.reloadItems(at: [indexPath])
        }
        self.delegate?.shouldEnableToolbarItems()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.delegate?.shouldEnableToolbarItems()
    }

}
