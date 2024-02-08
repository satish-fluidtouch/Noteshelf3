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
    func editTags(_ taggedEntity: [FTTaggedEntity])
    func removeTags(_ taggedEntity: [FTTaggedEntity])
    func openTaggedItemInNewWindow(_ taggedEntity: FTTaggedEntity)
}

class FTShelfTagsViewController: UIViewController {
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var currentTag: FTTag?;
    var viewState: FTShelfTagsPageState = .none
    private var currentSize: CGSize = .zero

    weak var delegate: FTShelfTagsPageDelegate?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar?
    @IBOutlet weak var removeTagsBtn: UIButton?
    @IBOutlet weak var editTagsBtn: UIButton?
    @IBOutlet weak var shareBtn: UIButton?
    @IBOutlet weak var emptyPlaceholderView: UIView?
    @IBOutlet weak private var selectButtom: UIBarButtonItem?
    private var selectAllButton: UIBarButtonItem?

    private var tagCategory = FTShelfTagCategory();

    private func updateTitle() {
        if viewState == .edit {
            if self.tagCategory.selectedEntities.count > 0 {
                self.title = String(format: "sidebar.allTags.navbar.selected".localized, String(describing: self.tagCategory.selectedEntities.count))
            } else {
                self.title = "sidebar.allTags.navbar.select".localized
            }
        }
        else {
            if let tag = currentTag {
                self.title = (tag.tagType == .allTag) ? tag.tagDisplayName : "#".appending(tag.tagDisplayName);
            }
        }
    }
    
