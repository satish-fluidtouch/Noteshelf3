//
//  FTGlobalSearchController.swift
//  Noteshelf3
//
//  Created by Narayana on 12/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon
import FTDocumentFramework
import Reachability
import Combine

protocol FTGlobalSearchDelegate: NSObjectProtocol {
    func willExitFromSearch(_ controller: FTGlobalSearchController)
    func didExitFromSearch(_ controller: FTGlobalSearchController)
    func openNotebook(info: FTDocumentOpenInfo)
    func didSelectCategory(category: FTShelfItemCollection)
    func didSelectGroup(groupItem: FTGroupItemProtocol)
    func performContextMenuOperation(for item: FTDiskItemProtocol,
                                     pageIndex: Int?,
                                     type: FTShelfItemContexualOption)
    func performContextMenuPageShare(for page: FTPageProtocol, shelfItem: FTShelfItemProtocol)
    func performContextualMenuPin(for shelfItem: FTShelfItemProtocol, isToPin: Bool)
    func selectSidebarWithCollection(_ collection: FTShelfItemCollection)
}

class FTSearchInputInfo: NSObject {
    var textKey: String
    var tags: [String]

    init(textKey: String, tags: [String]) {
        self.textKey = textKey
        self.tags = tags
    }
}

class FTGlobalSearchController: UIViewController {
    @IBOutlet private weak var searchStatusLabel: UILabel?
    @IBOutlet private weak var countInfoLabel: UILabel?

    @IBOutlet private weak var segmentControl: UISegmentedControl!

    // **** Members declared 'internal' here are intened to to use only inside class extensions
    // and not for outside purpose ****
    @IBOutlet internal weak var recentsTableView: UITableView!
    @IBOutlet internal weak var collectionView: UICollectionView!
    @IBOutlet internal weak var segmentInfoStackView: UIStackView!
    @IBOutlet weak var premiumStackView: UIView!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var upgradeNow: UIButton!
    @IBOutlet weak var premiumStackTopConstraint: NSLayoutConstraint!
    internal var progressView: RPCircularProgress?

    internal var allTags = [FTTagModel]()
    private(set) var searchInputInfo = FTSearchInputInfo(textKey: "", tags: [])

    internal var isRecentSelected: Bool = false
    internal var recentSearchList: [[FTRecentSearchedItem]] = []
    internal var searchController = FTUISearchController()

    weak var delegate: FTGlobalSearchDelegate?
    weak var shelfItemCollection: FTShelfItemCollection?

    private var selectedIndexPath : IndexPath?
    private var searchHelper: FTGlobalSearchProvider?
    private var selectedGridItem: FTSearchResultProtocol?
    private var searchedSections = [FTSearchSectionProtocol]()
    private var currentSize = CGSize.zero
    private let alignmentOffset: CGFloat = 550.0
    private var premiumCancellableEvent: AnyCancellable?;

#if targetEnvironment(macCatalyst)
    // This is used exclusively for updating search text when book is closed
    private var toUpdateSearchText = false
#endif

    deinit{
        self.premiumCancellableEvent?.cancel();
        self.premiumCancellableEvent = nil;
    }

