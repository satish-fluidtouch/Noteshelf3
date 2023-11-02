//
//  FTShelfBookmarksViewController.swift
//  Noteshelf3
//
//  Created by Siva on 20/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTShelfBookmarksPageDelegate: AnyObject {
    func openNotebook(shelfItem: FTDocumentItemProtocol, page: Int)
}

class FTShelfBookmarksViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet var emptyPlaceholderView: UIView?

    var viewModel: FTShelfBookmarksPageModel?
    var bookmarkItems = [FTBookmarksItem]()
    private var currentSize: CGSize = .zero

    weak var delegate: FTShelfBookmarksPageDelegate?
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshBookmarks"), object: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "sidebar.bookmarks".localized
        let layout = FTTagsAlignedCollectionViewFlowLayout(verticalAlignment: .bottom)
        self.collectionView?.collectionViewLayout = layout
        self.collectionView?.allowsMultipleSelection = true
        self.collectionView?.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)

        // Add activity indicator in the view
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: NSNotification.Name(rawValue: "refreshBookmarks"), object: nil)
        loadtagBookmarkPages()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFrame()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            self.collectionView?.reloadData()
        }, completion: { (_) in
        })
    }

    private func updateFrame() {
        let frame = self.view.frame.size;
        if currentSize.width != frame.width {
            currentSize = frame
            self.collectionView?.reloadData()
        }
    }

    private func columnWidthForSize(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfColumnsForCollectionViewGrid()
        let totalSpacing = FTShelfTagsConstants.Page.interItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (FTShelfTagsConstants.Page.gridHorizontalPadding * 2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    @objc func reloadContent() {
        loadtagBookmarkPages()
    }

    private func loadtagBookmarkPages() {
        viewModel = FTShelfBookmarksPageModel()
        showActivityIndicator()
        viewModel?.buildCache(completion: { result in
            self.bookmarkItems = result
            if self.bookmarkItems.isEmpty {
                self.showPlaceholderView()
            } else {
                self.hidePlaceholderView()
            }
            self.collectionView?.reloadData()
            self.hideActivityIndicator()
        })

    }

    private func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }

    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }

    private func showPlaceholderView() {
        self.collectionView?.isHidden = true
        self.emptyPlaceholderView?.frame = self.collectionView!.frame
        self.emptyPlaceholderView?.isHidden = false
    }

    private func hidePlaceholderView() {
        self.collectionView?.isHidden = false
        self.emptyPlaceholderView?.isHidden = true
    }

    func removeBookmarkForItem(item: FTBookmarksItem, at indexPath: IndexPath) {
        FTBookmarksProvider.shared.removeBookmarkFor(item: item) { success in
            self.bookmarkItems.remove(at: indexPath.row)
            self.collectionView?.reloadData()
            if self.bookmarkItems.isEmpty {
                self.showPlaceholderView()
            }
        }
    }

}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension FTShelfBookmarksViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookmarkItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? FTShelfBookmarkPageCell else {
            return UICollectionViewCell()
        }

        let item = self.bookmarkItems[indexPath.row]
        cell.updateBookmarkItemCellContent(bookmarkItem: item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.bookmarkItems[indexPath.row]
         let shelf = item.shelfItem
        self.delegate?.openNotebook(shelfItem: shelf, page: item.pageIndex)
            track(EventName.shelf_bookmark_page_tap, screenName: ScreenName.shelf_bookmarks)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.bookmarkItems[indexPath.row]
        let columnWidth = columnWidthForSize(self.view.frame.size) - 12

        if  item.pdfKitPageRect.size.width > item.pdfKitPageRect.size.height  { // landscape
            return CGSize(width: columnWidth, height: ((columnWidth)/FTShelfTagsConstants.Page.landscapeAspectRatio) + FTShelfTagsConstants.Page.extraHeightPadding)
        } else {
            return CGSize(width: columnWidth, height: ((columnWidth)/FTShelfTagsConstants.Page.potraitAspectRation) + FTShelfTagsConstants.Page.extraHeightPadding)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: FTShelfTagsConstants.Page.gridHorizontalPadding, bottom: 0, right: FTShelfTagsConstants.Page.gridHorizontalPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return FTShelfTagsConstants.Page.minInterItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTShelfTagsConstants.Page.minLineSpacing
    }

}
