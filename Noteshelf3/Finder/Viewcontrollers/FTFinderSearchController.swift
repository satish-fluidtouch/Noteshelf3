//
//  FTFinderSearchController.swift
//  Noteshelf3
//
//  Created by Sameer on 14/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

enum FTSuggestionType: String, Codable {
    case text
    case tag
    
    func image() -> String {
        var name = "tag"
        if self == .text {
            name = "doc.text.magnifyingglass"
        }
        return name
    }
}

protocol FTFinderSearchDelegate: AnyObject {
    func refreshSearchPagesUI()
}

class  FTFinderSearchController: UIViewController, FTFinderTabBarProtocol, FTFinderSearchDelegate {
    var selectedTab: FTFinderSelectedTab = .search
    private var filteredTags = [FTTagModel]();
    private var recentsList = [String]();
    var isSearching = false
    private(set) var searchInputInfo = FTSearchInputInfo(textKey: "", tags: [])
    var searchBar: UISearchBar? {
        return self.searchController?.searchBar
    }
    
    func didCloseNotebook() {
        if self.searchController?.isActive ?? false {
            self.searchController?.isActive = false;
        }
    }
    
    @IBOutlet weak var finderContainerView: UIView!
    @IBOutlet weak var recentsTableView: UITableView!
    private var resultsList : [String] = [String]()
    private weak var seperatorView: UIView?
    var suggestionItems = [FTSuggestedItem]()
    
    private weak var searchController: UISearchController?
    private weak var finderController : FTFinderViewController?
    private weak var delegate: FTFinderTabBarController?
    private weak var document:FTThumbnailableCollection?;
    
    var searchOptions: FTFinderSearchOptions!
    private weak var expandButton: UIButton?
    private weak var editButton: UIButton?
    private weak var primaryButton: UIButton?

    @IBOutlet weak var seperatorViewTopConstraint: NSLayoutConstraint!

    let activityIndicator = UIActivityIndicatorView(style: .medium)
    var hideSuggestions: Bool = false
    private(set) var searchInputInfo = FTSearchInputInfo(textKey: "", tags: [])
    override func viewWillLayoutSubviews() {
           super.viewWillLayoutSubviews()
    }
    private var allTags = [FTTagModel]();
    
    var screenMode: FTFinderScreenMode {
        return self.delegate?.currentScreenMode() ?? .normal
    }
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    func didChangeState(to screenState: FTFinderScreenState) {
    }
    
    func configureData(forDocument document: FTThumbnailableCollection,
                       exportInfo: FTExportTarget?,
                       delegate: FTFinderTabBarController?, searchOptions: FTFinderSearchOptions) {
        self.delegate = delegate
        self.document = document
        self.searchOptions = searchOptions
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if !targetEnvironment(macCatalyst)
        self.configureNavigation(hideBackButton: true, title: "Search".localized)
#endif
        configureEditButton()
        loadTags()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if screenMode == .fullScreen {
            seperatorView?.removeFromSuperview()
            seperatorView = nil
            leadingConstraint.constant = 44
            trailingConstraint.constant = 44
        } else if screenMode == .normal {
            addSeperatorView()
            leadingConstraint.constant = 0
            trailingConstraint.constant = 0
        }
        self.view.updateConstraintsIfNeeded()
        finderController?.configureForSearchTab()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
#if !targetEnvironment(macCatalyst)
        updateNavBarMargins()
#endif
    }
    
    override func viewDidLoad() {
        let searchVC = UISearchController(searchResultsController: nil)
        self.searchController = searchVC;
        navigationItem.searchController = searchVC
        initializeSearchBar()
//        self.searchOptions.onFinding = { [weak self] in
//            self?.finderController?.updateBackgroundViewForSearch()
//            self?.updateFilterAndCreateSnapShot();
//        }
//        self.searchOptions.onCompletion = { [weak self] in
//            self?.finderController?.updateBackgroundViewForSearch()
//            self?.updateFilterAndCreateSnapShot();
//            self?.finderController?.showSearchIndicator(false)
//        }
        recentsTableView.register(FTRecentSearchCell.self, forCellReuseIdentifier: kRecentSearchCell)
        if let doc = self.document as? FTNoteshelfDocument {
            FTFilterRecentsStorage.shared.documentUUID = doc.documentUUID
        }
        recentsTableView.sectionHeaderTopPadding = 0
        if let pages = self.searchOptions.searchPages, pages.count > 0 {
            isSearching = true
            updateFilterAndCreateSnapShot()
            self.searchBar?.searchTextField.text = self.searchOptions.searchedKeyword
            self.hideSuggestions = true
        }
        updateSubViews(isSearching: isSearching)
        finderController?.searchDelegate = self
        initializeActivityIndicator()
    }
    