    var navTitle: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        FTSearchSuggestionHelper.shared.fetchTags(completion: { allTags in
            self.allTags = allTags
       })
#if !targetEnvironment(macCatalyst)
        self.configureSearchControllerIfNeeded()
#endif
        self.configureSegmentControl()
        self.configureTableView()
        self.searchHelper = FTGlobalSearchProvider.init(with: [FTGlobalSearchType.titles, FTGlobalSearchType.content, FTGlobalSearchType.tags])
        (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = false
        let ftNoResultsVc = FTNoResultsViewHostingController(imageName: "emptySearch", title: "NoResults".localized, description: "search.tryNewSearch".localized)
        self.collectionView.backgroundView = ftNoResultsVc.view
        self.collectionView.backgroundView?.isHidden = true

        self.collectionView?.register(UINib(nibName: "FTSearchResultContentHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FTSearchResultContentHeader")
#if !targetEnvironment(macCatalyst)
        runInMainThread(0.1) {
            self.searchController.bringSearchBarResponder()
            self.configureProgressView()
        }
#endif

        premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremium in
            if isPremium {
                self?.premiumView.isHidden = true
                self?.premiumStackTopConstraint.constant = 0
            } else {
                self?.premiumView.isHidden = false
                self?.premiumStackTopConstraint.constant = 22
                self?.premiumStackView.layer.cornerRadius = 12.0
                self?.upgradeNow.layer.cornerRadius = 8.0
            }
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent);
        if nil == parent,self.searchController.isActive {
            self.searchController.isActive = false;
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let shelfItemCollection {
            self.delegate?.selectSidebarWithCollection(shelfItemCollection)
        }
#if targetEnvironment(macCatalyst)
        self.toUpdateSearchText = presentedViewController is FTNoteBookSplitViewController
#endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if targetEnvironment(macCatalyst)
        if let toolbar = self.view.toolbar as? FTShelfToolbar, toUpdateSearchText {
            toolbar.updateSearchText(self.searchInputInfo.textKey)
        }
#endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize != self.currentSize) {
            self.currentSize = currentFrameSize
            if self.currentSize.width > alignmentOffset {
                self.segmentInfoStackView.axis = .horizontal
                self.segmentInfoStackView.distribution = .fill
                self.segmentInfoStackView.alignment = .top
                self.countInfoLabel?.textAlignment = .left
            } else {
                self.segmentInfoStackView.axis = .vertical
                self.segmentInfoStackView.distribution = .fill
                self.segmentInfoStackView.alignment = .center
                self.countInfoLabel?.textAlignment = .center
            }
            self.segmentInfoStackView.layoutIfNeeded()
            self.collectionView.layoutIfNeeded()
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }

    @IBAction func segmentValueChanged(_ sender: Any) {
        self.cancelSearch()
        self.searchInputInfo.tags = FTSearchSuggestionHelper.shared.fetchCurrentSelectedTagsText(using: searchController.searchTokens)
        self.searchForNotebooks(with: searchInputInfo)
    }

    @IBAction func upgradeNowAction(_ sender: Any) {
        let reachability: Reachability = Reachability.forInternetConnection()
        let status: NetworkStatus = reachability.currentReachabilityStatus();
        if status == NetworkStatus.NotReachable {
            UIAlertController.showAlert(withTitle: "MakeSureYouAreConnected".localized, message: "", from: self, withCompletionHandler: nil)
            return
        } else {
            FTIAPurchaseHelper.shared.presentIAPIfNeeded(on: self);
        }
    }

    func cancelSearch() {
        runInMainThread {
            self.progressView?.isHidden = true
            self.updateSearchStatus()
            self.hideSegmentControlIfNeeded(toHide: true)
            self.searchedSections.removeAll()
            self.collectionView?.reloadData()
        }
        self.searchHelper?.cancelSearching()
    }

}

// MARK:  **** functions declared 'internal' here are intened to to use only inside this class extensions
// and not for outside purpose ****
extension FTGlobalSearchController {
    internal func searchForNotebooks(with info: FTSearchInputInfo) {
        self.cancelSearch()

        runInMainThread {
            var sectionIndexSet = IndexSet()
            for i in 0 ..< self.searchedSections.count {
                sectionIndexSet.insert(i)
            }
            self.hideSegmentControlIfNeeded(toHide: false)
            self.searchedSections.removeAll()
            self.collectionView?.deleteSections(sectionIndexSet)
            self.progressView?.isHidden = false
            self.progressView?.updateProgress(0.0, animated: false, initialDelay: 0, duration: 0, completion: nil)
            self.updateSearchStatus()
        }

        FTNotebookRecognitionHelper.activateMyScript("Global_Search")
        var shelfcatgories: [FTShelfItemCollection] = []
        if self.segmentControl.selectedSegmentIndex == 1, let collection = self.shelfItemCollection {
            shelfcatgories.append(collection)
        }
        let reqSearchKey = info.textKey.trimmingCharacters(in: .whitespaces)
        self.searchHelper?.fetchSearchResults(with: reqSearchKey, tags: info.tags, shelfCategories: shelfcatgories, onSectionFinding: {[weak self] (items) in
            guard let self = self, !items.isEmpty else {
                return
            }
            runInMainThread {
                items.forEach { itemSection in
                    if !self.searchedSections.contains(where: { section in
                        return itemSection.uuid == section.uuid
                    }) {
                        var sectionIndexSet = IndexSet()
                        for i in 0 ..< items.count {
                            sectionIndexSet.insert(self.searchedSections.count + i)
                        }
                        self.searchedSections.append(contentsOf: items)
                        self.collectionView?.insertSections(sectionIndexSet)
                        self.updateCountInfoLabel()
                    } else {
                        if let index = self.searchedSections.firstIndex(where: { section in
                            section.uuid == itemSection.uuid
                        }) {
                            let indexPath = IndexPath(item: 0, section: index)
                            if self.collectionView.indexPathsForVisibleItems.contains(where: { visibleIndexPath in
                                visibleIndexPath == indexPath
                            }) {
                                if let cell = self.collectionView.cellForItem(at: indexPath) as? FTBaseResultSectionCell {
                                    cell.updateContentSection(itemSection)
                                }
                                if let header = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath) as? FTSearchResultHeader {
                                    header.updatePageCount(itemSection)
                                }
                            }
                            self.updateCountInfoLabel()
                        }
                    }
                }
            }
        }, onCompletion: { [weak self] (_) in
            runInMainThread {
                if let `self` = self {
                    self.progressView?.isHidden = true
                    self.updateSearchStatus()
                    self.updateCountInfoLabel()
                }
            }
        })
        self.searchHelper?.onProgressUpdate = {[weak self] (progress) in
            runInMainThread {
                self?.progressView?.updateProgress(progress, animated: false, initialDelay: 0, duration: 0, completion: nil);
            }
        }
    }
}