    func setCurrentTag(_ tag: FTTag) {
        self.currentTag = tag;
        tagCategory.currentTag = tag;
        self.updateTitle();
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        self.updateTitle();
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateTags(_:)), name: .didUpdateTags, object: nil);
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self](_) in
            self?.updateToolbarTitles()
            self?.collectionView?.reloadData()
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

    @objc func didUpdateTags(_ notification: Notification) {
        if let userInfo = notification.userInfo
            , let tags = userInfo["tags"] as? [FTTag]
            , let curTag = self.currentTag
            ,tags.contains(curTag) {
            if let operation = userInfo["operation"] as? String {
//                if operation == "delete" {
//                    self.loadShelfTagItems();
//                    self.updateTitle();
//                    enableToolbarItemsIfNeeded()
//                }
//                else 
                if operation == "rename" {
                    self.loadShelfTagItems();
                    self.updateTitle();
                    enableToolbarItemsIfNeeded()
                }
            }
        }
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

    private func loadShelfTagItems() {
        if tagCategory.allEntities.isEmpty {
            self.showPlaceholderView();
        }
        else {
            self.hidePlaceholderView();
            if self.viewState == .edit, !self.tagCategory.selectedEntities.isEmpty {
                self.collectionView?.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            } else {
                self.collectionView?.reloadData()
            }
        }
    }

    private func showPlaceholderView() {
        selectButtom?.isEnabled = false
        self.collectionView?.isHidden = true
        self.emptyPlaceholderView?.frame = self.collectionView?.frame ?? self.view.bounds;
        self.emptyPlaceholderView?.isHidden = false
    }

    private func hidePlaceholderView() {
        selectButtom?.isEnabled = true
        self.collectionView?.isHidden = false
        self.emptyPlaceholderView?.isHidden = true
    }

     func enableToolbarItemsIfNeeded() {
        if viewState == .edit {
            let enableToolBar = !self.tagCategory.selectedEntities.isEmpty;
            self.updateTitle();
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
            activeEditMode()
            track(EventName.shelf_tag_select_tap, screenName: ScreenName.shelf_tags)
        }
        self.collectionView?.reloadData()
        enableToolbarItemsIfNeeded()
    }

    func activeEditMode() {
#if !targetEnvironment(macCatalyst)
        selectAllButton = UIBarButtonItem(title: "sidebar.allTags.navbar.selectAll".localized, style: .plain, target: self, action: #selector(selectAndDeselect))
        navigationItem.leftBarButtonItem = selectAllButton
        selectButtom?.title = "sidebar.allTags.navbar.done".localized
#endif
        viewState = .edit
        self.updateTitle();
        self.toolbar?.isHidden = false
    }

    func activateViewMode() {
        self.updateTitle();
        viewState = .none
        self.toolbar?.isHidden = true
        self.tagCategory.deselectAll();
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

    var shouldSelectAll: Bool {
        return self.tagCategory.selectedEntities.count != self.tagCategory.allEntities.count
    }

    @objc func selectAndDeselect() {
        let selectAll = shouldSelectAll
        if selectAll {
            track(EventName.shelf_tag_select_selectall_tap, screenName: ScreenName.shelf_tags)
        } else {
            track(EventName.shelf_tag_select_selectnone_tap, screenName: ScreenName.shelf_tags)
        }
        selectAll ? self.tagCategory.selectAll() : self.tagCategory.deselectAll();
        updateSelectAllTitle()
        enableToolbarItemsIfNeeded()
        self.collectionView?.reloadItems(at: self.collectionView.indexPathsForVisibleItems);
    }

    func shareOperation() {
        self.createDocumentForSelectedPages()
    }

    private func edittagsOperation() {
        let selectedEntities = self.tagCategory.selectedEntities;
        guard !selectedEntities.isEmpty else {
            return;
        }
        var commonTags = Set<FTTag>();
        selectedEntities.enumerated().forEach { eachEntry in
            let tags = eachEntry.element.tags;
            commonTags = eachEntry.offset == 0 ? tags : commonTags.intersection(tags);
        }
        let allTags = FTTagsProvider.shared.getTags();
        let allTagModels = allTags.compactMap({FTTagModel(id: $0.id, text: $0.tagName, image: nil, isSelected: commonTags.contains($0))})

        FTTagsViewController.showTagsController(onController: self, tags: allTagModels);
    }

    private func removeTagsOperation() {
        let selectedEntities = self.tagCategory.selectedEntities;
        guard !selectedEntities.isEmpty else {
            return;
        }
        UIAlertController.showRemoveTagsDialog(with: "sidebar.allTags.removeTags.alert.message".localized, message: "", from: self) {
            var allTags = Set<FTTagModel>();
            selectedEntities.forEach { eachItem in
                allTags.formUnion(eachItem.tags.map({FTTagModel(id: $0.id, text: $0.tagName, image: nil, isSelected: false)}));
            }
            guard !allTags.isEmpty else {
                return;
            }
            
            let indicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.splitViewController ?? self, withText: "Updating");
            let updater = FTDocumentTagUpdater();
            _ = updater.updateTags(addedTags: [], removedTags: Array(allTags), entities: Array(selectedEntities)) {
                debugLog("removed complete: \(updater)");
                indicator.hide();
                self.refreshView()
            }
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
        return self.tagCategory.pages.count;
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
            return cell
        } else if indexPath.section == 1 {
            let item = self.tagCategory.pages[indexPath.row]
            cell.updateTaggedEntity(taggedEntity: item, isRegular: self.traitCollection.isRegular);
        }
        
        let item = self.tagCategory.pages[indexPath.row]
        if viewState == .edit,self.tagCategory.selectedEntities.contains(item) {
            cell.isItemSelected = true;
        }
        else {
            cell.isItemSelected = false;
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == 0, let pageCell = cell as? FTShelfTagsBooksCell {
            pageCell.delegate = self
            pageCell.prepareCell(tagCategory: self.tagCategory, viewState: viewState, parentVC: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewState == .none {
            if indexPath.section == 1 {
                let item = self.tagCategory.pages[indexPath.row];
                let docId = item.documentUUID;
                let pageIndex = (item as? FTPageTaggedEntity)?.pageProperties.pageIndex ?? 0
                item.documentShelfItem(false) { docItem in
                    if let _shelfItem = docItem {
                        self.delegate?.openNotebook(shelfItem: _shelfItem, page: pageIndex)
                        track(EventName.shelf_tag_page_tap, screenName: ScreenName.shelf_tags)
                    }
                }
            }
        }
        if indexPath.section == 1,viewState == .edit {
            let item = self.tagCategory.pages[indexPath.row];
            if self.tagCategory.selectedEntities.contains(item) {
                self.tagCategory.setSelected(item, selected: false);
            }
            else {
                self.tagCategory.setSelected(item, selected: true);
            }
            collectionView.reloadItems(at: [indexPath])
        }
        self.enableToolbarItemsIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.enableToolbarItemsIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let booksCount = self.tagCategory.books.count;
        if indexPath.section == 0, booksCount > 0 {
            return CGSize(width: collectionView.frame.width, height: 250);
        }
        if indexPath.section == 1 {
            let pageRect = (self.tagCategory.pages[indexPath.row] as? FTPageTaggedEntity)?.pageProperties.pageSize;
            let columnWidth = columnWidthForSize(self.view.frame.size) - 12
            if let pageRect = pageRect {
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
        let booksEmpty = self.tagCategory.books.isEmpty;
        let pagesEmpty = self.tagCategory.pages.isEmpty;
        
        if section == 0, !booksEmpty {
            return CGSize(width: collectionView.frame.width, height: 45)
        } else if section == 1, !pagesEmpty {
            return CGSize(width: collectionView.frame.width, height: 45)
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
        var selBooks = [FTTaggedEntity]();
        var selPages = [String: [FTPageTaggedEntity]]();
        
        self.tagCategory.selectedEntities.forEach { eachitem in
            if eachitem.tagType == .book {
                selBooks.append(eachitem);
            }
            else if let pageEntity = eachitem as? FTPageTaggedEntity {
                var pages = selPages[pageEntity.documentUUID] ?? [FTPageTaggedEntity]();
                pages.append(pageEntity);
                selPages[pageEntity.documentUUID] = pages;
            }
        }
        
        let group = DispatchGroup()
        var itemsToExport = [FTShelfItemProtocol]();
        
        selBooks.forEach { eachItem in
            group.enter();
            eachItem.documentShelfItem { docItemProtocol in
                if let docItem = docItemProtocol {
                    itemsToExport.append(docItem);
                }
                group.leave();
            }
        }
        
        selPages.forEach { eachItem in
            group.enter();
            let doc = eachItem.key;
            let relativePath = FTCachedDocument(documentID: doc).relativePath
            FTNoteshelfDocumentProvider.shared.document(with: doc,orRelativePath: relativePath) { docItemProtocol in
                guard let docItem = docItemProtocol else {
                    group.leave();
                    return;
                }
                let request = FTDocumentOpenRequest(url: docItem.URL, purpose: .read)
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                    guard let _document = document else {
                        group.leave()
                        return;
                    }
                    let pagesUUIDs = eachItem.value.map{$0.pageUUID};
                    if let docPages = document?.pages() as? [FTPageProtocol] {
                        let pages = docPages.filter{ page in
                            return pagesUUIDs.contains(page.uuid)
                        }
                        let info = FTDocumentInputInfo()
                        info.rootViewController = self
                        info.overlayStyle = FTCoverStyle.clearWhite
                        info.isNewBook = true
                        
                        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(docItem.URL.title)
                        _ = _document.createDocumentAtTemporaryURL(url, purpose: .default, fromPages: pages, documentInfo: info) { _, error in
                            if error == nil {
                                let docum = FTDocumentItem.init(fileURL: url)
                                itemsToExport.append(docum)
                            }
                            FTNoteshelfDocumentManager.shared.closeDocument(document: _document, token: token) { _ in
                                group.leave()
                            }
                        }
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            if !itemsToExport.isEmpty {
                self.shareNotebooks(itemsToExport)
            }
        }
    }

    private func shareNotebooks(_ items: [FTShelfItemProtocol]) {
        if !items.isEmpty {
            let coordinator = FTShareCoordinator(shelfItems: items, presentingController: self)
            FTShareFormatHostingController.presentAsFormsheet(over: self, using: coordinator, option: .notebook, shelfItems: items)
        }
    }
}

// MARK: FTTagsViewControllerDelegate
extension FTShelfTagsViewController: FTTagsViewControllerDelegate {
    func tagsViewController(_ contorller: FTTagsViewController, addedTags: [FTTagModel], removedTags: [FTTagModel]) {
        let selectedItems = self.tagCategory.selectedEntities;
        self.activateViewMode()
        self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        
        if addedTags.isEmpty, removedTags.isEmpty {
            return;
        }

        let updater = FTDocumentTagUpdater();
        let indicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.splitViewController ?? self, withText: "Updating");
        _ = updater.updateTags(addedTags: addedTags, removedTags: removedTags, entities: Array(selectedItems)) { 
            debugLog("updater: \(updater)");
            indicator.hide();
        }
    }
    
    func refreshView() {
        if let tag = self.currentTag {
            self.setCurrentTag(tag);
        }
        self.loadShelfTagItems();
        self.activateViewMode()
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

    func editTags(_ taggedEntity: [FTTaggedEntity]) {
        taggedEntity.forEach { eachItem in
            self.tagCategory.setSelected(eachItem, selected: true);
        }
        self.edittagsOperation()
    }

    func removeTags(_ taggedEntity: [FTTaggedEntity]) {
        taggedEntity.forEach { eachItem in
            self.tagCategory.setSelected(eachItem, selected: true);
        }
        self.removeTagsOperation()
    }

    func openTaggedItemInNewWindow(_ taggedEntity: FTTaggedEntity) {
        taggedEntity.documentShelfItem { docItem in
            guard let shelfItem = docItem else {
                return;
            }
            if let pageEntity = taggedEntity as? FTPageTaggedEntity {
                self.openItemInNewWindow(shelfItem, pageIndex: pageEntity.pageProperties.pageIndex);
            }
            else {
                self.openItemInNewWindow(shelfItem, pageIndex: 0);
            }
        }
    }
}

class FTShelfTagCategory: NSObject {
    private(set) var books = [FTTaggedEntity]();
    private(set) var pages = [FTTaggedEntity]();
    private(set) var allEntities = [FTTaggedEntity]();
    private(set) var selectedEntities = Set<FTTaggedEntity>();

    var currentTag: FTTag? {
        didSet {
            self.selectedEntities.removeAll();
            self.allEntities.removeAll();
            var booksEntries = [FTTaggedEntity]();
            var pagessEntries = [FTTaggedEntity]();
            self.currentTag?.getTaggedEntities(sort: true, { entities in
                self.allEntities = entities;
                self.allEntities.forEach { eachType in
                    if eachType.tagType == .book {
                        booksEntries.append(eachType)
                    }
                    else {
                        pagessEntries.append(eachType)
                    }
                }
                self.books = booksEntries;
                self.pages = pagessEntries;
            })
        }
    }
    
    func selectAll() {
        selectedEntities.formUnion(Set(allEntities));
    }
    
    func deselectAll() {
        selectedEntities.removeAll();
    }
    
    func setSelected(_ item: FTTaggedEntity, selected: Bool) {
        if selected {
            self.selectedEntities.insert(item)
        }
        else {
            self.selectedEntities.remove(item)
        }
    }
}