    private func reloadData() {
        self.finderController?.updateBackgroundViewForSearch()
        self.updateFilterAndCreateSnapShot();
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.tabBarController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.tabBarController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    private func initializeActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.isHidden = true
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
    }
    
    func addSeperatorView() {
        if seperatorView == nil {
            let sepView = UIView()
            seperatorView = sepView;
            seperatorView?.backgroundColor = UIColor.appColor(.black20)
            seperatorView?.translatesAutoresizingMaskIntoConstraints = false
            self.view.insertSubview(seperatorView!, at: 0)
            seperatorView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            seperatorView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            seperatorView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -2).isActive = true
            seperatorView?.heightAnchor.constraint(equalToConstant: 1).isActive = true
            seperatorView?.isHidden = true
        }
    }
    
    private func initializeSearchBar() {
        searchBar?.searchTextField.delegate = self
        searchController?.searchBar.delegate = self
        searchController?.searchResultsUpdater = self
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.preferredSearchBarPlacement = .stacked
    }
    
    internal func loadTags() {
        self.allTags.removeAll();
        filteredTags.removeAll()
        self.document?.documentPages().forEach { (page) in
            page.tags().forEach({ [weak self] (tag) in
                if self?.allTags.contains(where: {$0.text == tag}) == false  {
                    self?.allTags.append(FTTagModel(text: tag, isSelected: false));
                }
            })
        };
        
        self.allTags.sort { (tag1, tag2) -> Bool in
            (tag1.text.compare(tag2.text, options: [String.CompareOptions.caseInsensitive,String.CompareOptions.numeric], range: nil, locale: nil) == ComparisonResult.orderedAscending) ? true : false
        }
        filteredTags = allTags
    }
    
    func refreshSearchPagesUI() {
        if var searchResultPages = searchOptions.searchPages, let filteredPages = finderController?.filteredPages {
            searchResultPages = searchResultPages.filter({ searchResultPage in
                filteredPages.contains { documentPage in
                    documentPage.uuid == searchResultPage.uuid
                }
            })
            let searchPageTags = searchResultPages.compactMap {$0.tags}
            let duplicatePages = filteredPages.filter { firstObject in
                searchResultPages.contains { secondObject in
                    firstObject.tags() == secondObject.tags()
                }
            }
            finderController?.searchResultPages = searchResultPages
        }
        finderController?.updateFilterAndCreateSnapShot()
    }
    
    private func updateFilterAndCreateSnapShot() {
        if let searchPages = searchOptions.searchPages {
            finderController?.searchResultPages = searchPages
            finderController?.updateFilterAndCreateSnapShot()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let finderController = segue.destination as? FTFinderViewController, let doc = self.document {
            self.finderController = finderController
            finderController.selectedTab = .search
            finderController.configureData(forDocument: doc, exportInfo: nil, delegate: self.delegate, searchOptions: searchOptions)
        }
    }
    
    class func viewController(forDocument doc: FTThumbnailableCollection,
                                              delegate: FTFinderTabBarController?,
                                              searchOptions: FTFinderSearchOptions!) -> FTFinderSearchController  {
        let searchController =  FTFinderSearchController.instantiate(fromStoryboard: .finder)
        searchController.delegate = delegate
        searchController.document = doc
        searchController.searchOptions = searchOptions
        return  searchController
    }
    
#if !targetEnvironment(macCatalyst)
    private func configureNavigation(hideBackButton: Bool = false, title: String, preferLargeTitle: Bool = true) {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationItem.title = ""
        var insetsToAdd = UIEdgeInsets.zero
        if screenMode == .normal {
            setUpNormalBarButtons()
            insetsToAdd = UIEdgeInsets(top: 13, left: 0, bottom: 0, right: 0)
        } else if screenMode == .fullScreen {
            setUpBarButtons()
            insetsToAdd = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        }
        if self.delegate?._isRegularClass() ?? false {
            self.navigationController?.additionalSafeAreaInsets = insetsToAdd
        }
        self.navigationItem.title = title
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20)]
        let fontSize : CGFloat = (screenMode == .normal) ? 28 : 36
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: fontSize)]
        self.navigationController?.navigationBar.prefersLargeTitles = preferLargeTitle
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
    }
    
    private func updateNavBarMargins() {
        let inset: CGFloat = (screenMode == .fullScreen) ? 44 : 16
        self.navigationController?.navigationBar.layoutMargins.left = inset
        self.navigationController?.navigationBar.layoutMargins.right = inset
    }
    
    private func setUpNormalBarButtons() {
        let button = UIButton()
        expandButton = button
        let image = UIImage.image(for: "chevron.backward.2", font: UIFont.appFont(for: .semibold, with: 14))
        var config = UIButton.Configuration.plain()
        config.image = image
        config.contentInsets = .zero
        button.configuration = config
        button.tintColor = UIColor.appColor(.accent)
        button.addTarget(self, action: #selector(expandButtonTapped(_ :)), for: .touchUpInside)
        
        let editButton = UIButton()
        self.editButton = editButton
        let _image = UIImage.image(for: "ellipsis.circle", font: UIFont.appFont(for: .semibold, with: 15))
        var _config = UIButton.Configuration.plain()
        _config.image = _image
        _config.contentInsets = .zero
        editButton.configuration = _config
        editButton.setImage(_image, for: .normal)
        editButton.tintColor = UIColor.appColor(.accent)
        
        let stackView = UIStackView(arrangedSubviews: [editButton, button])
        stackView.spacing = 20
        let rightBarButton = UIBarButtonItem(customView: stackView)
        
        let primaryButton = UIButton()
        self.primaryButton = primaryButton
        primaryButton.tintColor = UIColor.appColor(.accent)
        var primaryButtonConfiguration = UIButton.Configuration.plain()
        primaryButtonConfiguration.image = UIImage(named: "primaryButton")
        primaryButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -20, bottom: 0, trailing: 0)
        primaryButton.configuration = primaryButtonConfiguration
        self.primaryButton?.addTarget(self, action: #selector(primaryButtonTapped(_ :)), for: .touchUpInside)

        let leftBarButton = UIBarButtonItem(customView: primaryButton)
        if self.delegate?._isRegularClass() ?? false {
             self.navigationItem.rightBarButtonItems = [rightBarButton]
            if screenMode == .normal {
                self.navigationItem.leftBarButtonItem = leftBarButton
            }
         } else {
             self.navigationItem.rightBarButtonItems = []
         }
    }
    
    @objc func collpaseButtonAction(_ sender : UIButton) {
        self.delegate?.shouldStartWithFullScreen(false)
        self.delegate?.didTapOnExpandButton()
    }
    
    @objc func closeButtonAction(_ sender : UIButton) {
        self.delegate?.didTapOnCloseButton()
    }
    
    func screenModeDidChange() {
        if screenMode == .normal {
            setUpNormalBarButtons()
        }
    }
    
    private func setUpBarButtons() {
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17), NSAttributedString.Key.foregroundColor: UIColor.appColor(.accent)]
        let collapseBarButton = UIBarButtonItem(image: UIImage.image(for: "arrow.down.right.and.arrow.up.left", font: UIFont.appFont(for: .semibold, with: 14)), style: .plain, target: self, action: #selector(collpaseButtonAction(_ :)))
        let closeBarButton = UIBarButtonItem(title: NSLocalizedString("Close", comment: "Close"), style: .plain, target: self, action: #selector(closeButtonAction(_ :)))
        closeBarButton.setTitleTextAttributes(attributes, for: .normal)
        if self.delegate?._isRegularClass() ?? false {
            let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            spacer.width = 14
            self.navigationItem.rightBarButtonItems = [closeBarButton, spacer, collapseBarButton]
            navigationItem.leftBarButtonItems = []
        } else {
             self.navigationItem.rightBarButtonItems = []
         }
    }
    
    @objc func expandButtonTapped(_ sender : UIButton) {
        self.delegate?.didTapOnFinderCloseButton()
    }
    
    @objc func primaryButtonTapped(_ sender : UIButton) {
        self.delegate?.didTapOnPrimaryButton()
    }
#else
    func screenModeDidChange() {
        
    }
#endif
    
    private  func updateSubViews(isSearching: Bool) {
        finderContainerView.isHidden = !isSearching
        recentsTableView.isHidden = isSearching
    }
    
    private func configureEditButton() {
        let moreOptions: [FTEditOption] = [.expand]
        var actions = [UIAction]()
        moreOptions.forEach { eachType in
            let action = eachType.actionElment {[weak self] action in
                self?.didTapEditOption(identifier: action.identifier.rawValue)
            }
            actions.append(action)
        }
        let menu = UIMenu(children: actions)
        editButton?.menu = menu
        editButton?.showsMenuAsPrimaryAction = true
    }
    
   private func didTapEditOption(identifier: String) {
        let option = FTEditOption(rawValue: identifier)
        switch option {
        case .edit:
            break
        case .expand:
            self.delegate?.didTapOnExpandButton()
        case .none:
            debugPrint("None")
        }
    }
    
    private func shouldSwapSubviews() -> Bool {
        let recentsIndex = view.subviews.firstIndex(of: recentsTableView)
        var shouldSwapSubViews = false
        if self.isSearching {
            shouldSwapSubViews = (recentsIndex == 0) ? true : false
        } else {
            shouldSwapSubViews = (recentsIndex == 0) ? false : true
        }
        return shouldSwapSubViews
    }
}