private extension FTGlobalSearchController {
    private func configureSearchControllerIfNeeded() {
        self.searchController.configureSearch(with: self)
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.preferredSearchBarPlacement = .stacked
        self.navigationItem.title = "Search".localized
    }

    private func configureProgressView() {
        self.progressView = RPCircularProgress()
        self.progressView?.frame.size = CGSize(width: 25.0, height: 25.0)
        self.progressView?.translatesAutoresizingMaskIntoConstraints = false
        self.progressView?.trackTintColor = UIColor(hexString: "76787C")
        self.progressView?.progressTintColor = .white
        self.progressView?.innerTintColor = .clear
        self.progressView?.roundedCorners = true
        self.progressView?.clockwiseProgress = true
        self.progressView?.thicknessRatio = 0.25
        self.searchController.searchBar.addSubview(progressView!)
        self.progressView?.translatesAutoresizingMaskIntoConstraints = false
        self.progressView?.trailingAnchor.constraint(equalTo: self.searchController.searchBar.searchTextField.trailingAnchor, constant: -40).isActive = true
        self.progressView?.centerYAnchor.constraint(equalTo: self.searchController.searchBar.searchTextField.centerYAnchor, constant: 0.0).isActive = true
        self.progressView?.widthAnchor.constraint(equalToConstant: 25.0).isActive = true
        self.progressView?.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        self.progressView?.isHidden = true
    }

    private func configureTableView() {
        self.recentsTableView.register(FTRecentSearchCell.self, forCellReuseIdentifier: kRecentSearchCell)
        self.recentsTableView.sectionHeaderTopPadding = 0
        self.updateRecentSearchList()
        self.recentsTableView.fillerRowHeight = 0.0
        self.recentsTableView.isScrollEnabled = self.recentsTableView.contentSize.height > self.recentsTableView.frame.size.height
        self.recentsTableView.dataSource = self
        self.recentsTableView.delegate = self
#if !targetEnvironment(macCatalyst)
        self.updateUICondictionally(with: "")
#endif
    }

    private func configureSegmentControl() {
        let font = UIFont.appFont(for: .regular, with: 15)
        self.segmentControl.setTitleTextAttributes([NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: UIColor.label], for: .normal)
        self.segmentControl.setTitle(NSLocalizedString("AllNotes", comment: "All Notes"), forSegmentAt: 0)
        let segment2Title = "\"" + (self.shelfItemCollection?.displayTitle ?? "") + "\""
        self.segmentControl.setTitle(segment2Title, forSegmentAt: 1)
        self.segmentControl.selectedSegmentIndex = 0
        self.hideSegmentControlIfNeeded(toHide: true)
    }

    private func hideSegmentControlIfNeeded(toHide: Bool) {
        if let collection = self.shelfItemCollection, !collection.isAllNotesShelfItemCollection {
            self.segmentControl.isHidden = false
        }
        if toHide {
            self.segmentControl.isHidden = true
        }
    }

