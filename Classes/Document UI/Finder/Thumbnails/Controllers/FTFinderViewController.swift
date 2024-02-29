//
//  FTFinderViewController.swift
//  Noteshelf
//
//  Created by Naidu on 31/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework
import AVFoundation
import MobileCoreServices
import FTCommon
import FTNewNotebook

extension Notification.Name {
    static let didChangeCurrentPageNotification = Notification.Name(rawValue: "didChangeCurrentPageNotification")
    static let validationFinderButtonNotification = Notification.Name(rawValue: "validationFinderButtonNotification")
    static let shouldReloadFinderNotification = Notification.Name(rawValue: "shouldReloadFinderNotification")
}

fileprivate typealias FinderDataSource = UICollectionViewDiffableDataSource<FTFinderSectionType, AnyHashable>
fileprivate typealias FinderSnapShot = NSDiffableDataSourceSnapshot<FTFinderSectionType, AnyHashable>

enum FTFinderSectionType: Int {
    case thumbnails
    case bookmark
    case outline

    func segmentName() -> String {
        var name = "thumbnails"
        switch self {
        case .thumbnails:
            name = "thumbnails"
        case .bookmark:
            name = "bookmark"
        case .outline:
            name = "outline"
        }
        return name
    }
}

protocol FTFinderTabBarProtocol: AnyObject {
    func didChangeState(to screenState: FTFinderScreenState)
    func configureData(forDocument document: FTThumbnailableCollection,
                       exportInfo: FTExportTarget?,
                       delegate: FTFinderTabBarController?,
                       searchOptions: FTFinderSearchOptions)
    var selectedTab: FTFinderSelectedTab {get set}
    func didGoToAudioRecordings(with annotation: FTAnnotation)
    func screenModeDidChange()
    func scrollToTop()
    func didCloseNotebook();
}

extension FTFinderTabBarProtocol {
    func didGoToAudioRecordings(with annotation: FTAnnotation) {}
    func scrollToTop() {}
    func didCloseNotebook() {}
}

class FTDragDropCollectionView : UICollectionView {
    //reference link: https://stackoverflow.com/questions/51553223/handling-multiple-uicollectionview-interactivemovements-crash-uidragsnapping

    override func cancelInteractiveMovement() {
        super.cancelInteractiveMovement()
        super.endInteractiveMovement() // ← will not perform the standard "end" animation
        // the moving cell was already reset by cancelInteractiveMovement
    }
}

class FTFinderViewController: UIViewController, FTFinderTabBarProtocol, FTFinderHeaderDelegate {
    func didTapClearButton() {

    }
    private var selectedTagItems = Dictionary<String, FTShelfTagsItem>();

    var outlinesViewController: FTOutlinesViewController?
    @IBOutlet weak var rotateButton: UIButton!
    private weak var addPageNotificationObserver: NSObjectProtocol?
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var compactEditButton: UIButton?
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var dividerView: UIView?
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var duplicateButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    override var shouldAvoidDismissOnSizeChange: Bool {
        return true;
    }

    @IBOutlet weak var stackviewTopConstraint: NSLayoutConstraint?
    fileprivate var dataSource : FinderDataSource! //Used for UI Diffable datasource
    fileprivate var snapShot = FinderSnapShot()
    var selectedTab: FTFinderSelectedTab = .thumnails
    private var comingFromMovePageScreen : Bool = false;
    @IBOutlet weak var collectionView: FTDragDropCollectionView!
    var mode = FTFinderPageState.none
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var optionsToolBar: UIView!
    @IBOutlet weak var segmentControl: FTFinderSegmentControl?
    @IBOutlet weak var optionsStackView: UIStackView!
    weak var delegate: FTFinderTabBarController?
    weak var pdfDelegate: FTPDFRenderViewController?
    private var currentSize = CGSize.zero
    var previousScrollOffSet: CGPoint?
    var screenMode: FTFinderScreenMode  {
        return self.delegate?.currentScreenMode() ?? .normal
    }
    var searchResultPages: [FTThumbnailable]?
    //Document
    var exportTarget: FTExportTarget?
    var sectionHeader: FTFinderCollectionViewHeader?
    weak var document:FTThumbnailableCollection?;
    fileprivate var selectAll = true;
    internal var selectedPages = NSMutableSet()
    var filteredPages = [FTThumbnailable]()
    internal var contextMenuActivePages = NSSet()
    private var editNavButton: UIButton?
    var selectedSegment = FTFinderSegment.pages
    //UI
    var cellSize: CGSize = CGSize(width: 236, height: 208)

    let bookMarkThumbSize: CGSize = CGSize(width: 52, height: 72)
    private let extraCellPadding : CGFloat = 30
    private let preferredWidth: CGFloat = 335;

    //**************************************

    //**************************************
    var editBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var headerView: UIView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet fileprivate weak var collapseButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet fileprivate weak var selectAllButton: UIButton!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var viewLoading: UIView!
    @IBOutlet weak var pagesShareButton: UIButton!
    @IBOutlet weak var activityIndicatorViewLoading: UIActivityIndicatorView!
    @IBOutlet weak var labelLoading: FTStyledLabel!
    private var originalIndexPath: IndexPath?
    var draggingIndexPath: IndexPath?
    private var draggingView: UIView?
    private var dragOffset: CGPoint!;

    var presentedForToolbarMode : FTDeskToolbarMode = .normal
    private var shouldMoveToCurrentPage = true;
    //**************************************
    weak var outlinesContainerView: UIView?
    @IBOutlet private var collectionViewTopConstraint: NSLayoutConstraint?
    @IBOutlet weak private var collectionViewConstraintToSuperview: NSLayoutConstraint!
    @IBOutlet weak private var collectionViewBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak private var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var segmentControlHeightConstraint: NSLayoutConstraint!
    private  var placeHolderVc: FTFinderNoResultsViewHostingController?
    @IBOutlet weak private var selectModeHeaderView: UIView!
    @IBOutlet weak private var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak private var headerLabel: UILabel!
    weak var searchDelegate: FTFinderSearchDelegate?
    var allTags = [FTTagModel]();
    //tags and recents
    var recentsList = [[FTRecentSearchedItem]]();
    var isSearching = false
    var sections = [FTFinderSectionType]()
    var isResizing = false;
    var selectedIndexPath: IndexPath?
    private(set) var updatedItem : [FTThumbnailable]?

