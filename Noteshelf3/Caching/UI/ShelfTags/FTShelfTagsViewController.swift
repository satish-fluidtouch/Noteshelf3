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
    var tagItems = [FTShelfTagsItem]() {
        didSet {
            tagItems = tagItems.filter({$0.documentItem?.URL.isPinEnabledForDocument() == false})
        }
    }
    private var selectedTagItems = Dictionary<String, FTShelfTagsItem>();
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    var books = [FTShelfTagsItem]()
    var pages = [FTShelfTagsItem]()

    var selectedTag: FTTagModel? {
        didSet {
            if self.collectionView != nil {
                activateViewMode()
                enableToolbarItemsIfNeeded()
            }
            self.title = (nil == self.selectedTag) ? "sidebar.allTags".localized : "#" + (self.selectedTag?.text ?? "")
        }
    }
    var viewState: FTShelfTagsPageState = .none
    var contextMenuSelectedIndexPath: IndexPath?
    var selectedPaths = [IndexPath]()
    var selectedItems = [FTShelfTagsItem]()
    private var currentSize: CGSize = .zero

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

        configureActivityIndicator()
        loadShelfTagItems()
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
            removeTagsBtn?.setTitle("sidebar.allTags.contextualMenu.removeTags".localized, for: .normal)
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
            if let tagItem = FTTagsProvider.shared.getTagItemFor(tagName: tag) {
                self.selectedTag = tagItem.tag
            } else {
                selectedTag = FTTagModel(text: tag)
            }
        } else {
            loadShelfTagItems()
        }
        self.title = self.selectedTag == nil ? "sidebar.allTags".localized : "#" + (self.selectedTag?.text ?? "")
        enableToolbarItemsIfNeeded()
    }

    func reloadContent() {
        self.loadShelfTagItems()
    }

    private func configureActivityIndicator() {
        // Add activity indicator in the view
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }

    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }

    private func generateBooks() -> [FTShelfTagsItem] {
       return self.tagItems.filter({$0.type == .book})
    }

    private func generatePages() -> [FTShelfTagsItem] {
        return self.tagItems.filter({$0.type == .page})
    }

    private func loadShelfTagItems() {
        viewModel = FTShelfTagsPageModel()
        viewModel?.selectedTag = self.selectedTag?.text ?? "";
        showActivityIndicator()
        viewModel?.buildCache(completion: { result in
            self.tagItems = result
            self.books = self.generateBooks()
            self.pages = self.generatePages()
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
            self.hideActivityIndicator()
        })
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

    func selectedBooksOrPages() -> [FTShelfTagsItem] {
        if let indexPath = contextMenuSelectedIndexPath, pages.count > 0 {
            return [pages[indexPath.row]]
        } else if books.count > 0, let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell, let indexPath = booksCell.contextMenuSelectedIndexPath {
            return [books[indexPath.row]]
        } else {
            var selectedTagItems = [FTShelfTagsItem]()

            if let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell, let selectedBooks = booksCell.collectionView.indexPathsForSelectedItems {
                self.selectedPaths = selectedBooks
            }
            if let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems, selectedIndexPaths.count > 0 {
                self.selectedPaths += selectedIndexPaths
            }
            if self.selectedPaths.count > 0 {
                self.selectedPaths.forEach({ indexPath in
                    if indexPath.section == 0, books.count > 0 && indexPath.row <= books.count - 1 {
                        selectedTagItems.append(books[indexPath.row])
                    } else if indexPath.section == 1, indexPath.row <= pages.count - 1 {
                        selectedTagItems.append(pages[indexPath.row])
                    }
                })
                return selectedTagItems
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
            if selectedBooksOrPages().count > 0 {
                self.title = String(format: "sidebar.allTags.navbar.selected".localized, String(describing: selectedBooksOrPages().count))
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
            track(EventName.shelf_tag_select_done_tap, screenName: ScreenName.shelf_tags)
        } else {
            selectOrDeselectAllBooks(shouldSelect: false)
            activeEditMode()
            track(EventName.shelf_tag_select_tap, screenName: ScreenName.shelf_tags)
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
         self.title = (nil == self.selectedTag) ? "sidebar.allTags".localized : "#" + (self.selectedTag?.text ?? "")
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
       if selectAll {
           track(EventName.shelf_tag_select_selectall_tap, screenName: ScreenName.shelf_tags)
       } else {
           track(EventName.shelf_tag_select_selectnone_tap, screenName: ScreenName.shelf_tags)
       }
        selectOrDeselectAllBooks(shouldSelect: selectAll)
        selectOrDeselectAllPages(shouldSelect: selectAll)
        updateSelectAllTitle()
        enableToolbarItemsIfNeeded()
    }

    func openInNewWindow() {
        if let selectedItem = self.selectedBooksOrPages().first, let shelfItem = selectedItem.documentItem  {
            if selectedItem.type == .page {
                self.openItemInNewWindow(shelfItem, pageIndex: selectedItem.pageIndex)
            } else {
                self.openItemInNewWindow(shelfItem, pageIndex: 0)
            }
        }
    }

    func shareOperation() {
        self.createDocumentForSelectedPages()
    }

    func edittagsOperation() {
        self.selectedItems = self.selectedBooksOrPages()
        let tags = self.commonTagsFor(items: selectedItems)
        let tagItems = FTTagsProvider.shared.getAllTagItemsFor(tags)
        FTTagsViewController.presentTagsController(onController: self, tags: tagItems)
    }

    func removeTagsOperation() {
        selectedItems = self.selectedBooksOrPages()

        UIAlertController.showRemoveTagsDialog(with: "sidebar.allTags.removeTags.alert.message".localized, message: "", from: self) {
            for (index,selectedItem) in self.selectedItems.enumerated() {
                if let shelfItem = selectedItem.documentItem {
                    if selectedItem.type == .page, let pageUUID = selectedItem.pageUUID {
                        let shelftagItem = FTTagsProvider.shared.shelfTagsItemForPage(documentItem: shelfItem, pageUUID: pageUUID, tags: selectedItem.tags.map({$0.text}))
                        self.selectedItems[index].tags.removeAll()
                        shelftagItem.tags = self.selectedItems[index].tags
                    } else {
                        let shelftagItem = FTTagsProvider.shared.shelfTagsItemForBook(documentItem: shelfItem)
                        self.selectedItems[index].tags.removeAll()
                        shelftagItem.tags = self.selectedItems[index].tags
                    }
                }
            }
            self.refreshView()
            FTShelfTagsUpdateHandler.shared.updateTagsFor(items: self.selectedItems, completion: nil)
        }
    }

    @IBAction private func shareAction(_ sender: Any) {
        shareOperation()
        track(EventName.shelf_tag_select_share_tap, screenName: ScreenName.shelf_tags)
    }

    @IBAction private func editTagsAction(_ sender: Any?) {
        edittagsOperation()
        track(EventName.shelf_tag_select_edittags_tap, screenName: ScreenName.shelf_tags)
    }

    @IBAction func removeTagsAction(_ sender: Any?) {
        removeTagsOperation()
        track(EventName.shelf_tag_select_removetags_tap, screenName: ScreenName.shelf_tags)
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
        return pages.count
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
            cell.prepareCellWith(books: books, viewState: viewState, parentVC: self)
            return cell
        } else if indexPath.section == 1 {
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
        track(EventName.shelf_tag_select_page_tap, screenName: ScreenName.shelf_tags)
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.enableToolbarItemsIfNeeded()
        if viewState == .none {
            if indexPath.section == 1 {
                let item = pages[indexPath.row]
                if let shelf = item.documentItem {
                    self.delegate?.openNotebook(shelfItem: shelf, page: item.pageIndex)
                    track(EventName.shelf_tag_page_tap, screenName: ScreenName.shelf_tags)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.enableToolbarItemsIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0, books.count > 0 {
            return CGSize(width: collectionView.frame.width, height: 250);
        }
        if indexPath.section == 1 {
            let item = pages[indexPath.row]
            let columnWidth = columnWidthForSize(self.view.frame.size) - 12
            if let pageRect = item.pdfKitPageRect {
                if  pageRect.size.width > pageRect.size.height  { // landscape
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
        let selectedBooks = self.selectedBooksOrPages().filter {$0.type == .book}
        let selectedPages = self.selectedBooksOrPages().filter {$0.type == .page}
        let bookShelfs = selectedBooks.map {$0.documentItem} as? [FTShelfItemProtocol]
        var itemsToExport = bookShelfs
        let group = DispatchGroup()

        let multiples = Dictionary(grouping: selectedPages, by: {$0.documentItem?.documentUUID})
        multiples.values.forEach { tagItems in
            group.enter()
            let pagesUUIDs = tagItems.map({$0.pageUUID})
            if let docUrl = tagItems.first?.documentItem?.URL {
                let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(docUrl.deletingPathExtension().lastPathComponent)
                let request = FTDocumentOpenRequest(url: docUrl, purpose: .read)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    if let docPages = document?.pages() as? [FTPageProtocol] {
                        let pages = docPages.filter{ page in
                            return pagesUUIDs.contains(page.uuid)
                        }
                        let info = FTDocumentInputInfo()
                        info.rootViewController = self
                        info.overlayStyle = FTCoverStyle.clearWhite
                        info.isNewBook = true
                        if let document {
                            document.createDocumentAtTemporaryURL(url, purpose: .default, fromPages: pages, documentInfo: info) { _, error in
                                if error == nil {
                                    let docum = FTDocumentItem.init(fileURL: url)
                                    itemsToExport?.append(docum)
                                }
                                FTNoteshelfDocumentManager.shared.closeDocument(document: document, token: token) { _ in
                                    group.leave()
                                }
                            }
                        }
                    }
                }
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

    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void)) {

    }

    func refreshView() {
        self.tagItems.removeAll(where: {$0.tags.isEmpty})

        if selectedTag?.text != nil {
            self.tagItems = self.tagItems.filter { item in
                return item.tags.contains { $0.text == selectedTag?.text }
            }
        } else {
            self.tagItems = self.tagItems.filter { !$0.tags.isEmpty }
        }
        if let booksCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FTShelfTagsBooksCell, let selectedBooks = booksCell.collectionView.indexPathsForSelectedItems, viewState == .edit  {
            for selectedItem in selectedBooks {
                booksCell.collectionView.deselectItem(at: selectedItem, animated: false)
            }
        }
        self.books = self.generateBooks()
        self.pages = self.generatePages()
        self.collectionView.reloadData()
        self.activateViewMode()
        self.hidePlaceholderView()
        if self.tagItems.isEmpty {
            self.showPlaceholderView()
        }
    }

    func didDismissTags() {
        let items = self.selectedTagItems.values.reversed();
        self.selectedTagItems.removeAll()
        refreshView()
        FTShelfTagsUpdateHandler.shared.updateTagsFor(items: items, completion: nil)
    }

    func addTagsViewController(didTapOnBack controller: FTTagsViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func didAddTag(tag: FTTagModel) {
        //Add tag for selected pages
        updateShelfTagItemsFor(tag: tag)
    }

    func didUnSelectTag(tag: FTTagModel) {
        updateShelfTagItemsFor(tag: tag)
    }

    func updateShelfTagItemsFor(tag: FTTagModel) {
        let selectedItems = selectedItems

        if let tagModel = FTTagsProvider.shared.getTagItemFor(tagName: tag.text) {
            tagModel.updateTagForShelfTagItem(shelfTagItems: selectedItems) { items in
                items.forEach { item in
                    if item.type == .page, let pageUUID = item.pageUUID {
                        self.selectedTagItems[pageUUID] = item
                    } else if let docUUID = item.documentUUID {
                        self.selectedTagItems[docUUID] = item
                    }
                }
            }
            self.collectionView.reloadData()
        }
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
        self.edittagsOperation()
    }

    func removeTags() {
        self.removeTagsOperation()
    }

    func openItemInNewWindow() {
        self.openInNewWindow()
    }

}