extension FTFinderSearchController {
    @objc func initiateSearch() {
        let tags = searchOptions.selectedTags.map { eachModel in
            return eachModel.text
        }
        if searchInputInfo.textKey != searchOptions.searchedKeyword || searchInputInfo.tags != tags {
            isSearching = true
            self.finderController?.showSearchIndicator(true)
            self.document?.startRecognitionIfNeeded();
            finderController?.configureForSearchTab()
            finderController?.isSearching = true
            searchInputInfo.tags = tags
            finderController?.filterOptionsController(didChangeSearchText: searchInputInfo.textKey, onFinding: { [weak self] in
                self?.reloadData();
            }, onCompletion: { [weak self] in
                self?.reloadData()
                self?.finderController?.showSearchIndicator(false)
            })
            constructRecentItems()
            updateSubViews(isSearching: true)
        }
    }
    
    private func constructRecentItems() {
        let tags = self.searchOptions.selectedTags
        var items = [FTRecentSearchedItem]()
        tags.forEach { eachTag in
            let item =  FTRecentSearchedItem(type: .tag, name: eachTag.text)
            items.append(item)
        }
        if !self.searchInputInfo.textKey.isEmpty {
            let recentTextItem = FTRecentSearchedItem(type: .text, name: searchInputInfo.textKey)
            items.append(recentTextItem)
        }
        FTFilterRecentsStorage.shared.addNewSearchItem(items)
    }
    