    var isPreferredLanguageChosen: Bool {
        get{
            return UserDefaults.standard.bool(forKey: "isPreferredLanguageChosen")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "isPreferredLanguageChosen")
            UserDefaults.standard.synchronize()
        }
    }
    internal let landscapeHeightRatio: CGFloat = 152 / 210
    internal let potraitHeightRatio: CGFloat = 208 / 152
    internal let potraitWidthRatio: CGFloat = 152 / 210

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isSearching = false
    }

    deinit {
        self.outlinesViewController = nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self](_) in
            //            self?.segmentControlWidthConstraint?.constant = UIDevice.isLandscapeOrientation ? 245 : 205
        }, completion: { [weak self](_) in

        });
    }

    //MARK:- UIViewController
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        var isRegular = self.delegate?._isRegularClass() ?? self.isRegularClass()
        if let splitVc = self.splitViewController {
            isRegular = splitVc.isRegularClass()
        }
        if isRegular {
            if mode == .selectPages {
                self.cellSize = CGSize(width: 152, height: 204);
            }
        }
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    private func shouldShowNavBar(_ value: Bool) {
        self.navigationController?.navigationBar.isHidden = !value
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()
        self.setUpCollectionview()
        self.filteredPages.append(contentsOf: self.documentPages);
        updateSelectionTitle()
        if mode == .selectPages {
            self.view.backgroundColor = .appColor(.formSheetBgColor)
        } else {
            self.view.backgroundColor = .appColor(.finderBgColor)
        }
        //        self.segmentControlWidthConstraint?.constant = UIDevice.isLandscapeOrientation ? 245 : 203
        configureDiffableDataSource()
        updateFilterAndCreateSnapShot()
        configureMoreButton()
        configureEditButton()
        hideStandardNavBarAppearance()
        collectionView.backgroundView = _placeHolderVc().view
        collectionView.backgroundView?.isHidden = true
        updateHeaderUI()
        pagesShareButton.isHidden = true
        pagesShareButton.layer.cornerRadius = 10
        if self.mode == .selectPages {
            selectAllButton.setImage(UIImage(), for: .normal)
            selectAllButton.setImage(UIImage(), for: .selected)
            updateSelectAll()
        }
        self.updateContentInsets()
        segmentControl?.type = .image
        if self.mode == .selectPages {
            segmentControl?.segmentsCount = 2
            pagesShareButton.dropShadowWith(color: UIColor.appColor(.buttonShadow), offset:  CGSize(width: 0, height: 4), radius: 8)
        }
        segmentControl?.populateSegments()
        segmentControl?.selectedSegmentIndex = 0
    }

    private func updateContentInsets() {
        collectionView.contentInset = .zero
        if screenMode == .normal && selectedTab == .thumnails {
            collectionView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }

    private func hideStandardNavBarAppearance() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.backgroundColor = .clear
    }

    private func updateHeaderUI() {
        if self.mode == .none {
            selectModeHeaderView.isHidden = true
            headerView?.isHidden = false
            segmentControl?.isHidden = false
        } else if self.mode == .edit {
            segmentControl?.isHidden = true
            selectModeHeaderView.isHidden = false
            headerView?.isHidden = true
        } else if self.mode == .selectPages {
            headerView?.isHidden = true
            segmentControl?.isHidden = false
            selectModeHeaderView.isHidden = false
        }
    }

    public func configureData(forDocument document: FTThumbnailableCollection,
                              exportInfo: FTExportTarget?,
                              delegate: FTFinderTabBarController?, searchOptions: FTFinderSearchOptions) {
        self.document = document;
        self.exportTarget = exportInfo
        self.delegate = delegate;
    }

    func screenModeDidChange() {
        if screenMode == .normal {
            refreshSnapShot()
            updateHeaderView()
        }
        self.updateContentInsets()
    }

    private func configureNavigation(hideBackButton: Bool = false, title: String, preferLargeTitle: Bool = true) {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationItem.title = ""
        setUpBarButtons()
        updateNavBar(with: title)
        self.navigationController?.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font:  UIFont.clearFaceFont(for: .medium, with: 20)]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 36)]
        self.navigationController?.navigationBar.layoutMargins.left = 44
        self.navigationController?.navigationBar.prefersLargeTitles = preferLargeTitle
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.tabBarController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }

    override var prefersStatusBarHidden: Bool {
        return self.tabBarController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    private func updateNavBar(with title: String = "") {
        if self.mode == .edit {
            self.navigationItem.title = NSLocalizedString("Select", comment: "Select")
        } else {
            self.navigationItem.title = title
        }
    }

    private func setUpBarButtons() {
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17), NSAttributedString.Key.foregroundColor: UIColor.appColor(.accent)]
        let collapseBarButton = UIBarButtonItem(image: UIImage.image(for: "arrow.down.right.and.arrow.up.left", font: UIFont.appFont(for: .semibold, with: 14)), style: .plain, target: self, action: #selector(collapseButtonAction(_ :)))
        let editBarButton = UIBarButtonItem(image: UIImage.image(for: "checkmark.circle", font: UIFont.systemFont(ofSize: 14, weight: .medium)), style: .plain, target: self, action: #selector(editButtonAction(_ :)))
        let closeBarButton = UIBarButtonItem(title: NSLocalizedString("Close", comment: "Close"), style: .plain, target: self, action: #selector(closeButtonAction(_ :)))
        closeBarButton.setTitleTextAttributes(attributes, for: .normal)
        if self.delegate?._isRegularClass() ?? false {
            if self.mode == .edit {
                let selectAllButton = UIBarButtonItem(title: "SelectAll".localized, style: .plain, target: self, action: #selector(selectAllButtonAction(_ :)))
                selectAllButton.setTitleTextAttributes(attributes, for: .normal)
                navigationItem.leftBarButtonItem = selectAllButton
                let doneButton = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(doneButtonAction(_ :)))
                doneButton.setTitleTextAttributes(attributes, for: .normal)
                navigationItem.rightBarButtonItems = []
                navigationItem.rightBarButtonItem = doneButton
            } else {
                let spacer1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                spacer1.width = 10
                let spacer2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                spacer2.width = 14
                self.navigationItem.rightBarButtonItems = [closeBarButton, spacer2, collapseBarButton, spacer1, editBarButton]
                navigationItem.leftBarButtonItems = []
            }
        } else {
            self.navigationItem.rightBarButtonItems = []
        }
    }

    @objc func collapseButtonAction(_ sender : UIButton) {
        FTFinderEventTracker.trackFinderEvent(with: "finder_fullscreen_collapse_tap")
        self.delegate?.shouldStartWithFullScreen(false)
        self.delegate?.didTapOnExpandButton()
    }

    @objc func selectAllButtonAction(_ sender : UIButton) {
        self.selectAllClicked()
    }

    @objc func doneButtonAction(_ sender : UIButton) {
        self.mode = .none
        updateEditMode()
    }

    @objc func editButtonAction(_ sender : UIButton) {
        FTFinderEventTracker.trackFinderEvent(with: "finder_fullscreen_select_tap")
        self.mode = .edit
        updateEditMode()
    }

    private func updateEditMode() {
        if self.mode == .none {
            self.deselectAll()
        }
        let isEditMode = (self.mode == .edit)
        hideTabBar(isEditMode)
        optionsToolBar.isHidden = !isEditMode
        self.disableEditOptions()
        self.refreshSnapShot()
        setUpBarButtons()
        let title = (mode == .none) ? NSLocalizedString("Pages", comment: "Pages") : ""
        updateNavBar(with: title)
    }

    @objc func closeButtonAction(_ sender : UIButton) {
        FTFinderEventTracker.trackFinderEvent(with: "finder_fullscreen_close_tap")
        self.delegate?.didTapOnCloseButton()
    }

    private func configureDiffableDataSource() {
        dataSource = FinderDataSource(collectionView: self.collectionView, cellProvider: { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let self = self else {
                return nil
            }
            if item is FTThumbnailable {
                return self.collectionView(collectionView, thumbnailsCellForRowAt: indexPath)
            } else if item is FTPlaceHolderThumbnail {
                return self.collectionView(collectionView, placeHolderCellForRowAt: indexPath)
            } else if item is FTOutline {
                return self.collectionView(collectionView, outLineCellForRowAt: indexPath)
            } else if item is FTBookmarkCell {
                return self.collectionView(collectionView, bookmarkCellForRowAt: indexPath)
            }
            return nil
        })

        dataSource.supplementaryViewProvider =
        { [weak self] (collectionView, kind, indexPath) in
            guard kind == UICollectionView.elementKindSectionHeader, let self = self else {
                fatalError("Could not dequeue footer: FTShelfFooter")
            }
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTFinderCollectionViewHeader", for: indexPath) as? FTFinderCollectionViewHeader else {
                fatalError("Could not dequeue footer: FTShelfFooter")
            }
            self.sectionHeader = sectionHeader
            sectionHeader.del = self
            sectionHeader.configureHeader(count: self.filteredPages.count, mode: self.screenMode, tab: self.selectedTab)
            return sectionHeader
        }
    }

    private func showPlaceHolderThubnail() -> Bool {
        if selectedTab == .thumnails && self.mode == .none {
            return true
        }
        return false
    }
    
    internal func createSnapShot(shouldReload: Bool = false) {
        let sections = sectionsToReload()
        if dataSource == nil {
            return
        }
        var itemSnapShot = FinderSnapShot()
        if sections.isEmpty {
            //Empty state
            self.snapShot = itemSnapShot
        } else {
            let type = sections
            itemSnapShot.appendSections(type)
            for type in sections {
                if type == .thumbnails, let sectionItems = self.filteredPages as? [AnyHashable] {
                    collectionView.backgroundView?.isHidden = true
                    if sectionItems.isEmpty {
                        collectionView.backgroundView?.isHidden = false
                    } else {
                        collectionView.backgroundView?.isHidden = true
                        itemSnapShot.appendItems(sectionItems, toSection: type)
                        if self.showPlaceHolderThubnail() {
                            itemSnapShot.appendItems([FTPlaceHolderThumbnail(name: "place")], toSection: type)
                        }
                    }
                } else if type == .outline {
                    if !(outlinesViewController?.outlinesList.isEmpty ?? false) {
                        itemSnapShot.appendItems([FTOutline(name: "outline")], toSection: .outline)
                    }
                } else if type == .bookmark {
                    placeHolderVc?.updateView(for: .bookmark)
                    collectionView.backgroundView?.isHidden = true
                    if filteredPages.isEmpty  {
                        collectionView.backgroundView?.isHidden = false
                    } else {
                        collectionView.backgroundView?.isHidden = true
                        filteredPages.forEach { eachItem in
                            itemSnapShot.appendItems([FTBookmarkCell(uuid: eachItem.uuid)], toSection: type)
                        }
                    }
                } else {
                    collectionView.backgroundView?.isHidden = true
                    //We know there should be one row per section
                    if selectedTab == .search {
                        itemSnapShot.appendItems([type], toSection: type)
                    }
                }
            }
            self.snapShot = itemSnapShot
        }
        if shouldReload {
            self.dataSource.applySnapshotUsingReloadData(self.snapShot)
        } else {
            self.dataSource.apply(self.snapShot, animatingDifferences: false)
        }
        if selectedTab == .search {
            self.sectionHeader?.updateCountLabel(with: self.filteredPages.count)
        }
    }

    func didChangeState(to screenState: FTFinderScreenState){
        if screenState == .fullScreen || screenState == .initial {
            self.configureViewItems()
            if selectedTab != .search {
                refreshSnapShot()
            }
        }
    }

    func shouldStartWithFullScreen() -> Bool{
        return UserDefaults.standard.bool(forKey: "FT_Thumbnails_FullScreen")
    }
    
    func refreshSnapShot(with animation:Bool = false) {
        var snapoShot = self.dataSource.snapshot()
        snapoShot.reloadSections(sectionsToReload())
        self.dataSource.apply(snapoShot, animatingDifferences: animation, completion: nil)
    }
   
    private func configureMoreButton() {
        var actions = [UIMenuElement]()
        let copyAction = FTMoreOption.copy.actionElment {[weak self] action in
            self?.didTapMoreOption(identifier: action.identifier.rawValue)
        }
        let bookMarkAction = FTMoreOption.bookMark.actionElment {[weak self] action in
            self?.didTapMoreOption(identifier: action.identifier.rawValue)
        }
        let tagAction = FTMoreOption.tag.actionElment {[weak self] action in
            self?.didTapMoreOption(identifier: action.identifier.rawValue)
        }
        let moveAction = FTMoreOption.move.actionElment {[weak self] action in
            self?.didTapMoreOption(identifier: action.identifier.rawValue)
        }
        let deleteAction = FTMoreOption.delete.actionElment {[weak self] action in
            self?.didTapMoreOption(identifier: action.identifier.rawValue)
        }
        actions.append(UIMenu(identifier: UIMenu.Identifier( FTMoreOption.delete.rawValue), options: .displayInline, children: [deleteAction]))
        actions.append(UIMenu(identifier: UIMenu.Identifier(FTMoreOption.move.rawValue), options: .displayInline, children: [moveAction]))
        actions.append(UIMenu(identifier: UIMenu.Identifier(FTMoreOption.bookMark.rawValue), options: .displayInline, children: [tagAction, bookMarkAction]))
        actions.append(UIMenu(identifier: UIMenu.Identifier(FTMoreOption.copy.rawValue), options: .displayInline, children: [copyAction]))
        let menu = UIMenu(children: actions)
        moreButton.menu = menu
        moreButton.showsMenuAsPrimaryAction = true
    }

    @IBAction func didTapDuplicate(_ sender: Any) {
        self.duplicateClicked()
        FTFinderEventTracker.trackFinderEvent(with: "finder_select_duplicate_tap", params: ["location": currentFinderLocation()])

    }

    @IBAction func didTapRotate(_ sender: Any) {
        self.rotateClicked(withSelectedPages: selectedPages)
        FTFinderEventTracker.trackFinderEvent(with: "finder_select_rotate_tap", params: ["location": currentFinderLocation()])

    }

    @IBAction func didTapShare(_ sender: Any) {
        self.shareClicked(withSelectedPages: selectedPages)
        FTFinderEventTracker.trackFinderEvent(with: "finder_select_share_tap", params: ["location": currentFinderLocation()])

    }

    @IBAction func didTapEditButton(_ sender: Any) {
        self.mode = .edit
        self.validateHeaderView()
    }

    private func configureEditButton() {
        let moreOptions: [FTEditOption] = [.edit, .expand]
        var actions = [UIAction]()
        moreOptions.forEach { eachType in
            let action = eachType.actionElment {[weak self] action in
                self?.didTapEditOption(identifier: action.identifier.rawValue)
            }
            actions.append(action)
        }
        let menu = UIMenu(children: actions)
        editButton.menu = menu
        editButton.showsMenuAsPrimaryAction = true
    }

    private func updateMenuItemsIfNeeded() {
        if let elements = editButton.menu?.children {
            elements.forEach { eachElement in
                if let action = eachElement as? UIAction, action.identifier.rawValue == FTEditOption.edit.rawValue {
                    if self.filteredPages.isEmpty {
                        action.attributes = .disabled
                    } else {
                        action.attributes = .standard
                    }
                }
            }
        }
        editNavButton?.isEnabled = !self.filteredPages.isEmpty
    }

    private func didTapEditOption(identifier: String) {
        let option = FTEditOption(rawValue: identifier)
        switch option {
        case .edit:
            self.mode = .edit
            runInMainThread(0.1) {
                self.validateHeaderView()
            }
            FTFinderEventTracker.trackFinderEvent(with: "finder_more_select_tap")
        case .expand:
            self.delegate?.didTapOnExpandButton()
            FTFinderEventTracker.trackFinderEvent(with: "finder_more_fullscreen_tap")
        case .none:
            debugPrint("None")
        }
    }

    internal func validateHeaderView() {
        let isEditMode = (mode == .edit)
        hideTabBar(isEditMode)
        updateHeaderUI()
        optionsToolBar.isHidden = !isEditMode
        self.disableEditOptions()
        self.createSnapShot(shouldReload: true)
    }

    @IBAction func didTapDoneButton(_ sender: Any) {
        if mode == .selectPages {
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.share_selectpages_done_tap, params: ["location": currentFinderLocation()])
            self.dismiss(animated: true)
            return
        }
        self.mode = .none
        validateHeaderView()
        self.selectedPages.removeAllObjects();
        self.selectAll = true;
        self.updateSelectAllUI();
        self.updateSelectionTitle()
        FTFinderEventTracker.trackFinderEvent(with: "finder_select_done_tap", params: ["location": currentFinderLocation()])
    }

    private func disableEditOptions() {
        shareButton.isEnabled = false
        moreButton.isEnabled = false
        duplicateButton.isEnabled = false
        rotateButton.isEnabled = false
    }

    private func enableEditOptions() {
        shareButton.isEnabled = true
        moreButton.isEnabled = true
        duplicateButton.isEnabled = true
        rotateButton.isEnabled = true
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if selectedTab == .thumnails {
            if self.screenMode == .fullScreen && self.mode == .none  {
                return CGSize(width: collectionView.frame.size.width, height: 50)
            }
        } else if selectedTab == .search {
            return CGSize(width: collectionView.frame.size.width, height: 44)
        }
        return CGSize.zero
    }

    @IBAction func didTapExpandButton(_ sender: Any) {
        self.delegate?.didTapOnFinderCloseButton()
    }

    @IBAction func didTapPrimaryButton(_ sender: Any) {
        self.delegate?.didTapOnPrimaryButton()
    }

    @IBAction func didTapOnSelectAll(_ sender: Any) {
        self.selectAllClicked()
    }

    private func hideTabBar(_ value: Bool) {
        if let tabBarController = self.parent?.parent as? FTFinderTabBarController {
            tabBarController.tabBar.isHidden = value
        }
    }

    @IBAction func didTapOnSegment(_ sender: Any) {
        if let segmentControl = sender as? FTFinderSegmentControl {
            if self.mode == .selectPages {
                self.deselectAll()
            }
            if let segmentType = FTFinderSectionType(rawValue: segmentControl.selectedSegmentIndex) {
                FTFinderEventTracker.trackFinderEvent(with: "finder_pages_segment_tap", params: ["segment": segmentType.segmentName()])
                updateSegmentData(for: segmentType);
            }
        }
    }

    @IBAction func shareButton(_ sender: Any) {
        self.dismiss(animated: true)
        self.shareClicked(withSelectedPages: self.selectedPages)
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.share_selectpages_share_tap, params: ["location": currentFinderLocation()])
    }

    private func updateSegmentData(for type: FTFinderSectionType) {
        var headerTitle = "Pages"
        editButton.isEnabled = true
        editButton.isHidden = false
        compactEditButton?.isEnabled = true
        if !(self.delegate?._isRegularClass() ?? false) {
            editButton.isHidden = true
        }
        switch type {
        case .thumbnails:
            headerTitle = NSLocalizedString("Pages", comment: "Pages")
            self.selectedSegment = .pages
            reloadFilteredItems()
            if let previousScrollOffSet {
                collectionView.contentOffset = previousScrollOffSet
            }
        case .bookmark:
            //Book marks
            if selectedSegment == .pages {
                previousScrollOffSet = self.collectionView.contentOffset
            }
            headerTitle = NSLocalizedString("finder.bookmarks", comment: "Bookmarks")
            self.selectedSegment = .bookmark
            let documentPages = self.documentPages
            let filteredPages = documentPages.filter{$0.isBookmarked};
            self.filteredPages = filteredPages
            if filteredPages.isEmpty {
                createSnapShot()
                placeHolderVc?.updateView(for: .bookmark)
                compactEditButton?.isEnabled = false
            } else {
                editButton.isEnabled = true
                collectionView.isHidden = false
                reloadFilteredItems()
                compactEditButton?.isEnabled = true
            }
        case .outline:
            //Outline
            if selectedSegment == .pages {
                previousScrollOffSet = self.collectionView.contentOffset
            }
            self.selectedSegment = .outlines
            headerTitle = NSLocalizedString("finder.outline", comment: "Outline")
            placeHolderVc?.updateView(for: .outlines)
            if self.outlinesViewController == nil {
                let outlinesVc = FTOutlinesViewController.instantiate(fromStoryboard: .finder)
                self.outlinesViewController = outlinesVc
                self.outlinesContainerView = outlinesVc.view
                if let currentDocument = self.document as? FTNoteshelfDocument {
                    self.outlinesViewController?.delegate = self
                    self.outlinesViewController?.currentDocument = currentDocument
                }
            }
            self.collectionView.backgroundView?.isHidden = true
            compactEditButton?.isEnabled = false
            self.outlinesViewController?.refreshOutlines(with:  "")
        default:
            print("print")
            break
        }
        self.navigationItem.title = headerTitle
        if screenMode == .normal {
            //dividerView.isHidden = self.filteredPages.isEmpty
        }
        let indexPath = IndexPath(row: 0, section: 0)
        if screenMode == .fullScreen, let cell = self.collectionView?.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath) as? FTFinderCollectionViewHeader {
            //                cell.headerLabel.text = headerTitle
        } else {
            headerLabel.text = headerTitle
        }
        updateMenuItemsIfNeeded()
    }

    func _placeHolderVc() -> FTFinderNoResultsViewHostingController {
        let finderNoResultsVc = FTFinderNoResultsViewHostingController(segment: self.selectedSegment)
        self.placeHolderVc = finderNoResultsVc
        return finderNoResultsVc
    }

    private func setUpCollectionview() {
        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
        self.collectionView.allowsMultipleSelection = true;
        self.collectionView.alwaysBounceVertical = true;
        self.collectionView.dragInteractionEnabled = (self.mode == .selectPages) ? false : true
    }

    func configureForSearchTab() {
        recentsList = FTFilterRecentsStorage.shared.availableRecents()
        hideStackView(true)
        runInMainThread {[weak self] in
            self?.collectionViewTopConstraint?.constant = 0
            self?.stackviewTopConstraint?.constant = 0
        }
    }

    func hideStackView(_ value: Bool) {
        stackView.subviews.forEach { eachView in
            eachView.isHidden = value
        }
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(FTFinderViewController.handlePageRecognitionUpdate(_:)), name: NSNotification.Name(rawValue: FTRecognitionInfoDidUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFinderReloadNotifier(_:)), name: .shouldReloadFinderNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCurrentPageChangeNotifier(_:)), name:  .didChangeCurrentPageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FTFinderViewController.willShowHideKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(FTFinderViewController.willShowHideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(FTFinderViewController.reloadData), name: NSNotification.Name("FTDocumentGetReloaded"), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(FTFinderViewController.reloadData), name: NSNotification.Name.FTPageDidChangePageTemplate, object: nil)
    }

    @objc private func handleFinderReloadNotifier(_ notification: Notification) {
        if var arrSelectedPages = Array(self.selectedPages) as? [FTThumbnailable] {
            if self.mode == .edit, !arrSelectedPages.isEmpty {
                let pages = self.documentPages
                arrSelectedPages = arrSelectedPages.filter { reqPage in
                    return pages.contains { page in
                        return reqPage.uuid == page.uuid
                    }
                }
                self.selectedPages.removeAllObjects()
                self.selectedPages.addObjects(from: arrSelectedPages)
                self.updateSelectAllUI()
            }
        }
        self.refreshSnapShot()
    }

    @objc private func handleCurrentPageChangeNotifier(_ notification: Notification) {
        var currentSessionID = ""
        if let sessionIdentifier = self.view.window?.windowScene?.session.persistentIdentifier {
            currentSessionID = sessionIdentifier
        }
        guard let sessionID = notification.object as? String, sessionID == currentSessionID else {
            return
        }
        self.createSnapShot(shouldReload: true)
        self.shouldMoveToCurrentPage = true
        moveToCurrentPageIfNeeded()
    }

    func didTapOnSegmentControl(_segmentControl: FTFinderSegmentControl) {
        if let segmentType = FTFinderSectionType(rawValue: _segmentControl.selectedSegmentIndex) {
            updateSegmentData(for: segmentType);
            if self.segmentControl != _segmentControl  {
                self.segmentControl?.selectedSegmentIndex = _segmentControl.selectedSegmentIndex
            }
        }
    }

    private func configureViewItems() {
        self.updateHeaderView()
        collapseButton.isHidden = !(self.delegate?._isRegularClass() ?? false)
        dismissButton.isHidden = self.delegate?._isRegularClass() ?? false
        primaryButton.isHidden = !(self.delegate?._isRegularClass() ?? false)
        editButton.isHidden = !(self.delegate?._isRegularClass() ?? false)
        compactEditButton?.isHidden = self.delegate?._isRegularClass() ?? false
        if screenMode == .normal {
            let hide = (collectionView.contentOffset.y > 0) ? false : true
            self.hideBottomDivider(hide)
        }
        updateUi(ofOptionButton: shareButton, option: .share)
        updateUi(ofOptionButton: rotateButton, option: .rotate)
        updateUi(ofOptionButton: duplicateButton, option: .duplicate)
        updateUi(ofOptionButton: moreButton, option: .more)
    }

    //TODO - Refactor this
    private func updateHeaderView() {
        if self.screenMode == .fullScreen {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut) {
                self.navigationController?.navigationBar.alpha = 1
                self.headerView?.alpha = 0
                self.segmentControl?.alpha = 0
                self.stackView.alpha = 0
                self.stackView.isHidden = true
                self.headerView?.isHidden = true
                self.segmentControl?.isHidden = true
                self.dividerView?.isHidden = true
                self.shouldShowNavBar(true)
                self.collectionViewTopConstraint?.constant = 54
                self.view.layoutIfNeeded()
            }
        } else if screenMode == .normal {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
                self.navigationController?.navigationBar.alpha = 0
                self.headerView?.alpha = 1
                self.segmentControl?.alpha = 1
                self.stackView.alpha = 1
                self.stackView.isHidden = false
                self.headerView?.isHidden = false
                self.segmentControl?.isHidden = false
                self.shouldShowNavBar(false)
                self.collectionViewTopConstraint?.constant = 20
                self.dividerView?.isHidden = false
                self.view.layoutIfNeeded()
            }
        }
    }

    private func updateUi(ofOptionButton button: UIButton, option: FTBottomOption) {
        if screenMode == .fullScreen {
            button.configuration?.imagePlacement = .leading
            button.configuration?.imagePadding = 10
            let titleAttrString = NSAttributedString(string: option.title(), attributes: [NSAttributedString.Key.font : UIFont.appFont(for: .regular, with: 15)])
            button.setAttributedTitle(titleAttrString, for: .normal)
        } else if screenMode == .normal {
            button.configuration?.imagePlacement = .top
            button.configuration?.imagePadding = 5
            let titleAttrString = NSAttributedString(string: "")
            button.setAttributedTitle(titleAttrString, for: .normal)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if targetEnvironment(macCatalyst)
        if mode != .selectPages {
            hideStackView(true)
            self.collectionViewTopConstraint?.constant = 0
            self.stackviewTopConstraint?.constant = 0
            dividerView?.isHidden = true
            self.view.updateConstraintsIfNeeded()
        }
#else
        if self.selectedTab == .thumnails && mode == .none {
            configureViewItems()
            if screenMode == .fullScreen {
                shouldShowNavBar(true)
                configureNavigation(title: "Pages".localized)
            } else {
                shouldShowNavBar(false)
            }
        }
            reloadFilteredItems()
            self.editButton.isEnabled = !self.filteredPages.isEmpty
            //updateSegmentData(for: self.segmentControl)
            self.sectionHeader?.segmentControl.selectedSegmentIndex = self.selectedSegment.rawValue
            (self.collectionView.collectionViewLayout as? FTFinderCollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = (screenMode == .fullScreen)
        #endif
        if !shouldMoveToCurrentPage {
            shouldMoveToCurrentPage = true
            moveToCurrentPageIfNeeded(withDelay: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        let currentFrameSize = self.view.frame.size
        if(currentFrameSize != self.currentSize) {
            self.currentSize = currentFrameSize
            self.collectionView.layoutIfNeeded()
            refreshSnapShot()
        }
    }

    @objc func handlePageRecognitionUpdate(_ notification: Notification){
    }

    fileprivate func updateSelectAllUI() {
        self.selectAllButton.isSelected = !self.selectAll
        self.updateSelectAll()
        if selectedPages.count == 0 {
            self.disableEditOptions()
        } else {
            self.enableEditOptions()
        }
        if mode == .selectPages {
            pagesShareButton.isHidden = (selectedPages.count == 0)
        }
        updateSelectionTitle()
    }

    private func updateSelectAll() {
        let title = !self.selectAllButton.isSelected ? NSLocalizedString("SelectAll", comment: "Select All") : NSLocalizedString("shelf.navBar.deselectAll", comment: "Select None")
        self.navigationItem.leftBarButtonItem?.title = title
        if mode == .selectPages {
            self.selectAllButton.setTitle(title, for: .normal)
        }
        //self.selectAllButton.titleLabel?.addCharacterSpacing(kernValue: -0.41)
    }


    func deselectAll() {
        self.selectedPages.removeAllObjects();
        self.refreshSnapShot()
        self.selectAll = true;
        self.updateSelectAllUI();
    }

    func updateFilterAndCreateSnapShot() {
        var filteredPages = self.searchResultPages ?? self.documentPages
        if selectedSegment == .bookmark {
            filteredPages = filteredPages.filter{$0.isBookmarked};
        }
        self.filteredPages = filteredPages;
        createSnapShot()
        moveToCurrentPageIfNeeded()
    }

    private func sectionsToReload() -> [FTFinderSectionType] {
        sections.removeAll()
        if selectedTab == .thumnails {
            if selectedSegment == .outlines {
                sections.append(.outline)
            } else if selectedSegment == .bookmark {
                sections.append(.bookmark)
            } else {
                sections.append(.thumbnails)
            }
        } else if selectedTab == .search {
            sections.append(.thumbnails)
        }
        return sections
    }

    internal func isBookMarkedOrTaggedFilteredScreen() -> Bool {
        if selectedSegment == .bookmark  {
            return true
        }
        return false
    }

    @objc func reloadData(withAnimation shouldAnimate: Bool = true) {
        reloadFilteredItems()
    }

    func switchToEditModeIfNeeded() {
        if self.mode != .edit {
            self.mode = .edit
            validateHeaderView()
        }
    }

    private func reloadItems() {
        self.reloadFilteredItems();
    }
    
    internal func reloadFilteredItems() {
        var filteredPages = self.searchResultPages ?? self.documentPages;
        if selectedSegment == .bookmark {
            filteredPages = filteredPages.filter{$0.isBookmarked};
        }
        self.filteredPages = filteredPages;
        if selectedTab == .search && isSearching {
            self.searchDelegate?.refreshSearchPagesUI()
        } else {
            createSnapShot(shouldReload: true)
            self.moveToCurrentPageIfNeeded();
        }
    }

    private func moveToCurrentPageIfNeeded(withDelay: Bool = true) {
        if self.shouldMoveToCurrentPage && selectedTab == .thumnails {
            self.shouldMoveToCurrentPage = false;
            if let currentPage = self.delegate?.currentPage(in: self) {
                let rows = self.collectionView.numberOfItems(inSection: 0);
                if let index = self.filteredPages.index(where: {$0.uuid == currentPage.uuid}), index < rows {
                    func scrollToItem() {
                        if index < self.filteredPages.count {
                            self.collectionView.scrollToItem(at: IndexPath.init(item: index, section: 0), at: UICollectionView.ScrollPosition(), animated: false);
                        }
                    }
                    if withDelay {
                        runInMainThread(0.1, closure: {
                            scrollToItem()
                        });
                    } else {
                        scrollToItem()
                    }
                }
            }
        }
    }

    //MARK:- Custom
    @IBAction func dismiss() {
        self.delegate?.didTapOnDismissButton()
    }
}

extension FTFinderViewController:  UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //MARK:- UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView, indexPath.item < self.filteredPages.count  {
            let page = self.filteredPages[indexPath.item]
            page.thumbnail()?.cancelThumbnailGeneration();
        }
    }

    func snapshotItem(for indexPath: IndexPath) -> AnyHashable {
        let sectionType = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        return dataSource.snapshot().itemIdentifiers(inSection: sectionType)[indexPath.row]
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView
        {
            if collectionView.hasActiveDrag {
                return
            }
            let item =  snapshotItem(for: indexPath)
            if item is FTPlaceHolderThumbnail {
                return
            }

            let page = self.filteredPages[indexPath.item];
            if  self.mode == .none {
                let indexSelected: Int;
                if self.mode == .none {
                    if let index = self.documentPages.firstIndex(where: {$0.uuid == page.uuid}) {
                        indexSelected = index;
                    }
                    else {
                        indexSelected = 0;
                    }
                }
                else {
                    indexSelected = indexPath.item;
                }
                self.delegate?.finderViewController(didSelectPageAtIndex: indexSelected)
                FTFinderEventTracker.trackFinderEvent(with: "finder_page_tap", params: ["location": currentFinderLocation()])
                //                createSnapShot()
            }
            else if self.mode == .edit || mode == .selectPages {
                let pageSelected = self.selectedPages.contains(where: { (element) -> Bool in
                    let pageElemenet = element as! FTThumbnailable
                    return pageElemenet.uuid == page.uuid;
                });
                if pageSelected {
                    self.selectedPages.remove(page);
                    trackPageUnSelect()
                }
                else {
                    self.selectedPages.add(page);
                    trackPageSelect()
                }
                if let collectionViewCell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell {
                    collectionView.deselectItem(at: indexPath, animated: true);
                    collectionViewCell.setIsSelected(!pageSelected);
                    if let currentPage = self.delegate?.currentPage(in: self), currentPage.uuid == page.uuid, self.mode == .none {
                        collectionViewCell.setAsCurrentVisiblePage()
                    }
                }
                else {
                    if let collectionViewCell = collectionView.cellForItem(at: indexPath) as? FTBookmarkCollectionViewCell {
                        collectionView.deselectItem(at: indexPath, animated: true);
                        collectionViewCell.setIsSelected(!pageSelected)
                    }
                }

                if self.selectedPages.count == self.filteredPages.count {
                    self.selectAll = false;
                }
                else {
                    self.selectAll = true;
                }
                self.updateSelectAllUI();
                self.updateSelectionTitle()
            }
        }
    }
    
    private func trackPageSelect() {
        if mode == .selectPages {
            FTNotebookEventTracker.trackNotebookEvent(with: "share_selectpages_page_select", params: ["location": currentFinderLocation()])
        } else {
            FTFinderEventTracker.trackFinderEvent(with: "finder_select_page_select_tap", params: ["location": currentFinderLocation()])
        }
    }
    
    private func trackPageUnSelect() {
        if mode == .selectPages {
            FTNotebookEventTracker.trackNotebookEvent(with: "share_selectpages_page_unselect", params: ["location": currentFinderLocation()])
        } else {
            FTFinderEventTracker.trackFinderEvent(with: "finder_select_page_unselect_tap", params: ["location": currentFinderLocation()])
        }
    }

    internal func currentFinderLocation() -> String {
        var currentLocation = "thumbnails"
        if self.selectedTab == .thumnails {
            currentLocation = self.selectedSegment.segmentName()
        } else if self.selectedTab == .search {
            currentLocation = FTFinderSegment.search.segmentName()
        }
        return currentLocation
    }
}