    private func updateSearchStatus() {
        self.collectionView.backgroundView?.isHidden = true
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.01

        if self.searchedSections.isEmpty {
            let countAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.label.withAlphaComponent(0.7), .font: UIFont.appFont(for: .regular, with: 13), NSAttributedString.Key.paragraphStyle: paragraphStyle]
            self.countInfoLabel?.attributedText = NSAttributedString(string: "", attributes: countAttrs)
        }

        let searchKeyAttrs: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.label, .font: UIFont.clearFaceFont(for: .medium, with: 28), NSAttributedString.Key.paragraphStyle : paragraphStyle]

        let searchTokens = self.searchController.searchTokens
        var searchedCompundStr = ""
        if searchTokens.isEmpty {
            searchedCompundStr = searchInputInfo.textKey
        } else {
            var searchedText = FTSearchSuggestionHelper.shared.fetchCurrentSelectedTagsText(using: searchController.searchTokens)
            if !searchInputInfo.textKey.isEmpty {
                searchedText.append(searchInputInfo.textKey)
            }
            for (index, tagText) in searchedText.enumerated() {
                if index == 0 {
                    searchedCompundStr.append(tagText)
                } else {
                    let framedText = (index == (searchedText.count - 1) ) ? " and " : ","
                    searchedCompundStr.append(framedText)
                    searchedCompundStr.append(tagText)
                }
            }
        }

        let leftQuoteMark = "\u{201C}"
        let rightQuoteMark = "\u{201D}"
        let quotedStr = leftQuoteMark + searchedCompundStr + rightQuoteMark
        let resultsForText = String(format: NSLocalizedString("ResultsFor", comment: "Results for"), quotedStr)
        let attributedString = NSMutableAttributedString(string: resultsForText,
                                                         attributes: searchKeyAttrs)
        let range = (resultsForText as NSString).range(of: quotedStr)
        attributedString.addAttributes(searchKeyAttrs, range: range)
        self.searchStatusLabel?.attributedText = attributedString
    }

    private func updateCountInfoLabel() {
        if self.searchedSections.isEmpty {
            self.countInfoLabel?.isHidden = true
            self.collectionView.backgroundView?.isHidden = false
        } else {
            self.countInfoLabel?.isHidden = false
            var totalCount = 0
            totalCount = self.searchedSections.reduce(0) { result, section in
                result + section.items.count
            }
            let countStr = String(format: "NItems".localized, totalCount)
            self.countInfoLabel?.text = countStr
        }
    }
}

