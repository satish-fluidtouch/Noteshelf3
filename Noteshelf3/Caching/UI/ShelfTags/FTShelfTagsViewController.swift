//
//  FTShelfTagsViewController.swift
//  Noteshelf3
//
//  Created by Siva on 04/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

enum FTShelfTagsPageState {
    case edit, none
}

protocol FTShelfTagsPageDelegate: AnyObject {
    func openNotebook(shelfItem: FTDocumentItemProtocol, page: Int)
}

protocol FTShelfTagsAndBooksDelegate: AnyObject {
    func shouldEnableToolbarItems()
    func openNotebook(shelfItem: FTDocumentItemProtocol, page: Int)
    func editTags()
    func removeTags()
    func openItemInNewWindow()
}

class FTShelfTagsViewController: UIViewController {
    var viewModel: FTShelfTagsPageModel?
    var tagItems = [FTShelfTagsItem]()

    var selectedTag: FTTagModel? {
        didSet {
            if searchTag != selectedTag?.text || (selectedTag == nil && searchTag == "sidebar.allTags".localized) {
                loadtagsBooksAndPages()
            }
            searchTag = selectedTag?.text
            if self.collectionView != nil {
                activateViewMode()
                enableToolbarItemsIfNeeded()
            }
            self.title = (nil == self.selectedTag) ? "sidebar.allTags".localized : "#" + (self.selectedTag?.text ?? "")
        }
    }
    var viewState: FTShelfTagsPageState = .none
    var contextMenuSelectedIndexPath: IndexPath?
    var removeTagsTitle = "sidebar.allTags.contextualMenu.removeTags".localized
    var selectedPaths = [IndexPath]()
    private var currentSize: CGSize = .zero
    private var searchTag: String?

    weak var delegate: FTShelfTagsPageDelegate?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar?
    @IBOutlet weak var removeTagsBtn: UIButton?
    @IBOutlet weak var editTagsBtn: UIButton?
    @IBOutlet weak var shareBtn: UIButton?
    @IBOutlet var emptyPlaceholderView: UIView?
    @IBOutlet weak private var selectButtom: UIBarButtonItem?
    var selectAllButton: UIBarButtonItem?