extension FTFinderViewController {
    func filterOptionsController(didChangeSearchText keyword: String, onFinding: (() -> ())?, onCompletion: (() -> ())?) {
        let trimmedKeyword = keyword.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if (!trimmedKeyword.isEmpty) {
            var notification = Notification.init(name: Notification.Name.init(FTRecognitionInfoDidUpdateNotification))
            notification.userInfo = (self.document as? FTRecognitionHelper)?.recognitionHelper?.recognitionIndexingInfo
            self.handlePageRecognitionUpdate(notification)
        }
        else{
        }

        self.delegate?.finderViewController(self, searchForKeyword: trimmedKeyword, onFinding: onFinding, onCompletion: onCompletion)
        self.searchResultPages = [FTThumbnailable]();
        collectionView.backgroundView = nil
        self.updateFilterAndCreateSnapShot();
    }
}

extension FTFinderViewController{
    var isRegularWidth: Bool {
        return self.delegate?._isRegularClass() ?? false && self.view.frame.width == UIScreen.main.bounds.width;
    }

    var isRegularFinder: Bool {
        var isRegular = self.delegate?._isRegularClass() ?? false
        let minWidthForRegularSizeClass : CGFloat = 694;
        if self.view.frame.width <= minWidthForRegularSizeClass {
            isRegular = false
        }
        return isRegular;
    }