    func constructSelectedTags() {
        guard let searchVC = searchController else {
            return;
        }
        let tokens = searchVC.searchBar.searchTextField.tokens
        var currentTags = [FTTagModel]()
        tokens.forEach { eachToken in
             if let item = eachToken.representedObject as? FTSuggestedItem, let tag = item.tag {
                 tag.isSelected = true
                 currentTags.append(tag)
             }
         }
         self.searchOptions.selectedTags.removeAll()
         self.searchOptions.selectedTags = currentTags
    }
}

extension FTFinderSearchController : FTFinderHeaderDelegate {
    func didTapClearButton() {
        recentsList.removeAll()
        FTFilterRecentsStorage.shared.clear()
        finderController?.createSnapShot()
    }
    
    func didTapOnSegmentControl(_segmentControl: FTFinderSegmentControl) {
        
    }
}

extension FTFinderSearchController : UISearchTextFieldDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let searchVC = searchController else {
            return;
        }
        let key = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        let tokens = searchVC.searchBar.searchTextField.tokens
        let tags = self.searchOptions.selectedTags
        if tokens.count != tags.count {
            var currentTags = [FTTagModel]()
            tokens.forEach { eachToken in
                if let item = eachToken.representedObject as? FTSuggestedItem, let tag = item.tag {
                    currentTags.append(tag)
                }
            }
            self.searchOptions.selectedTags.removeAll()
            self.searchOptions.selectedTags = currentTags
        }
    #if !targetEnvironment(macCatalyst)
        if !key.isEmpty {
            if !hideSuggestions {
                populateSearchSuggestion(for: key)
            }
        } else {
            searchController?.searchSuggestions = []
        }
    #endif
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    #if targetEnvironment(macCatalyst)
        NotificationCenter.default.post(name: .shouldResignTextfieldNotification, object: nil)
    #endif
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.hideSuggestions = false
        expandButton?.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        expandButton?.isHidden = false
    }

    func updateSearchResults(for searchController: UISearchController, selecting searchSuggestion: UISearchSuggestion) {
        if let suggestion = searchSuggestion.representedObject as? FTSuggestedItem {
            didTapOnSuggestion(suggestion)
        }
    }
    
    private func didTapOnSuggestion(_ suggestionItem: FTSuggestedItem) {
        if suggestionItem.type == .tag {
            let textField = searchController?.searchBar.searchTextField
            let token = searchToken(for: suggestionItem)
            textField?.text = ""
            textField?.insertToken(token, at:  (textField?.tokens.count ?? 0))
        }
        if suggestionItem.type == .tag {
            constructSelectedTags()
            searchInputInfo.textKey = ""
        } else {
            searchInputInfo.textKey = searchController?.searchBar.searchTextField.text ?? ""
        }
        initiateSearch()
    }
    
    internal func searchToken(for suggestionItem: FTSuggestedItem) -> UISearchToken {
         let tokenColor = UIColor.white
        let image = UIImage(systemName: suggestionItem.type.image())?.withTintColor(tokenColor, renderingMode: .alwaysOriginal)
        let string = suggestionItem.suggestion.string
        let searchToken = UISearchToken(icon: image, text: string)
        searchToken.representedObject = suggestionItem
        return searchToken
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let text = textField.text ?? ""
        if !text.isEmpty {
            searchInputInfo.textKey = text
            initiateSearch()
        }  else if searchOptions.selectedTags.count > 0 {
            searchInputInfo.textKey = ""
            initiateSearch()
        }
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        perfromSearchCancel()
    }
    
    internal func perfromSearchCancel() {
        self.isSearching = false
        updateSubViews(isSearching: self.isSearching)
        recentsTableView.reloadData()
        recentsTableView.isHidden = false
        self.delegate?.cancelFinderSearchOperation()
        self.searchInputInfo = FTSearchInputInfo(textKey: "", tags: [])
    }

    private func populateSearchSuggestion(for query: String) {
        self.buildSuggestions(for: query)
        var items = [UISearchSuggestionItem]()
        suggestionItems.forEach { eachSuggestion in
            let item = suggestionItem(with: eachSuggestion)
            items.append(item)
        }
        searchController?.searchSuggestions = items
    }
    
    private func buildSuggestions(for query: String) {
        var items = [FTSuggestedItem]()
        var filteredTags = [FTTagModel]()
//        if query.count >= 3 {
            filteredTags = self.allTags.filter({
                $0.text.lowercased().hasPrefix(query.lowercased()) == true
            })
//        }
        let containsQuery = "finder.search.contains".localized + " \"\(query)\""
        let textItem = FTSuggestedItem(tag: nil, type: .text, suggestion: self.mutableString(for: containsQuery, type: .text, query: query))
        items.append(textItem)
        filteredTags.forEach { eachTag in
            let suggestionItem = FTSuggestedItem(tag: eachTag, type: .tag, suggestion: self.mutableString(for: eachTag.text, type: .tag, query: query))
            items.append(suggestionItem)
        }
        suggestionItems.removeAll()
        suggestionItems = items
    }
    
    private func mutableString(for string: String,  type: FTSuggestionType, query: String) -> NSMutableAttributedString {
        let mutableString = NSMutableAttributedString(string: string)
        mutableString.addAttribute(.foregroundColor, value: UIColor.label.withAlphaComponent(0.5), range: NSRange(location: 0, length: mutableString.length))
        var range = (mutableString.string.lowercased() as NSString).range(of: query.lowercased())
        if !query.isEmpty, type == .text, let _range = mutableString.rangesOfOccurance(of: "\"")?.first as? NSRange {
            range = NSRange(location: _range.location + 1, length: query.count )
        }
        mutableString.addAttribute(.foregroundColor, value: UIColor.label, range:  range)
        return mutableString
    }
    
    func suggestionItem(with item: FTSuggestedItem)  -> UISearchSuggestionItem {
        let image = UIImage(systemName: item.type.image())
        let suggestionItem = UISearchSuggestionItem(localizedAttributedSuggestion: item.suggestion, localizedDescription: item.suggestion.string, iconImage: image)
        suggestionItem.representedObject = item
        return suggestionItem
    }
}

struct FTSuggestedItem {
    var tag: FTTagModel?
    var type: FTSuggestionType = .tag
    var suggestion: NSMutableAttributedString
    
    init(tag: FTTagModel?, type: FTSuggestionType, suggestion: NSMutableAttributedString) {
        self.tag = tag
        self.type = type
        self.suggestion = suggestion
    }
}

extension FTFinderSearchController : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isDragging {
            return
        }
        self.hideBottomDivider(false)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.hideBottomDivider(true)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.hideBottomDivider(true)
    }
    
    private func hideBottomDivider(_ value: Bool) {
        if screenMode == .normal {
            seperatorView?.isHidden = value
        }
    }
}