    override func viewDidLoad()  {
        super.viewDidLoad()
        self.title = (nil == self.selectedTag) ? "sidebar.allTags".localized : "#" + (self.selectedTag?.text ?? "")
        self.collectionView.register(FTShelfTagsSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        self.toolbar?.isHidden = true
        let layout = FTShelfPagesLayout()
        self.collectionView.collectionViewLayout = layout
        self.collectionView.allowsMultipleSelection = true
        self.collectionView?.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
        loadtagsBooksAndPages()
        self.updateToolbarTitles()
#if targetEnvironment(macCatalyst)
        self.navigationItem.leftBarButtonItems = []
        self.navigationItem.rightBarButtonItems = []
        (self.view.toolbar as? FTShelfToolbar)?.toolbarActionDelegate = self
#endif
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh(_ :)), name: Notification.Name(rawValue: "refreshShelfTags"), object: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self](_) in
            self?.updateToolbarTitles()
            self?.collectionView.reloadData()
        }, completion: { (_) in
        })
    }

    private func updateFrame() {
        let frame = self.view.frame.size;
        if currentSize.width != frame.width {
            currentSize = frame
            self.collectionView.reloadData()
        }
    }

    private func columnWidthForSize(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfColumnsForCollectionViewGrid()
        let totalSpacing = FTShelfTagsConstants.Page.interItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (FTShelfTagsConstants.Page.gridHorizontalPadding * 2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    private func updateToolbarTitles() {
        if self.isRegularClass() {
            removeTagsTitle = self.selectedTag == nil ? "sidebar.allTags.contextualMenu.removeTags".localized : "sidebar.allTags.contextualMenu.removeTag".localized
            removeTagsBtn?.setTitle(removeTagsTitle, for: .normal)
            shareBtn?.setTitle("sidebar.allTags.toolbar.share".localized, for: .normal)
            editTagsBtn?.setTitle("sidebar.allTags.toolbar.editTags".localized, for: .normal)
        } else {
            removeTagsBtn?.setTitle("", for: .normal)
            shareBtn?.setTitle("", for: .normal)
            editTagsBtn?.setTitle("", for: .normal)
        }
    }

    @objc func refresh(_ notification: Notification) {
        activateViewMode()
        if let info = notification.userInfo, let tag = info["tag"] as? String {
            let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: FTTagModel(text: tag))
            reloadListFor(docIds: docIds)
        }

        self.title = self.selectedTag == nil ? "sidebar.allTags".localized : "#" + (self.selectedTag?.text ?? "")
        enableToolbarItemsIfNeeded()
    }

    private func generateBooks() -> [FTShelfTagsItem] {
        var books = [FTShelfTagsItem]()
        for i in 0..<self.tagItems.count {
            let book = tagItems[i]
            if book.type == .book {
                books.append(tagItems[i])
            }
        }
        return books
    }

    private func generatePages() -> [FTShelfTagsItem] {
        var pages = [FTShelfTagsItem]()
        for i in 0..<self.tagItems.count {
            let page = tagItems[i]
            if page.type == .page {
                pages.append(tagItems[i])
            }
        }
        return pages
    }


    private func loadtagsBooksAndPages() {
        viewModel = FTShelfTagsPageModel()
        viewModel?.selectedTag = self.selectedTag?.text ?? "";
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: "")
        Task {
            await viewModel?.buildCache()
            loadingIndicatorViewController.hide {
                if let result = self.viewModel?.tagsResult {
                    self.tagItems = result.tagsItems
                    if self.tagItems.isEmpty {
                        self.showPlaceholderView()
                    } else {
                        self.hidePlaceholderView()
                        if self.viewState == .edit, !self.selectedPaths.isEmpty {
                            self.collectionView.reloadItems(at: self.selectedPaths)
                        } else {
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }

    private func showPlaceholderView() {
        selectButtom?.isEnabled = false
        self.collectionView.isHidden = true
        self.emptyPlaceholderView?.frame = self.collectionView!.frame
        self.emptyPlaceholderView?.isHidden = false
    }

    private func hidePlaceholderView() {
        selectButtom?.isEnabled = true
        self.collectionView.isHidden = false
        self.emptyPlaceholderView?.isHidden = true
    }

    func selectedItems() -> [FTShelfTagsItem] {
        let books = generateBooks()
        let pages = generatePages()
        if let indexPath = contextMenuSelectedIndexPath, pages.count > 0 {
            return [pages[indexPath.row]]
        } else if books.count > 0, let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell, let indexPath = booksCell.contextMenuSelectedIndexPath {
            return [books[indexPath.row]]
        } else {
            var selectedItems = [FTShelfTagsItem]()

            if let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell, let selectedBooks = booksCell.collectionView.indexPathsForSelectedItems {
                self.selectedPaths = selectedBooks
            }
            if let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems, selectedIndexPaths.count > 0 {
                self.selectedPaths += selectedIndexPaths
            }
            if self.selectedPaths.count > 0 {
                self.selectedPaths.forEach({ indexPath in
                    if indexPath.section == 0, books.count > 0 && indexPath.row <= books.count - 1 {
                        selectedItems.append(books[indexPath.row])
                    } else if indexPath.section == 1, indexPath.row <= pages.count - 1 {
                        selectedItems.append(pages[indexPath.row])
                    }
                })
                return selectedItems
            }
        }
        return []
    }

    func commonTagsFor(items: [FTShelfTagsItem]) -> [String] {
        var commonTags: Set<String> = []
        for (index, item) in items.enumerated() {
            if index == 0 {
                commonTags = Set.init(item.tags.map{$0.text})
            } else {
                commonTags = commonTags.intersection(Set.init(item.tags.map{$0.text}))
            }
        }
        return Array(commonTags)
    }

     func enableToolbarItemsIfNeeded() {
        if viewState == .edit {
            var enableToolBar = false
            if selectedItems().count > 0 {
                self.title = String(format: "sidebar.allTags.navbar.selected".localized, String(describing: selectedItems().count))
                enableToolBar = true
            } else {
                self.title = "sidebar.allTags.navbar.select".localized
            }
            if let toolbarItems = self.toolbar?.items {
                toolbarItems.forEach { item in
                    item.isEnabled = enableToolBar
                }
            }
            updateSelectAllTitle()
        }
    }

    func updateSelectAllTitle() {
        let selectAll = shouldSelectAll
#if !targetEnvironment(macCatalyst)
        if selectAll {
            selectAllButton?.title = "sidebar.allTags.navbar.selectAll".localized
        } else {
            selectAllButton?.title = "sidebar.allTags.navbar.selectNone".localized
        }
        #else
        if let items = self.view.toolbar?.items, let item = items.first(where: {$0.itemIdentifier == FTSelectNotesToolbarItem.identifier}) {
            if selectAll {
                item.title = "sidebar.allTags.navbar.selectAll".localized
            } else {
                item.title = "sidebar.allTags.navbar.selectNone".localized
            }
        }
#endif
    }

    // MARK: - IBActions
    @IBAction func selectAction(_ sender: Any) {
        if viewState == .edit {
            activateViewMode()
        } else {
            activeEditMode()
        }
        clearContextMenuIndex()
        self.collectionView.reloadData()
        enableToolbarItemsIfNeeded()
    }

     func activeEditMode() {
#if !targetEnvironment(macCatalyst)
        selectAllButton = UIBarButtonItem(title: "sidebar.allTags.navbar.selectAll".localized, style: .plain, target: self, action: #selector(selectAndDeselect))
        navigationItem.leftBarButtonItem = selectAllButton
         selectButtom?.title = "sidebar.allTags.navbar.done".localized
#endif
         self.title = "sidebar.allTags.navbar.select".localized
        viewState = .edit
        self.toolbar?.isHidden = false
    }

     func activateViewMode() {
        self.title = "sidebar.allTags".localized
        viewState = .none
        self.toolbar?.isHidden = true
        self.selectedPaths = []
        selectOrDeselectAllBooks(shouldSelect: false)
#if !targetEnvironment(macCatalyst)
        selectButtom?.title = "sidebar.allTags.navbar.select".localized
        if navigationItem.leftBarButtonItems?.count ?? 0 > 0 {
            navigationItem.leftBarButtonItems?.removeLast()
        }
         #else
         if let toolbar = self.view.toolbar as? FTShelfToolbar {
             toolbar.switchMode(.tags)
         }
#endif
    }

    func selectOrDeselectAllBooks(shouldSelect: Bool) {
        let books = generateBooks()
        if let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell {
            for (index, _) in books.enumerated() {
                let indexPath = IndexPath(row: index, section: 0)
                if shouldSelect {
                    booksCell.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                } else {
                    booksCell.collectionView.deselectItem(at: indexPath, animated: false)
                }
            }
        }
    }

    func selectOrDeselectAllPages(shouldSelect: Bool) {
        let pages = generatePages()
        for (index, _) in pages.enumerated() {
            let indexPath = IndexPath(row: index, section: 1)
            if shouldSelect {
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            } else {
                self.collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }

    var shouldSelectAll: Bool {
        var selectAll = false
        var selectedItems = [IndexPath]()

        if let selectedPages = self.collectionView.indexPathsForSelectedItems {
            selectedItems = selectedPages
        }

        if let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell,
           let selectedBooks = booksCell.collectionView.indexPathsForSelectedItems {
            selectedItems += selectedBooks
        }

        if tagItems.count != selectedItems.count {
            selectAll = true
        }
        return selectAll
    }

   @objc func selectAndDeselect() {
        let selectAll = shouldSelectAll
        selectOrDeselectAllBooks(shouldSelect: selectAll)
        selectOrDeselectAllPages(shouldSelect: selectAll)
        updateSelectAllTitle()
        enableToolbarItemsIfNeeded()
    }

    func openInNewWindow() {
        if let selectedItem = self.selectedItems().first, let shelfItem = selectedItem.shelfItem  {
            self.openItemInNewWindow(shelfItem, pageIndex: selectedItem.pageIndex)
        }
    }

    @IBAction func shareAction(_ sender: Any) {
        self.createDocumentForSelectedPages()
    }

    @IBAction func editTagsAction(_ sender: Any?) {
        let selectedItems = self.selectedItems()
        let tags = self.commonTagsFor(items: selectedItems)
        let sortedArray = FTCacheTagsProcessor.shared.tagsModelForTags(tags: tags)
        FTTagsViewController.presentTagsController(onController: self, tags: sortedArray)
    }

    @IBAction func removeTagsAction(_ sender: Any?) {
        let selectedItems = self.selectedItems()

        UIAlertController.showDeleteDialog(with: "sidebar.allTags.removeTags.alert.message".localized, message: "", from: self) {
            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: "")

            if let tag = self.selectedTag {
                Task {
                    try await FTShelfTagsUpdateHandler.shared.updateTag(tag, for: selectedItems, updateType: FTTagsUpdateType.remove)
                    loadingIndicatorViewController.hide {
                        reloadView()
                    }
                }
            } else {
                Task {
                    try await FTShelfTagsUpdateHandler.shared.updateTag(nil, for: selectedItems, updateType: .removeAll)
                    loadingIndicatorViewController.hide {
                        reloadView()
                    }
                }
            }

            @MainActor
            func reloadView() {
                let selectedArraySet = Set(selectedItems.map { $0.id })
                self.tagItems = self.tagItems.filter { !selectedArraySet.contains($0.id) }
                self.collectionView.reloadData()
                self.activateViewMode()
                if self.tagItems.isEmpty {
                    self.showPlaceholderView()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshSideMenu"), object: nil)
                }

            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension FTShelfTagsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return generatePages().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTShelfTagsPageCell", for: indexPath) as? FTShelfTagsPageCell else {
            return UICollectionViewCell()
        }
        cell.selectionBadge?.isHidden = viewState == .none ? true : false

        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTShelfTagsBooksCell", for: indexPath) as? FTShelfTagsBooksCell else {
                return UICollectionViewCell()
            }
            cell.delegate = self
            cell.prepareCellWith(books: generateBooks(), viewState: viewState)
            return cell
        } else if indexPath.section == 1 {
            let pages = generatePages()
            let item = pages[indexPath.row]
            cell.updateTagsItemCellContent(tagsItem: item, isRegular: self.traitCollection.isRegular)
        }
        cell.isSelected = true
        return cell
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
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.enableToolbarItemsIfNeeded()
        if viewState == .none {
            if indexPath.section == 1 {
                let pages = generatePages()
                let item = pages[indexPath.row]
                if let shelf = item.shelfItem {
                    self.delegate?.openNotebook(shelfItem: shelf, page: item.pageIndex ?? 0)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.enableToolbarItemsIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0, generateBooks().count > 0 {
            return CGSize(width: collectionView.frame.width, height: 250);
        }
        if indexPath.section == 1 {
            let pages = generatePages()
            let item = pages[indexPath.row]
            let columnWidth = columnWidthForSize(self.view.frame.size) - 12
            let size = CGSize(width: columnWidth, height: ((columnWidth)/FTShelfTagsConstants.Page.potraitAspectRation) + FTShelfTagsConstants.Page.extraHeightPadding)

            if let page = item.page {
                if  page.pdfPageRect.size.width > page.pdfPageRect.size.height  { // landscape
                    return CGSize(width: columnWidth, height: ((columnWidth)/FTShelfTagsConstants.Page.landscapeAspectRatio) + FTShelfTagsConstants.Page.extraHeightPadding)
                } else {
                    return CGSize(width: columnWidth, height: ((columnWidth)/FTShelfTagsConstants.Page.potraitAspectRation) + FTShelfTagsConstants.Page.extraHeightPadding)
                }

            }
        }
        return CGSize(width: collectionView.frame.width, height: 0.1);

    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! FTShelfTagsSectionHeader
            if indexPath.section == 0 {
                sectionHeader.label.text = "sidebar.allTags.notebooks".localized
            } else {
                sectionHeader.label.text = "sidebar.allTags.pages".localized
            }
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let books = generateBooks()
        let pages = generatePages()
        if section == 0, books.count > 0 {
            return CGSize(width: collectionView.frame.width, height: books.count > 0 ? 45 : 0)
        } else if section == 1, pages.count > 0 {
            return CGSize(width: collectionView.frame.width, height: pages.count > 0 ? 45 : 0)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: FTShelfTagsConstants.Page.gridHorizontalPadding, bottom: 16, right: FTShelfTagsConstants.Page.gridHorizontalPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return FTShelfTagsConstants.Page.minInterItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTShelfTagsConstants.Page.minLineSpacing
    }


}


// MARK: - Share
extension FTShelfTagsViewController {

    private func createDocumentForSelectedPages() {
        let selectedBooks = self.selectedItems().filter {$0.type == .book}
        let selectedPages = self.selectedItems().filter {$0.type == .page}
        let bookShelfs = selectedBooks.map {$0.shelfItem} as? [FTShelfItemProtocol]
        var itemsToExport = bookShelfs
        let group = DispatchGroup()

        let multiples = Dictionary(grouping: selectedPages, by: {$0.shelfItem?.documentUUID})
        multiples.values.forEach { tagItems in
            group.enter()
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(FTUtils.getUUID());
            let pages = tagItems.map {$0.page} as! [FTPageProtocol]
            if let doc = tagItems.first?.document {
                doc.openDocument(purpose: .read, completionHandler: { _, error in
                    let info = FTDocumentInputInfo();
                    info.rootViewController = self;
                    info.overlayStyle = FTCoverStyle.clearWhite
                    info.isNewBook = true;

                    doc.createDocumentAtTemporaryURL(url, purpose: .default, fromPages: pages, documentInfo: info) { _, error in
                        if let docum = FTDocumentItem.init(fileURL: url) as? FTShelfItemProtocol {
                            itemsToExport?.append(docum)
                            doc.closeDocument(completionHandler: nil)
                            group.leave()
                        }
                    }
                })
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if let books = itemsToExport, books.count > 0 {
                self.shareNotebooks(books)
            }
        }
    }

    private func shareNotebooks(_ items: [FTShelfItemProtocol]) {
        if !items.isEmpty {
            let coordinator = FTShareCoordinator(shelfItems: items, presentingController: self)
            FTShareFormatHostingController.presentAsFormsheet(over: self, using: coordinator, option: .notebook, shelfItems: items)
        }
    }

    func clearContextMenuIndex() {
        if let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell {
            booksCell.contextMenuSelectedIndexPath = nil
        }
        self.contextMenuSelectedIndexPath = nil
    }
}

// MARK: FTTagsViewControllerDelegate
extension FTShelfTagsViewController: FTTagsViewControllerDelegate {

    private func reloadListFor(docIds: [String]) {

        var indexesToRemove = [Int]()
        if self.tagItems.count > 0 {
            for i in (0..<self.tagItems.count) {
                let item = self.tagItems[i]
                if let docId = item.shelfItem?.documentUUID {
                    if docIds.contains(docId) {
                        if let tags = try? FTCacheTagsProcessor.shared.tagsFor(shelfItem: item) {
                            if tags.count > 0 {
                                self.tagItems[i].removeAllTags()
                                self.tagItems[i].setTags(tags)
                            } else {
                                indexesToRemove.append(i)
                            }
                        }
                    }
                }
            }
        }
        let sortedIndexesToRemove = indexesToRemove.sorted(by: >)
        for index in sortedIndexesToRemove {
            if index >= 0 && index < self.tagItems.count {
                self.tagItems.remove(at: index)
            }
        }
        if self.tagItems.isEmpty {
            self.showPlaceholderView()
            self.presentedViewController?.dismiss(animated: true)
        } else {
            self.hidePlaceholderView()
        }
        self.collectionView.reloadData()
        for indexPath in selectedPaths {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        enableToolbarItemsIfNeeded()
    }

    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void)) {

    }

    func addTagsViewController(didTapOnBack controller: FTTagsViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func didAddTag(tag: FTTagModel) async throws {
        //Add tag for selected pages
        let selectedItems = self.selectedItems()
        try await FTShelfTagsUpdateHandler.shared.updateTag(tag, for: selectedItems, updateType: .add)
        let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: tag)
        reloadListFor(docIds: docIds)
    }

    func didRenameTag(tag: FTTagModel, renamedTag: FTTagModel) async throws {
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: "")
        let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: tag)
        try await FTShelfTagsUpdateHandler.shared.renameTag(tag: tag, with: renamedTag, for: nil)
        loadingIndicatorViewController.hide(nil)
        reloadListFor(docIds: docIds)
    }

    func didUnSelectTag(tag: FTTagModel) async throws {
        let selectedItems = self.selectedItems()
        let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: tag)
        try await FTShelfTagsUpdateHandler.shared.updateTag(tag, for: selectedItems, updateType: .remove)
        reloadListFor(docIds: docIds)
    }

    func didDeleteTag(tag: FTTagModel) async throws {
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: "")
        let docIds = FTCacheTagsProcessor.shared.documentIdsForTag(tag: tag)
        try await FTShelfTagsUpdateHandler.shared.deleteTag(tag: tag, for: nil)
        loadingIndicatorViewController.hide(nil)
        reloadListFor(docIds: docIds)
    }
}

// MARK: FTShelfTagsAndBooksDelegate
extension FTShelfTagsViewController: FTShelfTagsAndBooksDelegate {
    func openNotebook(shelfItem: FTDocumentItemProtocol, page: Int) {
        self.delegate?.openNotebook(shelfItem: shelfItem, page: page)
    }

    func shouldEnableToolbarItems() {
        self.enableToolbarItemsIfNeeded()
    }

    func editTags() {
        self.editTagsAction(nil)
    }

    func removeTags() {
        self.removeTagsAction(nil)
    }

    func openItemInNewWindow() {
        self.openInNewWindow()
    }

}