    var minimumInterItemSpacing: CGFloat {
        let spacing: CGFloat
        if mode == .selectPages {
            spacing = 10
        } else if self.isRegularFinder {
            spacing = 24
        } else {
            spacing = 24
        }
        return spacing
    }

    private var bookMarkContentInsets: UIEdgeInsets {
        let horizontalMargin: CGFloat = (self.screenMode == .normal) ? 16 : 44
        return UIEdgeInsets(top: 5, left: horizontalMargin, bottom: 20, right: horizontalMargin)
    }

    private var cellWidthForBookmark : CGFloat {
        let extraInsets = self.bookMarkContentInsets.left + self.bookMarkContentInsets.right
        return collectionView.frame.width - extraInsets
    }

    var contentInset: UIEdgeInsets {
        let horizontalMargin: CGFloat = 44 //self.isRegularFinder ? 44 : 24;
        return UIEdgeInsets(top: 5, left: horizontalMargin, bottom: 22, right: horizontalMargin);
    }

    fileprivate func horizontalSpacing() -> CGFloat{

        var expectedSpacing: CGFloat = 0
        let cellWidth: CGFloat = self.cellSize.width
        var availableWidth = self.collectionView.frame.width - CGFloat(self.contentInset.left * 2)
        var cellCount = Int(availableWidth / cellWidth)
        availableWidth = availableWidth - CGFloat((cellCount-1) * Int(self.minimumInterItemSpacing))
        cellCount = Int(availableWidth / cellWidth)

        availableWidth = self.collectionView.frame.width - CGFloat(self.contentInset.left * 2)
        if cellCount > 1{
            expectedSpacing = (availableWidth - CGFloat(cellCount * Int(cellWidth))) / CGFloat((cellCount-1))
        }
        else{
            expectedSpacing = self.minimumInterItemSpacing
        }
        return expectedSpacing
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let hide = (scrollView.contentOffset.y > 0) ? false : true
        self.hideBottomDivider(hide)
    }