//MARK:- UICollectionViewDataSource
extension FTGlobalSearchController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.searchedSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.init(width: collectionView.frame.width, height: 42)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionContent = self.searchedSections[indexPath.section]
        sectionContent.onStatusChange = {[weak self] (section,   isActive) in
            if isActive {
                if let index = self?.searchedSections.firstIndex(where: { (eachSection) -> Bool in
                    return eachSection.isEqual(section)
                }){
                    var sectionIndexSet = IndexSet()
                    sectionIndexSet.insert(index)
                    self?.collectionView?.reloadSections(sectionIndexSet)
                }
            }
        }
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }

        var cellIdentifier = "FTSearchResultTitlesHeader"
        if !self.view.isRegularClass() && sectionContent is FTSearchSectionContentProtocol {
            cellIdentifier = "FTSearchResultContentHeader"
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: cellIdentifier, for: indexPath)
        if let headerCell = header as? FTSearchResultTitlesHeader {
            headerCell.configureHeader(sectionContent, searchKey: searchInputInfo.textKey)
        }
        else if let headerCell = header as? FTSearchResultContentHeader {
            headerCell.configureHeader(sectionContent, searchKey: searchInputInfo.textKey)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let sectionContent = self.searchedSections[indexPath.section] as? FTSearchSectionContentProtocol {
            sectionContent.beginContentAccess()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if self.searchedSections.count > indexPath.section {
            if let sectionContent = self.searchedSections[indexPath.section] as? FTSearchSectionContentProtocol {
                sectionContent.endContentAccess()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = self.searchedSections[indexPath.section]
        var cellIdentifier: String = "FTCategoryResultSectionCell"
        if section.contentType == .book {
            cellIdentifier = "FTBookResultSectionCell"
        }
        else if section.contentType == .page {
            cellIdentifier = "FTPageResultSectionCell"
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let aCell = cell as? FTBaseResultSectionCell {
            aCell.contentSection = section
            aCell.delegate = self
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let sectionContent = self.searchedSections[indexPath.section] as? FTSearchSectionContentProtocol {
            sectionContent.beginContentAccess()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.searchedSections.count > indexPath.section {
            if let sectionContent = self.searchedSections[indexPath.section] as? FTSearchSectionContentProtocol {
                sectionContent.endContentAccess()
            }
        }
    }
}
//MARK:- UICollectionViewDelegateFlowLayout
extension FTGlobalSearchController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = self.searchedSections[indexPath.section]
        var height: CGFloat = 100.0 // just some default
        if section.contentType == .category {
            height = self.isRegularClass() ? GlobalSearchConstants.CategoryResultsCollectionViewHeight.regular :  GlobalSearchConstants.CategoryResultsCollectionViewHeight.compact
        } else if section.contentType == .book {
            height = self.isRegularClass() ? GlobalSearchConstants.BookResultsCollectionViewHeight.regular :  GlobalSearchConstants.BookResultsCollectionViewHeight.compact
        } else if section.contentType == .page {
            height = self.isRegularClass() ? GlobalSearchConstants.PageResultsCollectionViewHeight.regular :  GlobalSearchConstants.PageResultsCollectionViewHeight.compact
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension FTGlobalSearchController: FTSearchResultActionDelegate {
    func didSelectItem(_ gridItem: FTSearchResultProtocol) {
        self.parent?.view.endEditing(true)
        guard let section = gridItem.parentSection else {
            return
        }
        if section.contentType == .category {
            if let shelf = (gridItem as? FTSearchResultCategoryProtocol)?.shelfItemCollection {
                self.delegate?.didSelectCategory(category: shelf)
                return
            }
        }
        //*************************
        self.selectedGridItem = gridItem
        var selectedShelfItem: FTShelfItemProtocol?
        if section.contentType == .page {
            selectedShelfItem = section.sectionHeaderItem as? FTShelfItemProtocol
        }
        else if let resultItem = gridItem as? FTSearchResultBookProtocol {
            selectedShelfItem = resultItem.shelfItem
        }
        guard let shelfItem = selectedShelfItem else {
            return
        }
        //*************************

        if let groupItem = shelfItem as? FTGroupItemProtocol {
            self.delegate?.didSelectGroup(groupItem: groupItem)
            return
        }

        if(!FileManager().fileExists(atPath: shelfItem.URL.path)) {
            var shouldDisplayAlert: Bool = false
            if FTNSiCloudManager.shared().iCloudOn() == true {
                if (shelfItem.URL.isUbiquitousFileExists() == false) {
                    shouldDisplayAlert = true
                }
            }
            else{
                shouldDisplayAlert = true
            }
            if shouldDisplayAlert {
                DispatchQueue.main.async {
                    if let shelfController = self.parent {
                        UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("BookNotExistMessage", comment: ""), from: shelfController, withCompletionHandler: nil)
                    }
                }
                return
            }
        }

        FTDocumentValidator.openNoteshelfDocument(for: shelfItem,
                                                  pin: nil,
                                                  onViewController: self) {[weak self] (openedDocument, error,token) in
            //**************************************
            if let inError = error {
                if(inError.isConflictError) {
                    if let conflictedDocument = openedDocument, let item = shelfItem as? FTDocumentItemProtocol {
                        let documentConflictScreen = FTCloudDocumentConflictScreen.conflictViewControllerForDocument(conflictedDocument, documentItem:item)
                        self?.present(documentConflictScreen, animated: true, completion: nil);
                    }
                }
                else if(inError.isNotDownloadedError) {
                    if let documentItem = shelfItem as? FTDocumentItemProtocol {
                        if(!documentItem.isDownloaded) {
                            do {
                                try FileManager().startDownloadingUbiquitousItem(at: documentItem.URL);
                            }
                            catch let error as NSError {
                                FTLogError("Notebook download failed", attributes: error.userInfo);
                            }
                        }
                    }
                }
                return;
            }
            //**************************************
            guard let `self` = self, let notebookToOpen = openedDocument else {
                if let token = token, let doc = openedDocument {
                    FTNoteshelfDocumentManager.shared.closeDocument(document: doc,
                                                                    token: token,
                                                                    onCompletion: nil);
                }
                return
            }
            var selectedPageIndex = -1
            if let pageItem = gridItem as? FTSearchResultPageProtocol {
                selectedPageIndex = pageItem.searchingInfo?.pageIndex ?? 0
            }

            let docInfo = FTDocumentOpenInfo(document: notebookToOpen,
                                             shelfItem: shelfItem,
                                             index: selectedPageIndex);
            docInfo.documentOpenToken = token ?? FTDocumentOpenToken();
            //************************************** Only content matches will be populated in finder
            if section is FTSearchSectionContentProtocol {
                let documentSearchResults = FTDocumentSearchResults()
                documentSearchResults.searchedKeyword = self.searchHelper?.searchKey
                var searchIndices = [FTPageSearchingInfo]()
                for eachItem in section.items {
                    if let searchInfo = (eachItem as? FTSearchResultPageProtocol)?.searchingInfo {
                        searchIndices.append(searchInfo)
                    }
                }
                documentSearchResults.searchPageResults = searchIndices
                docInfo.documentSearchResults = documentSearchResults;
            }
            //**************************************
            if let sectionIndex = self.searchedSections.firstIndex(where: { $0.hash == section.hash}) {
                if let itemIndex = self.searchedSections[sectionIndex].items.firstIndex(where: { $0.hash == gridItem.hash}) {
                    if let cell = self.collectionView?.cellForItem(at: IndexPath(row: 0, section: sectionIndex)) as? FTBaseResultSectionCell {
                        let indexPath = IndexPath(row: itemIndex, section: 0)
                        docInfo.openAnimationInfo = cell.getAnimationInfo(for: indexPath)
                    }
                }
            }
            runInMainThread {
                self.delegate?.openNotebook(info: docInfo);
            }
        }
    }

    func performContextMenuOperation(for item: FTDiskItemProtocol,
                                     pageIndex: Int?,
                                     type: FTShelfItemContexualOption) {
        self.delegate?.performContextMenuOperation(for: item,
                                                   pageIndex: pageIndex,
                                                   type: type)
    }

    func performContextMenuPageShare(for page: FTPageProtocol, shelfItem: FTShelfItemProtocol) {
        self.delegate?.performContextMenuPageShare(for: page, shelfItem: shelfItem)
    }

    func performContextualMenuPin(for shelfItem: FTShelfItemProtocol, isToPin: Bool) {
        self.delegate?.performContextualMenuPin(for: shelfItem, isToPin: isToPin)
    }
}

//MARK:- Open/Close Animation
extension FTGlobalSearchController {
    func getSelectedItemAnimationInfo(withRespectToView targetView: UIView?) -> FTOpenAnimationInfo? {
        if let localCollectionView = self.collectionView, let gridItem = self.selectedGridItem, let parentSection = gridItem.parentSection {
            if let sectionIndex = self.searchedSections.firstIndex(where: { $0.hash == parentSection.hash}) {
                if let rowIndex = self.searchedSections[sectionIndex].items.firstIndex(where: { $0.hash == gridItem.hash}) {
                    let indexPath = IndexPath.init(row: 0, section: sectionIndex)
                    self.collectionView?.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.init(rawValue: 0), animated: false);
                    self.collectionView?.layoutSubviews()

                    if let cell = localCollectionView.cellForItem(at: indexPath) as? FTBaseResultSectionCell {
                        let itemIndexPath = IndexPath(row: rowIndex, section: 0)
                        cell.collectionView?.scrollToItem(at: itemIndexPath, at: UICollectionView.ScrollPosition.init(rawValue: 0), animated: false)
                        cell.collectionView?.layoutSubviews()

                        if let animateInfo = cell.getAnimationInfo(for: itemIndexPath), let rootView = targetView {
                            animateInfo.imageFrame = rootView.convert(animateInfo.imageFrame, from: localCollectionView) //Convert the frame with respect to split master view space occupied
                            animateInfo.imageFrame.origin.x -= (cell.collectionView?.contentOffset.x ?? 0)
                            return animateInfo
                        }
                    }
                }
            }
        }
        return nil
    }
}