    private func hideBottomDivider(_ value: Bool) {
#if !targetEnvironment(macCatalyst)
        if self.selectedTab == .thumnails {
            if screenMode == .fullScreen {
                if screenMode == .fullScreen, let header = self.sectionHeader {
                    header.hideDivider(value)
                }
            } else if screenMode == .normal {
                dividerView?.isHidden = value
            }
        }
#endif
    }

    func updateBackgroundViewForSearch() {
        collectionView.backgroundView = _placeHolderVc().view
        self.placeHolderVc?.updateView(for: .search)
    }
    
    func showSearchIndicator(_ value : Bool) {
        self.sectionHeader?.showSearchIndicator(value)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let sectionIdentfier = dataSource.sectionIdentifier(for: section)
        if sectionIdentfier == .thumbnails {
            return 24
        } else if sectionIdentfier == .bookmark {
            return 8
        }
        return 0;
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let sectionIdentfier = dataSource.sectionIdentifier(for: section)
        if (screenMode == .fullScreen || (screenMode == .normal && !self.isRegularClass())) && sectionIdentfier == .thumbnails {
            return 24
        }
        if mode == .selectPages {
            return self.horizontalSpacing()
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionIdentfier = dataSource.sectionIdentifier(for: section)
        if sectionIdentfier == .thumbnails {
            if screenMode == .normal && (self.delegate?._isRegularClass() ?? false) {
                return UIEdgeInsets(top: 5, left: 0, bottom: 20, right: 0)
            } else if screenMode == .fullScreen {
                return self.contentInset
            }

        } else if sectionIdentfier == .bookmark || sectionIdentfier == .outline {
            return self.bookMarkContentInsets
        }
        return self.contentInset
    }
    
    private func noOfGridColumns(_ size: CGSize) -> Int {
        let availableSize = size.width - (2 * contentInset.left);
        let cellWidth = self.cellSize.width;
        let cellWidthWithSpacing = cellWidth + minimumInterItemSpacing;
        var maxColumns = Int(availableSize / cellWidthWithSpacing)
        let totalWidthNeeded = (CGFloat(maxColumns) * cellWidth) + (CGFloat(maxColumns - 1) * minimumInterItemSpacing);
        if(availableSize > (totalWidthNeeded + cellWidth * 0.5)) {
            maxColumns += 1;
        }
        return maxColumns;
    }
    
    internal func cellSize(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfGridColumns(size)
        let totalSpacing = minimumInterItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (contentInset.left * 2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = dataSource.itemIdentifier(for: indexPath)
        if  item is  FTPlaceHolderThumbnail {
            let columnWidth = cellSize(collectionView.frame.size)
            let potraitWidth = ((columnWidth) * potraitWidthRatio)
            let height : CGFloat = ((potraitWidth) * potraitHeightRatio)
            let size = CGSize(width: columnWidth, height: height + extraCellPadding)
            return size
        }
        if item is FTOutline {
            var height = self.outlinesViewController?.treeView.contentSize.height
            if height == .zero {
                height = collectionView.frame.height
            }
            return CGSize(width: cellWidthForBookmark, height: height ?? .zero  )
        } else if item is FTBookmarkCell {
            return CGSize(width: cellWidthForBookmark, height: 90)
        }
        if filteredPages.count == 0 {
            return CGSize.zero
        }
        let page: FTThumbnailable!;

        let collectionViewLayout = collectionViewLayout as! FTFinderCollectionViewFlowLayout;

        if let draggedOldIndexPath = collectionViewLayout.draggedOldIndexPath,
           let selectedItemIndexPath = collectionViewLayout.selectedItemIndexPath,
           nil != collectionViewLayout.draggedOldIndexPath
            && nil != collectionViewLayout.selectedItemIndexPath
            && ((indexPath.item <= draggedOldIndexPath.item && indexPath.item >= selectedItemIndexPath.item)
                || (indexPath.item >= draggedOldIndexPath.item && indexPath.item <= selectedItemIndexPath.item)) {
            //Dragover
            if indexPath == selectedItemIndexPath {
                page = self.filteredPages[draggedOldIndexPath.item];
            }
            //MovingUp
            else if indexPath.item <= draggedOldIndexPath.item && indexPath.item >= selectedItemIndexPath.item {
                page = self.filteredPages[indexPath.item - 1];
            }
            //MovingDown
            else {
                page = self.filteredPages[indexPath.item + 1];
            }
        }
        else {
            page = self.filteredPages[indexPath.item];
        }
        let columnWidth = cellSize(collectionView.frame.size)
        let potraitWidth = ((columnWidth) * potraitWidthRatio)
        var height : CGFloat = ((potraitWidth) * potraitHeightRatio)
        if page.pdfPageRect.size.width > page.pdfPageRect.size.height {
            height = ((columnWidth) * landscapeHeightRatio)
        }
        let size = CGSize(width: columnWidth, height: height)
        return CGSize(width: size.width, height: size.height + extraCellPadding);
    }
    

    //MARK:- StateMachine
    fileprivate func changeState(from fromState:FTFinderPageState, to toState: FTFinderPageState, withAnimation needAnimation: Bool) {
        self.mode = toState;

        switch fromState {
        case .edit:
            if let collectionViewCells = self.collectionView.visibleCells as? [FTFinderThumbnailViewCell] {
                collectionViewCells.forEach{$0.editing = false};
            }
            self.selectedPages.removeAllObjects();
            self.selectAll = true;
            self.updateSelectAllUI();
        case .none, .selectPages:
            break;
        }

        self.mode = toState;
    }

    fileprivate func updateSelectionTitle() {
        let titleEditMode: String;
        if self.selectedPages.count > 0 {
            titleEditMode = String.init(format: NSLocalizedString("numSelected", comment: "numSelected"), self.selectedPages.count);
        }
        else {
            if mode == .selectPages {
                titleEditMode = "SelectPages".localized
            } else {
                titleEditMode = "Select".localized
            }
        }
        if self.mode == .edit {
            self.navigationItem.title = titleEditMode
        }

        self.titleLabel?.text = titleEditMode
        self.titleLabel?.addCharacterSpacing(kernValue: -0.41)
    }

    func updateUI(ofTagButton buttonTag: UIButton) {
        let tag = self.allTags[buttonTag.tag];

        if tag.isSelected == true {
            buttonTag.setTitleColor(UIColor.white, for: UIControl.State.normal)
            buttonTag.layer.borderWidth = 0.0;
            buttonTag.backgroundColor = UIColor.appColor(.accent);
        }
        else {
            buttonTag.setTitleColor(UIColor.label, for: UIControl.State.normal)
            buttonTag.layer.borderWidth = 0.0;
            buttonTag.backgroundColor = UIColor.init(hexString: "#E5E5EA");
        }
    }

    //MARK:- Keyboard
    @objc fileprivate func willShowHideKeyboard(_ notification : Notification) {
        guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = self.view.window else {
            return
        }

        let endFrameWrtView = window.convert(endFrame, from: nil);
        let heightOfKeyboard = abs(window.bounds.size.height - endFrameWrtView.origin.y);

        var contentInset = self.collectionView.contentInset;
        contentInset.bottom = heightOfKeyboard;
        //        self.collectionView.contentInset = contentInset;
    }

    //MARK:- Share
    @IBAction func shareClicked(_ sender:UIButton) {
        self.delegate?.finderViewController(self, didSelectShareWithPages: self.selectedPages, exportTarget: self.exportTarget)
    }

}

extension FTFinderViewController {
    @IBAction fileprivate func editClicked() {
        self.view.endEditing(true);
        if self.mode == .edit {
            self.changeState(from: self.mode, to: .none, withAnimation: true);
        }
        else {
            self.changeState(from: self.mode, to: .edit, withAnimation: true);
            track("Finder_TapEditPage", params: [:],screenName: FTScreenNames.finder)
        }
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self.titleLabel);
    }

    @IBAction func toggleSelectAllClicked() {
        self.selectAllClicked()
        track("Finder_EditPage_SelectAll", params: [:],screenName: FTScreenNames.finder)
    }

    fileprivate func selectAllClicked() {
        self.selectAll = !self.selectAll;
        self.selectedPages.removeAllObjects();
        if !self.selectAll {
            self.selectedPages.addObjects(from: self.filteredPages)
        }
        UIView.performWithoutAnimation {
            refreshSnapShot()
        };
        self.updateSelectionTitle();
        self.updateSelectAllUI();
        if mode == .selectPages {
            let eventName = !self.selectAll ?  "share_selectpages_selectall_tap" :  "share_selectpages_selectnone_tap"
            FTNotebookEventTracker.trackNotebookEvent(with:eventName, params: ["location": currentFinderLocation()])
        } else {
            let eventName = !self.selectAll ?  "finder_select_selectall_tap" :  "finder_select_selectnone_tap"
            FTFinderEventTracker.trackFinderEvent(with:eventName, params: ["location": currentFinderLocation()])
        }
    }

    @IBAction func didTapAddNewPage(_ sender: UIButton) {
        let currentIndex = IndexPath(item: filteredPages.count - 1, section: 0)
        let pageItem = self.filteredPages[currentIndex.item]
        if let selectedPage = pageItem as? FTPageProtocol {
            let task = startBackgroundTask();
            DispatchQueue.main.async {
                self.listenToPageAddChange();
                self.delegate?.finderViewController(self, didSelectInsertBelowForPage: selectedPage);
                endBackgroundTask(task);
            }
        }
        FTFinderEventTracker.trackFinderEvent(with: "finder_newpage_tap")
    }

    //MARK:- Bookmark
    @IBAction func togglePageBookmark(_ sender: UIButton) {
        if self.mode == .selectPages { return }
        let page = self.filteredPages[sender.tag]
        let parameter = page.isBookmarked ? "off" : "on"
        FTFinderEventTracker.trackFinderEvent(with: "finder_page_bookmarkicon_toggle", params: ["toggle": parameter])
        self.delegate?.finderViewController(bookMark: page)
        if(page.isBookmarked == false) {
            sender.tintColor = .appColor(.gray9)
        } else {
            sender.tintColor = UIColor.appColor(.secondaryAccent)
            let toastConfig = FTToastConfiguration(title: "Bookmarked", subTitle: "Page \(page.pageIndex() + 1)")
            FTToastHostController.showToast(from: self, toastConfig: toastConfig)
        }
        refreshSnapShot()
    }
}

extension FTFinderViewController {
    func duplicateClicked() {
        guard let doc = self.document as? FTDocumentProtocol else {
            return;
        }

        FTNotebookUtils.checkIfAudioIsNotPlaying(forDocument: doc, InAnyOf: self.selectedPages,
                                                 alertMessage: "AudioRecoring_Progress_Message".localized,
                                                 onViewController: self)
        { [weak self] (success) in
            guard let self = self, success else {
                return
            }
            self.duplicateClicked(withSelectedPages: self.selectedPages);
        }
    }

    //MARK:- Actions
    @IBAction func moveClicked() {
        let shelfItemsViewModel = FTShelfItemsViewModel(purpose: .finder)
        shelfItemsViewModel.movePageDelegate = self
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: shelfItemsViewModel)
        controller.title = ""
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        if self.isRegularClass() {
            self.ftPresentFormsheet(vcToPresent: navController, contentSize: CGSize(width: 540, height: 620),hideNavBar: false)
        }else {
            self.ftPresentPopover(vcToPresent: navController, contentSize: CGSize(width: self.view.frame.width , height: 440),hideNavBar: false)
        }
    }
    @IBAction func duplicateClicked(withSelectedPages pages: NSSet) {
        let task = startBackgroundTask()
        self.showLoading(withMessage: NSLocalizedString("Duplicating", comment: "Duplicating"))

        if let reqPages = Array(pages) as? [FTThumbnailable] {
            self.delegate?.finderViewController(didSelectDuplicate: reqPages, onCompletion: { [weak self] in
                endBackgroundTask(task)
                DispatchQueue.main.async {
                    self?.hideLoading()
                    self?.reloadFilteredItems()
                }
            })
        }
    }

    private func listenToPageAddChange() {
        self.removeListenToPageAddChange();
        let doc = self.document;
        addPageNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "FTDocumentDidAddedPageIndices"),
                                                                             object: doc,
                                                                             queue: nil) { [weak self] (_) in
            self?.reloadFilteredItems() ;
            self?.removeListenToPageAddChange();
        }
    }

    private func removeListenToPageAddChange() {
        guard let observer = self.addPageNotificationObserver else{
            return;
        }
        let doc = self.document;
        NotificationCenter.default.removeObserver(observer,
                                                  name: Notification.Name(rawValue: "FTDocumentDidAddedPageIndices"),
                                                  object: doc);
    }

    func copyClicked(withSelectedPages pages: NSSet) {
        guard let doc = self.document as? FTDocumentProtocol else {
            return;
        }
        FTNotebookUtils.checkIfAudioIsNotPlaying(forDocument: doc, InAnyOf: pages,
                                                 alertMessage: "AudioRecoring_Progress_Message".localized,
                                                 onViewController: self)
        { [weak self] (success) in
            if success {
                self?.view.window?.isUserInteractionEnabled = false;
                self?.document?.saveDocument(completionHandler: { [weak self] ( success ) in
                    if success {
                        runInMainThread {
                            let t1 = Date.timeIntervalSinceReferenceDate;
                            let copiedPages = pages.allObjects as! [FTPageProtocol]
                            let pagesToCopy = copiedPages.sorted(by: { (p1, p2) -> Bool in
                                return (p1.pageIndex() < p2.pageIndex())
                            });

                            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(FTUtils.getUUID());
                            _ = doc.createDocumentAtTemporaryURL(url,
                                                                 purpose: .default,
                                                                 fromPages: pagesToCopy,
                                                                 documentInfo: nil)
                            { [weak self] (success, error) in
                                guard let self = self else{
                                    return
                                }
                                let t2 = Date.timeIntervalSinceReferenceDate;
                                debugPrint("COPY: Time Taken: \(t2-t1)");
                                let toastConfig = FTToastConfiguration(title: "Copied", subTitle: self.subTitle(pages: pages))
                                FTToastHostController.showToast(from: self, toastConfig: toastConfig)
                                self.view.window?.isUserInteractionEnabled = true;
                                if(nil != error) {
                                    if let nserror = error {
                                        nserror.showAlert(from: self);
                                    }
                                }
                                else {
                                    let pasteBoard = FTPasteBoardManager.shared
                                    pasteBoard.copiedUrl = url
                                }
                            }
                        }
                    } else {
                        self?.view.window?.isUserInteractionEnabled = true;
                    }
                })
            }
        }
    }

    private func subTitle(pages: NSSet) -> String {
        var subTitle = ""
        let newPages = pages.allObjects
        if !newPages.isEmpty {
            if newPages.count == 1 {
                if let firstPage = newPages.first as? FTThumbnailable {
                    subTitle = "Page \(firstPage.pageIndex() + 1)"
                }
            } else {
                subTitle = "\(newPages.count) pages"
            }
        }
        return subTitle
    }

    func shareClicked(withSelectedPages pages: NSSet) {
        guard let shelfItem = currentShelfItem(), let sharedPages = pages.allObjects as? [FTPageProtocol]  else {
            return
        }
        let presentingController = (mode == .selectPages) ? self.presentingViewController : self
        let reqPages = sharedPages.sorted(by: { (p1, p2) -> Bool in
            return (p1.pageIndex() < p2.pageIndex())
        })

        let option: FTShareOption = (reqPages.count == 1) ? .currentPage : (reqPages.count == self.filteredPages.count) ? .allPages : .selectPages

        guard let presentingController = presentingController else {return}
        var bookHasStandardCover: Bool = false
        if option == .allPages, let firstPage = reqPages.first {
            bookHasStandardCover = firstPage.isCover
        }
        let coord = FTShareCoordinator(shelfItems: [shelfItem], pages: reqPages, presentingController: presentingController)
        FTShareFormatHostingController.presentAsFormsheet(over: presentingController, using: coord, option: option, pages: reqPages,bookHasStandardCover: bookHasStandardCover)
    }

    func currentShelfItem() -> FTShelfItemProtocol? {
        var item = self.delegate?.currentShelfItemInShelfItemsViewController()
        if item == nil {
            item = self.pdfDelegate?.currentShelfItemInShelfItemsViewController()
        }
        return item
    }

    @IBAction func deleteClicked(withSelectedPages pages: NSSet, shouldShowAlert show: Bool) {

        guard let doc = self.document as? FTDocumentProtocol else {
            return;
        }

        let indexSet = NSMutableIndexSet();
        pages.forEach { [weak self] (page) in
            let index = self?.filteredPages.index(where: { (eachPage) -> Bool in
                if let pageProtocol = page as? FTPageProtocol,
                   pageProtocol.uuid == eachPage.uuid {
                    return true;
                }
                return false;
            });
            indexSet.add(index!);
        };

        let pageCount = self.documentPages.count;
        if(pages.count == pageCount) {
            _ = doc.insertPageAtIndex(pageCount);
        }

        func showAlert(_ pages: NSSet) {
            let alert = UIAlertController(title: "", message: "DeletePagePasswordProtectedAlert".localized, preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "MoveToTrash".localized, style: UIAlertAction.Style.default, handler: { [weak self] action in
                self?.movePagestoTrash(from: doc, pages: pages) { [weak self] (error, _) in
                    if error == nil, let weakSelf = self,let doc = weakSelf.document {
                        weakSelf.deletePagesPermanantly(from: doc,
                                                        pages: pages,
                                                        indexes: indexSet)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "DeletePermanently".localized, style: UIAlertAction.Style.default,  handler: { [weak self] (action) in
                if let weakSelf = self,let doc = weakSelf.document {
                    weakSelf.deletePagesPermanantly(from: doc,
                                                    pages: pages,
                                                    indexes: indexSet)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: UIAlertAction.Style.destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        FTNotebookUtils.checkIfAudioIsNotPlaying(forDocument: doc, InAnyOf: pages,
                                                 alertMessage: "AudioRecoring_Progress_Message".localized,
                                                 onViewController: self)
        { [weak self] (success) in
            if success, let weakSelf = self {
                if show {
                    let shareAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet);

                    let alertTitle: String;
                    if weakSelf.selectedPages.count == 1 {
                        alertTitle = String(format: NSLocalizedString("MovePageToTrash", comment: "Move %d page to Trash"), weakSelf.selectedPages.count);
                    }
                    else {
                        alertTitle = String(format: NSLocalizedString("MovePagesToTrash", comment: "Move %d pages to Trash"), weakSelf.selectedPages.count);
                    }
                    shareAlertController.addAction(UIAlertAction(title: alertTitle, style: .destructive, handler: { (action) in
                        runInMainThread { [weak self] in
                            if let weakSelf = self, let curDoc = weakSelf.document {
                                if curDoc.isPinEnabled() {
                                    showAlert(pages)
                                } else {
                                    weakSelf.movePagestoTrash(from: doc, pages: pages) { [weak self] (error, _) in
                                        if error == nil{
                                            self?.deletePagesPermanantly(from: curDoc, pages: pages, indexes: indexSet)
                                        }
                                    }
                                }
                            }
                        };
                    }));
                    shareAlertController.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: nil));

                    shareAlertController.modalPresentationStyle = .popover;
                    let sourceView = weakSelf.moreButton
                    shareAlertController.popoverPresentationController?.sourceView = sourceView;
                    shareAlertController.popoverPresentationController?.sourceRect = sourceView!.bounds;

                    weakSelf.present(shareAlertController, animated: true, completion: nil);
                } else {
                    if let curDoc = weakSelf.document, curDoc.isPinEnabled() {
                        showAlert(pages)
                    } else {
                        weakSelf.movePagestoTrash(from: doc, pages: pages) { [weak self] (error, _) in
                            if error == nil,let curDoc = self?.document{
                                self?.deletePagesPermanantly(from: curDoc, pages: pages, indexes: indexSet)
                            }
                        }
                    }
                }
            }
        };
    }

    func movePagestoTrash(from doc:FTDocumentProtocol,  pages: NSSet, completion: @escaping (Error?, FTShelfItemProtocol?) -> ()) {
        self.showLoading(withMessage: NSLocalizedString("Deleting", comment: "Deleting"));
        let copiedPages = pages.allObjects as! [FTPageProtocol]
        let pagesToCopy = copiedPages.sorted(by: { (p1, p2) -> Bool in
            return (p1.pageIndex() < p2.pageIndex())
        });


        let info = FTDocumentInputInfo();

        info.rootViewController = self;
        info.overlayStyle = FTCoverStyle.clearWhite
        info.coverTemplateImage = FTPDFExportView.snapshot(forPage: pagesToCopy[0],
                                                           size: portraitCoverSize,
                                                           screenScale: 2.0,
                                                           shouldRenderBackground: true);
        info.isNewBook = true;

        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(FTUtils.getUUID());
        _ = doc.createDocumentAtTemporaryURL(url,
                                             purpose: .trashRecovery,
                                             fromPages: pagesToCopy,
                                             documentInfo: info)

        { (_, error) in
            if(nil == error) {
                let title = doc.URL.deletingPathExtension().lastPathComponent;
                FTNoteshelfDocumentProvider.shared.addDocumentAtURLToTrash(url,
                                                                           title: title)
                { (error, shelfItem) in
                    completion(error, shelfItem)
                }
            } else {
                completion(error, nil)
            }
        }
    }

    func deletePagesPermanantly(from document: FTThumbnailableCollection, pages: NSSet, indexes: NSMutableIndexSet) {
        DispatchQueue.main.async {
            self.document?.deletePages(Array(pages) as! [FTThumbnailable]);
            self.searchResultPages = nil
            self.document?.saveDocument(completionHandler: { [weak self] (_) in
                if let weakSelf = self {
                    weakSelf.hideLoading();
                    weakSelf.delegate?.finderViewController(weakSelf, didSelectRemovePagesWithIndices: IndexSet(indexes))
                    weakSelf.deselectAll();
                    let toastConfig = FTToastConfiguration(title: "Pages Deleted")
                    FTToastHostController.showToast(from: weakSelf, toastConfig: toastConfig)
                }
            })
        }
    }

    func rotateClicked(withSelectedPages pages: NSSet) {
        let loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self.parent!, withText: NSLocalizedString("Rotating", comment: "Rotating..."));

        guard nil != self.document as? FTDocumentProtocol else {
            return;
        }
        if pages.count > 0 {
            self.delegate?.finderViewController(self, didSelectRotatePages: pages)
        }

        loadingIndicator.hide(afterDelay: 1)
    }

    func movePages(withSelectedPages pages: NSSet) {
        guard let doc = self.document as? FTDocumentProtocol else {
            return;
        }
        FTNotebookUtils.checkIfAudioIsNotPlaying(forDocument: doc, InAnyOf: pages,
                                                 alertMessage: "AudioRecoring_Progress_Message".localized,
                                                 onViewController: self)
        { [weak self] (success) in
            if success {
                self?.moveClicked();
                let thumbNailPages = Array(pages) as! [FTThumbnailable]
                self?.updatedItem = thumbNailPages
            }
        }
    }

    func tagPages(withSelectedPages pages: NSSet, targetView: UIView) {
        let pages = ((pages.count > 0) ? pages : NSSet(array: self.filteredPages)) as Set<NSObject> as NSSet
        contextMenuActivePages = pages
        self.delegate?.finderViewController(self, didSelectTag: pages, from: targetView)
    }

    func indexForSelectedItem(_ thumbNailPage: FTThumbnailable) -> IndexPath? {
        if self.filteredPages.count > 0 {
            let rows = self.collectionView.numberOfItems(inSection: 0);
            if let index = self.filteredPages.index(where: {$0.uuid == thumbNailPage.uuid}), index < rows {
                if index < self.filteredPages.count {
                    return IndexPath.init(item: index, section: 0)
                }
            }
        }
        return nil
    }

    func performContextMenuOperation(_ menuOperation: FTFinderContextMenuOperation,
                                     indexPath: IndexPath) {
        let pageItem = self.filteredPages[indexPath.item]

        var itemSet:NSSet
#if targetEnvironment(macCatalyst)
        if self.mode == .none {
            itemSet = NSSet(array: [pageItem])
        } else {
            itemSet = self.selectedPages
        }
#else
        itemSet = NSSet(array: [pageItem])
#endif

        self.contextMenuActivePages = itemSet
        FTFinderEventTracker.trackFinderEvent(with: menuOperation.eventTrackdescription, params: ["location": currentFinderLocation()])
        var targetView: UIView? = self.collectionView

        if self.selectedSegment == .bookmark {
            if let cell = self.collectionView?.cellForItem(at: indexPath) as? FTBookmarkCollectionViewCell {
                targetView = cell.contentView
            }
        } else {
            if let cell = self.collectionView?.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell {
                targetView = cell.contentView
            }
        }

        switch menuOperation {
        case .copyPages:
            self.copyClicked(withSelectedPages: itemSet)
        case .pastePages:
            self.delegate?.finderViewController(self, pastePagesAtIndex: pageItem.pageIndex() + 1)
        case .insertAbove:
            if let selectedPage = pageItem as? FTPageProtocol {
                let task = startBackgroundTask();
                DispatchQueue.main.async {
                    self.listenToPageAddChange();
                    self.delegate?.finderViewController(self, didSelectInsertAboveForPage: selectedPage);
                    endBackgroundTask(task);
                }
            }
        case .insertBelow:
            if let selectedPage = pageItem as? FTPageProtocol {
                let task = startBackgroundTask();
                DispatchQueue.main.async {
                    self.listenToPageAddChange();
                    self.delegate?.finderViewController(self, didSelectInsertBelowForPage: selectedPage);
                    endBackgroundTask(task);
                }
            }
        case .duplicatePages:
            guard let doc = self.document as? FTDocumentProtocol else {
                return;
            }
            FTNotebookUtils.checkIfAudioIsNotPlaying(forDocument: doc, InAnyOf: itemSet,
                                                     alertMessage: "AudioRecoring_Progress_Message".localized,
                                                     onViewController: self)
            { [weak self] (success) in
                if success {
                    self?.duplicateClicked(withSelectedPages: itemSet)
                }
            }
        case .rotatePages:
            self.rotateClicked(withSelectedPages: itemSet)
        case .tagPages:
            if let trView = targetView {
                tagPages(withSelectedPages: itemSet, targetView: trView)
            }
        case .movePages:
            movePages(withSelectedPages: itemSet)
        case .sharePages:
            if let trView = targetView {
                shareClicked(withSelectedPages: itemSet)
            }
        case .deletePages:
            self.deleteClicked(withSelectedPages: itemSet, shouldShowAlert: false)
        case .bookmark:
            if let selectedPage = pageItem as? FTPageProtocol, let trView = targetView {
                FTBookmarkViewController.showBookmarkController(fromSourceView: trView, onController: self, pages: [selectedPage])
            }
        }
    }

    //MARK:- Show/HideLoading
    func showLoading(withMessage message: String) {
        self.view.window?.isUserInteractionEnabled = false;
        if !self.activityIndicatorViewLoading.isAnimating {
            self.activityIndicatorViewLoading.startAnimating();
        }
        self.labelLoading.style = FTLabelStyle.style4.rawValue;
        self.labelLoading.styleText = message;
        self.shadowView.alpha = 0;
        self.shadowView.isHidden = false;
        self.viewLoading.alpha = 0;
        self.viewLoading.isHidden = false;
        UIView.animate(withDuration: 0.3, animations: {
            self.viewLoading.alpha = 1;
            self.shadowView.alpha = 1;
        }) ;
    }

    func hideLoading() {
        self.shadowView.isHidden = false;
        self.viewLoading.isHidden = false;
        UIView.animate(withDuration: 0.3, animations: {
            self.shadowView.alpha = 0;
            self.viewLoading.alpha = 0;
            self.activityIndicatorViewLoading.stopAnimating();
            self.view.window?.isUserInteractionEnabled = true;
        }) ;

    }
}

extension FTFinderViewController: FTTagsViewControllerDelegate {

    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void)) {

    }

    func didDismissTags() {
        let items = self.selectedTagItems.values.reversed();
        self.selectedTagItems.removeAll()
        FTShelfTagsUpdateHandler.shared.updateTagsFor(items: items, completion: nil)
    }

    func addTagsViewController(didTapOnBack controller: FTTagsViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func didAddTag(tag: FTTagModel) {
        updateShelfTagItemsFor(tag: tag)
    }

    func didUnSelectTag(tag: FTTagModel) {
        updateShelfTagItemsFor(tag: tag)
    }

    func updateShelfTagItemsFor(tag: FTTagModel) {
        let pages = self.selectedPages.count > 0 ? self.selectedPages : contextMenuActivePages
        if let tagModel = FTTagsProvider.shared.getTagItemFor(tagName: tag.text) {
            if let _pages = pages.allObjects as? [FTThumbnailable], let documentItem = self.delegate?.currentShelfItemInShelfItemsViewController() as? FTDocumentItemProtocol {
                tagModel.updateTagForPages(documentItem: documentItem, pages: _pages) { [weak self] items in
                    guard let self = self else { return }
                    items.forEach { item in
                        if let page = _pages.first(where: {$0.uuid == item.pageUUID}) {
                            self.selectedTagItems[page.uuid] = item
                            (page as? FTNoteshelfPage)?.addTags(tags: item.tags.map({$0.text}))
                        }
                        self.refreshTagPills()
                    }
                }
            }
        }

    }

    private func refreshTagPills() {
        var filteredPages = self.searchResultPages ?? self.documentPages;
        if self.selectedSegment == .bookmark {
            filteredPages = filteredPages.filter{$0.isBookmarked};
        }
        for (index, differentPage) in filteredPages.enumerated() {
            if let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: self.selectedIndexPath?.section ?? 0)) as? FTFinderThumbnailViewCell {
                cell.page = differentPage
                cell.updateTagsPill()
            }
        }
    }
}

extension FTFinderViewController : FTOutlinesViewControllerDelegate {
    func didTapMoreOption(identifier: String) {
        if let option = FTMoreOption(rawValue: identifier) {
            FTFinderEventTracker.trackFinderEvent(with: option.eventDescription(), params: ["location": currentFinderLocation()])
            switch option {
            case .copy:
                self.copyClicked(withSelectedPages: selectedPages)
            case .move:
                self.movePages(withSelectedPages: selectedPages)
            case .bookMark:
                if let trView = moreButton {
                    let pages = selectedPages.allObjects as! [FTPageProtocol]
                    FTBookmarkViewController.showBookmarkController(fromSourceView: trView, onController: self, pages: pages)
                }
            case .tag:
                if  let targetView = moreButton {
                    self.tagPages(withSelectedPages: selectedPages, targetView: targetView)
                }
            case .delete:
                self.deleteClicked(withSelectedPages: selectedPages, shouldShowAlert: true)
            }
        }
    }

    private func flattenMenuElements(_ elements: [UIMenuElement]) -> [UIMenuElement] {
        return elements.flatMap { element -> [UIMenuElement] in
            if let submenu = element as? UIMenu {
                return flattenMenuElements(submenu.children)
            } else {
                return [element]
            }
        }
    }

    func isAllPagesBookMarked() -> Bool  {
        let item = self.selectedPages.filter{return ($0 as? FTThumbnailable)?.isBookmarked ?? false }
        return  item.count == self.selectedPages.count
    }

    func outlinesViewController(didSelectPage selectedPage: FTPageProtocol?) {
        if let page = selectedPage{
            self.delegate?.finderViewController(didSelectPageAtIndex: page.pageIndex())
            FTFinderEventTracker.trackFinderEvent(with: "finder_page_tap", params: ["location": currentFinderLocation()])
        }
    }

    func outlinesViewController(showPlaceHolder: Bool) {
        if showPlaceHolder {
            self.collectionView.backgroundView?.isHidden = false
        }
        createSnapShot()
        refreshSnapShot()
    }

    func scrollToTop() {
        if selectedSegment == .pages {
            let itemIndex = 0
            let items = collectionView.numberOfItems(inSection: 0)
            if itemIndex < items {
                self.collectionView.scrollToItem(at: IndexPath.init(item: itemIndex, section: 0), at: .top, animated: false);
            }
        }
    }
}

struct FTPlaceHolderThumbnail:Hashable {
    var name:String
}

struct FTOutline:Hashable {
    var name:String
}

struct FTBookmarkCell:Hashable {
    var uuid:String
}

#if targetEnvironment(macCatalyst)
extension FTFinderViewController {
    func configureForMac() {
        self.segmentControl?.isHidden = true;
    }

    func showContent(_ type: FTNotebookSidebarMenuType) {
        guard type == .thumbnails || type == .bookmarks || type == .tableOfContents else {
            return;
        }
        if(type == .thumbnails) {
            self.updateSegmentData(for: .thumbnails)
        }
        else if(type == .bookmarks) {
            self.updateSegmentData(for: .bookmark)
        }
        else if(type == .tableOfContents) {
            self.updateSegmentData(for: .outline)
        }
    }
}
#endif

extension FTFinderViewController {
    var documentPages: [FTThumbnailable] {
        return self.document?.documentPages() ?? [FTThumbnailable]()
    }
}

class FTFinderEventTracker: NSObject {
    static func trackFinderEvent(with value: String, params: [String: Any]? = nil) {
        track(value, params: params,screenName: FTScreenNames.finder)
    }
}
