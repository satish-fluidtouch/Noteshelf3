//
//  FTShelfViewController.swift
//  Noteshelf3
//
//  Created by Akshay on 15/06/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//
import FTCommon
import UIKit
import Combine
import MessageUI
import FTTemplatesStore

// TODO: (AK) Rename this later
protocol FTShelfPresentable {
    var prefersStatusBarHidden: Bool { get }
    var isInSearchMode: Bool { get }
    var isInGroupMode: Bool { get }
    var currentShelfViewModel: FTShelfViewModel? { get }
    var shelfItemCollection: FTShelfItemCollection? { get set }
    var groupItemIfExists : FTGroupItemProtocol? { get set }

    var presentedViewController: UIViewController? { get }

    func refreshShelfCollection(setToDefault: Bool,animate: Bool, onCompletion: @escaping () -> Void)

//    func createQuickNoteBook()
//    func createNotebookWithAudio()
//    func createNotebookWithCameraPhoto()
//    func createNotebookWithScannedPhoto()
    func shelfWillMovetoBack()
    func shelfViewDidMovedToFront(with item : FTDocumentItem)
    
    func hideGroup(animate: Bool, onCompletion: (() -> Void)?)
    func showGroup(with shelfItem: FTShelfItemProtocol, animate: Bool)
    func showNotebookAskPasswordIfNeeded(_ shelfItem: FTShelfItemProtocol, animate: Bool, pin: String?, addToRecent: Bool,isQuickCreate: Bool,createWithAudio: Bool, onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?)
    func continueProcessingImport(withOpenDoc openDoc: Bool, withItem item: FTShelfItemProtocol)
    func importItemAndAutoScroll(_ item: FTImportItem, shouldOpen: Bool, completionHandler: ((FTShelfItemProtocol?, Bool) -> Void)?)
//    func shelfItems(_ sortOrder: FTShelfSortOrder, parent: FTGroupItemProtocol?, searchKey: String?, onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void))

}

class FTShelfSplitViewController: UISplitViewController, FTShelfPresentable {
    var selectedTagItems = Dictionary<String, FTShelfTagsItem>();

    let shelfMenuDisplayInfo = FTShelfMenuOverlayInfo();
    
    internal var shelfItemCollection: FTShelfItemCollection? {
        didSet {
            if let shelfItemCollection {
                self.sideMenuController?.upateSideMenuCurrentCollection(shelfItemCollection)
            }
        }
    }
    private var lastSelectedSideBarItemType: FTSideBarItemType = .home
    private var lastSelectedTag: String = ""
    private var isInNonCollectionMode: Bool = false

    var isInSearchMode: Bool = false
    var isInGroupMode: Bool = false
    var groupItemIfExists: FTGroupItemProtocol?
    var sideMenuController: FTSideMenuViewController?
    var detailNavigationController: UINavigationController?

    var restoringToastMessage : String?
    var restorePageToastMessage : String?
    var restoringItems = [FTShelfItemProtocol]()
    private var size: CGSize = .zero

    let allNotesCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
    var globalSearchController: FTGlobalSearchController?
    var currentShelfViewModel: FTShelfViewModel? {
        if let shelfVc = self.detailNavigationController?.topViewController as? FTShelfViewControllerNew {
            return shelfVc.shelfViewModel
        } else if let shelfVc = self.detailNavigationController?.children.last(where: { controller in
            controller is FTShelfViewControllerNew
        }) as? FTShelfViewControllerNew {
            return shelfVc.shelfViewModel
        } else if lastSelectedSideBarItemType == .home, let homeVc = self.detailNavigationController?.children.last(where: { controller in
            controller is FTShelfHomeViewController
        }) as? FTShelfHomeViewController {
            return homeVc.shelfViewModel
        }
        return nil
    }
    
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        super.showDetailViewController(vc, sender: sender)
        if let nav = vc as? UINavigationController {
            nav.delegate = self
        }
    }

    var openingBookInProgress: Bool = false
    var cancellable = Set<AnyCancellable>()
    typealias ImportItems = [FTImportItem]

    var importFileHandler : FTImportFileHandler?
    var shareItems: [FTShelfItemProtocol] = []

    override func viewDidLoad() {
        #if targetEnvironment(macCatalyst)
            self.primaryBackgroundStyle = .sidebar
        #endif
        setControllersToSplitVC()
        setupView()
        self.shelfMenuDisplayInfo.splitController = self;
    }

   override func isAppearingThroughModelScale() {
       (self.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first?.isAppearingThroughModelScale()
    }
    
    private func setControllersToSplitVC(){
        // Primary VC
        guard let primaryViewController = getPrimaryViewController() as? FTSideMenuViewController else {
            return
        }
        self.sideMenuController = primaryViewController
        self.setViewController(primaryViewController, for: UISplitViewController.Column.primary)
        let dropInteraction = UIDropInteraction(delegate: self)
        self.view.addInteraction(dropInteraction)
        /*if UIDevice.current.userInterfaceIdiom == .phone {
            self.setViewController(self.getTabViewController(), for: .compact)
        }*/  // commenting for beta release
    }
    func configureSecondaryController(isInNonCollectionMode:Bool,
                                      lastSelectedContentType: FTSideBarItemType,
                                      lastSelectedTag: String,
                                      lastSelectedCollection collection: FTShelfItemCollection?){
        func setSecondaryVC(_ vc: UIViewController) {
            let navController = UINavigationController(rootViewController: secondaryViewController)
            navController.navigationBar.prefersLargeTitles = true
            self.detailNavigationController = navController;
            self.showDetailViewController(navController, sender: nil);
        }
        let secondaryViewController: UIViewController
        let collectionTypes: [FTSideBarItemType] = [.home,.starred,.unCategorized,.trash,.category,.ns2Category]
        if collectionTypes.contains(where: {$0 == lastSelectedContentType}),let collection {
            self.shelfItemCollection = collection
        } else {
            self.shelfItemCollection = nil
        }
        if isInNonCollectionMode {
            self.lastSelectedSideBarItemType = lastSelectedContentType
            self.isInNonCollectionMode = isInNonCollectionMode
            self.lastSelectedTag = lastSelectedTag
            secondaryViewController =  getViewControllerBasedOn(sideBarItemType: self.lastSelectedSideBarItemType,selectedTag: self.lastSelectedTag)
            setSecondaryVC(secondaryViewController)
        } else if let collection = self.shelfItemCollection {
            secondaryViewController =  getSecondaryViewControllerWith(collection: collection, groupItem: nil)
            setSecondaryVC(secondaryViewController)
        }
    }
    
    private func setupView(){
        self.preferredDisplayMode = .oneBesideSecondary
        self.preferredSplitBehavior = .tile
        #if targetEnvironment(macCatalyst)
        self.displayModeButtonVisibility = .never
        #else
        self.displayModeButtonVisibility = .always
        #endif
        self.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Sidebar width based on orientation and size of screen. In Ipad portrait Regular 2/3 mode we are making sidebar width less into order to accomodate more number of books. Also setting sidebar view grid item size based on width of sidebar
        self.preferredPrimaryColumnWidth = (isInLandscape && self.view.frame.width > 809) ? 320 : 280
        self.sideMenuController?.setSideBarWidthTo(self.preferredPrimaryColumnWidth ==  320 ? 280 : 240)
        #if targetEnvironment(macCatalyst)
        (self.view.toolbar as? FTShelfToolbar)?.toolbarActionDelegate = self
        (self.view.toolbar as? FTShelfToolbar)?.searchActionDelegate = self
        #endif
    }

    func refreshShelfCollection(setToDefault: Bool,animate: Bool, onCompletion: @escaping () -> Void) {
        if setToDefault {
            self.sideMenuController?.upateSideMenuCurrentCollection(FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection);
            self.sideMenuController?.selectSidebarItemWithCollection(FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection)
            if let detailController = self.detailController(), detailController.isKind(of: FTShelfHomeViewController.self) {
                currentShelfViewModel?.reloadShelf() // As home is already active, we are reloading the shelf
            } else {
                self.showHomeView();
            }
            onCompletion()
        }
        else {
            if let currentViewM = self.currentShelfViewModel {
                currentViewM.reloadItems(animate: animate) {
                    onCompletion()
                }
            } else {
                onCompletion()
            }
        }
    }

    func shelfWillMovetoBack() {
        currentShelfViewModel?.shelfWillMovetoBack()
        sideMenuController?.disableUpdatesForSideBar()
    }

    func shelfViewDidMovedToFront(with item : FTDocumentItem) {
         currentShelfViewModel?.shelfViewDidMovedToFront(with: item)
         if let shelfTagsVC = (self.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first as? FTShelfTagsViewController {
             shelfTagsVC.reloadContent()
         } else if let shelfBookmarksVC = (self.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first as? FTShelfBookmarksViewController {
             shelfBookmarksVC.reloadContent()
         }
         sideMenuController?.enableUpdatesForSideBar()
         //Force refresh the UI to update with latest categories.
         sideMenuController?.updateSideMenuItemsCollections()
     }

    func hideGroup(animate: Bool, onCompletion: (() -> Void)?) {
        if UIDevice.current.userInterfaceIdiom == .phone {
                if let tabController = self.viewControllers.first(where: {$0 is FTTabViewController}) as? FTTabViewController {
                    detailNavigationController = tabController.shelfNavigationController
                }
        }
        detailNavigationController?.popViewController(animated: animate, completion: {
            if let group = self.currentShelfViewModel?.groupItem?.parent {
                self.setLastOpenedGroup(group.URL)
            } else {
                self.setLastOpenedGroup(nil)
                self.saveLastSelectedCollection(self.shelfItemCollection)
            }
            if let children = self.currentShelfViewModel?.groupItem?.childrens, children.isEmpty {
                self.hideGroup(animate: false, onCompletion: nil)
            } else {
                self.currentShelfViewModel?.reloadShelf()
                onCompletion?()
            }
        })
    }

    func showGroup(with shelfItem: FTShelfItemProtocol, animate: Bool) {
        self.setLastOpenedGroup(shelfItem.URL)
        var secondaryViewController: FTShelfViewControllerNew?

        if UIDevice.current.userInterfaceIdiom == .phone {
            if let tabController = self.viewControllers.first(where: {$0 is FTTabViewController}) as? FTTabViewController {
                    detailNavigationController = tabController.shelfNavigationController
                secondaryViewController = tabController.getSecondaryViewControllerWith(collection: shelfItem.shelfCollection, groupItem: shelfItem as? FTGroupItemProtocol)
            }
        } else {
            secondaryViewController = getSecondaryViewControllerWith(collection: shelfItem.shelfCollection, groupItem: shelfItem as? FTGroupItemProtocol)
        }

        if shelfItem.shelfCollection == nil {
            let alertVc = UIAlertController(title: "", message: "This Item doesn't exist. It may be deleted from other session", preferredStyle: .alert)
             alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { _ in
                 self.hideGroup(animate: false, onCompletion: nil)
                 return
             }))
             self.present(alertVc, animated: false, completion: nil)
        }
        if let secondaryViewController = secondaryViewController {
            secondaryViewController.title = shelfItem.displayTitle
            if UIDevice.current.userInterfaceIdiom == .phone {
                if let tabController = self.viewControllers.first(where: {$0 is FTTabViewController}) as? FTTabViewController, let searchNavVc = tabController.globalSearchVc?.navigationController {
                    searchNavVc.pushViewController(secondaryViewController, animated: animate)
                }
            } else {
                if let navController = globalSearchController?.navigationController {
                    navController.pushViewController(secondaryViewController, animated: animate)
                } else {
                    detailNavigationController?.pushViewController(secondaryViewController, animated: animate)
                }
            }
        }
    }
    func showCategory(_ shelfCollection: FTShelfItemCollection) {
        self.saveLastSelectedCollection(shelfCollection)
        self.shelfItemCollection = shelfCollection
        self.sideMenuController?.selectSidebarItemWithCollection(shelfCollection)
        let categoryVc = getSecondaryViewControllerWith(collection: shelfCollection, groupItem: nil)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if let tabController = self.viewControllers.first(where: {$0 is FTTabViewController}) as? FTTabViewController, let searchNavVc = tabController.globalSearchVc?.navigationController {
                searchNavVc.pushViewController(categoryVc, animated: true)
            }
        } else {
            if let globalSearchNavVc = self.globalSearchController?.navigationController {
                globalSearchNavVc.pushViewController(categoryVc, animated: true)
            } else {
                detailNavigationController?.pushViewController(categoryVc, animated: true)
            }
        }
    }
    func showNotebookAskPasswordIfNeeded(_ shelfItem: FTShelfItemProtocol, animate: Bool, pin: String?, addToRecent: Bool, isQuickCreate: Bool, createWithAudio: Bool, onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?) {
        self.openNotebookAndAskPasswordIfNeeded(shelfItem,
                                                animate: animate,
                                                presentWithAnimation: false,
                                                pin: pin,
                                                addToRecent: addToRecent,
                                                isQuickCreate: isQuickCreate,
                                                createWithAudio: createWithAudio,
                                                pageIndex: nil,
                                                onCompletion: onCompletion)
    }

    func continueProcessingImport(withOpenDoc openDoc: Bool, withItem item: FTShelfItemProtocol) {
        if openDoc, self.shelfItemCollection?.collectionType != .system, !(item.isPinEnabledForDocument()) {
            self.showNotebookAskPasswordIfNeeded(item, animate: self.isInSearchMode, pin: nil, addToRecent: true, isQuickCreate: false, createWithAudio: false, onCompletion: nil)
        }
    }

    func importItemAndAutoScroll(_ item: FTImportItem, shouldOpen: Bool, completionHandler: ((FTShelfItemProtocol?, Bool) -> Void)?) {
        self.currentShelfViewModel?.removeObserversForShelfItems()
        self.beginImporting(items: [item]) { [weak self] status, shelfItemsList in
            if let item = shelfItemsList.first {
                if status && shouldOpen {
                    if let shelfItemProtocol = shelfItemsList.first {
                        self?.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItemProtocol, isQuickCreated: false)
                    }
                }
                self?.currentShelfViewModel?.addObserversForShelfItems()
                completionHandler?(item, status)
            } else {
                completionHandler?(nil, false)
            }
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
#if !targetEnvironment(macCatalyst)
        // Sidebar width based on orientation and size of screen. In Ipad portrait Regular 2/3 mode we are making sidebar width less into order to accomodate more number of books. Also setting sidebar view grid item size based on width of sidebar
        self.preferredPrimaryColumnWidth = (isInLandscape && (size.width > 809.0)) ? 320 : 280
        self.sideMenuController?.setSideBarWidthTo(self.preferredPrimaryColumnWidth ==  320 ? 280 : 240)

        //For Retaining the display mode on orientation change
        if self.displayMode == .secondaryOnly {
            self.preferredDisplayMode = .secondaryOnly
        } else if self.displayMode == .oneBesideSecondary {
            self.preferredDisplayMode = .oneBesideSecondary
        }
#endif
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
            // Based on orientation and display mode, we are showing the bottom bar with only icons or icons with text.
            updateBottomToolBarCompactStatus()
    }
    private func updateBottomToolBarCompactStatus(){
#if !targetEnvironment(macCatalyst)
        if isInLandscape {
            self.currentShelfViewModel?.showCompactBottombar = (!self.traitCollection.isRegular && self.displayMode == .oneBesideSecondary)
        } else {
            self.currentShelfViewModel?.showCompactBottombar = ((self.displayMode == .oneBesideSecondary && self.traitCollection.isRegular && !isInLandscape) || !self.traitCollection.isRegular)
        }
#endif
    }
}
class FTNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = UIScreen.main.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.appColor(.accent)
    }
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        return self.splitViewController?.traitCollection ?? self.traitCollection
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.navigationBar.tintColor = UIScreen.main.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.appColor(.accent)
        }
    }
}
extension UINavigationController {
     func popViewController(animated: Bool, completion: @escaping ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popViewController(animated: animated)
        CATransaction.commit()
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
}
extension FTShelfSplitViewController {
    private func getTabViewController() -> UIViewController {
        let tabController = FTTabViewController.instantiateFromStroyboard()
        tabController.shelfItemCollection = shelfItemCollection
        tabController.shelfViewModelDelegate = self
        tabController.shelfNewNoteDelegate = self
        tabController.mediaDelegate = self
        tabController.tagsControllerDelagate = self
        tabController.tagsDelegate = self
        tabController.globalSearchDelegate = self
        return tabController
    }
    private func getPrimaryViewController() -> UIViewController {
        let sideBarViewModel = isInNonCollectionMode ? FTSidebarViewModel(selectedSideBarItemType: lastSelectedSideBarItemType,selectedTag: lastSelectedTag) : FTSidebarViewModel(collection:shelfItemCollection)
        sideBarViewModel.dropDelegate = self
        sideBarViewModel.sideBarItemWidth = self.preferredPrimaryColumnWidth ==  320 ? 280 : 240
        let sideMenuController = FTSideMenuViewController(viewModel: sideBarViewModel,shelfDisplayMenu: shelfMenuDisplayInfo)
        sideMenuController.delegate = self
        return sideMenuController
    }
    func getSecondaryViewControllerWith(collection: FTShelfItemCollection, groupItem: FTGroupItemProtocol?) -> FTShelfViewControllerNew {
        let shelfViewModel = FTShelfViewModel(collection: collection , groupItem: groupItem)
        shelfViewModel.delegate = self
        shelfViewModel.tagsControllerDelegate = self
        let detailViewController = FTShelfViewControllerNew(shelfViewModel: shelfViewModel,shelfMenuOverlayInfo: shelfMenuDisplayInfo);
        if groupItem != nil {
            detailViewController.title =  groupItem?.displayTitle ?? ""
        } else {
            detailViewController.title =  collection.displayTitle
        }
        detailViewController.shelfItemCollection = collection
        detailViewController.parentShelfItem = groupItem
        return detailViewController
    }
    func getSecondaryViewControllerForHomeOption() -> FTShelfHomeViewController {
        lastSelectedSideBarItemType = .home
        let shelfViewModel = FTShelfViewModel(sidebarItemType: .home)
//        shelfViewModel.isSidebarOpen = self.displayMode  == .oneBesideSecondary
        shelfViewModel.delegate = self
        shelfViewModel.tagsControllerDelegate = self
        let detailViewController = FTShelfHomeViewController(shelfViewModel: shelfViewModel, shelfMenuOverlayInfo: shelfMenuDisplayInfo);
        detailViewController.title = (self.currentShelfViewModel?.shouldShowGetStartedInfo ?? false) ? "" : "sidebar.topSection.home".localized
        detailViewController.shelfViewModel = shelfViewModel
        return detailViewController
    }
    

#if targetEnvironment(macCatalyst)
    
    func  openNotebookAndAskPasswordIfNeeded(_ shelfItem: FTShelfItemProtocol,
                                             animate: Bool,
                                             presentWithAnimation: Bool,
                                             pin: String?,
                                             addToRecent: Bool,
                                             isQuickCreate: Bool,
                                             createWithAudio: Bool,
                                             pageIndex: Int?,
                                             onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?) {

        let downloadStatus = shelfItem.URL.downloadStatus();
        if downloadStatus != .downloaded {
            if downloadStatus == .notDownloaded {
                NotificationCenter.default.post(name: NSNotification.Name.shelfItemRemoveLoader, object: shelfItem, userInfo: nil)
                self.downloadShelfItem(shelfItem)
            }
            onCompletion?(nil, false)
            return
        }

        func openDoc(_ pin: String?) {
            openItemInNewWindow(shelfItem, pageIndex: nil, docPin: pin, createWithAudio: createWithAudio, isQuickCreate: isQuickCreate)
            onCompletion?(nil,true);
        }

        if let documentPin = pin {
            openDoc(documentPin)
        }
        else{
            self.view.isUserInteractionEnabled = false
            self.openingBookInProgress = true
            FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                         onviewController: self) { [weak self] (pin, success, cancelled) in
                self?.view.isUserInteractionEnabled = true
                self?.openingBookInProgress = false
                NotificationCenter.default.post(name: NSNotification.Name.shelfItemRemoveLoader, object: shelfItem, userInfo: nil)
                if(success) {
                    openDoc(pin)
                } else if cancelled {
                    onCompletion?(nil,false);
                } else  {
                    self?.handleNotebookOpenError(for: shelfItem, error: FTDocumentOpenErrorCode.error(.invalidPin));
                    onCompletion?(nil,false);
                }
            }
        }
    }
#else
    func openNotebookAndAskPasswordIfNeeded(_ shelfItem: FTShelfItemProtocol,
                                            animate: Bool,
                                            presentWithAnimation: Bool,
                                            pin: String?,
                                            addToRecent: Bool,
                                            isQuickCreate: Bool,
                                            createWithAudio: Bool,
                                            pageIndex: Int?,
                                            onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?) {

        let notebookName = shelfItem.displayTitle
        FTCLSLog("Book: \(notebookName): Show")
        self.view.isUserInteractionEnabled = false

        self.openingBookInProgress = true
        FTDocumentValidator.openNoteshelfDocument(for: shelfItem,
                                                  pin: pin,
                                                  onViewController: self)
        { [weak self] (openedDocument, error,token) in
            if let inError = error {
                self?.view.isUserInteractionEnabled = true
                self?.openingBookInProgress = false
                NotificationCenter.default.post(name: NSNotification.Name.shelfItemRemoveLoader, object: shelfItem, userInfo: nil)
                if(inError.isConflictError) {
                    FTCLSLog("Book: \(notebookName): Conflict")
                    if let conflictedDocument = openedDocument, let item = shelfItem as? FTDocumentItemProtocol {
                        let documentConflictScreen = FTCloudDocumentConflictScreen.conflictViewControllerForDocument(conflictedDocument, documentItem:item)
                        self?.present(documentConflictScreen, animated: true, completion: nil)
                    }
                }
                else if(inError.isNotDownloadedError) {
                    self?.downloadShelfItem(shelfItem)
                }
                else if inError.isNotExistError {
                    runInMainThread {
                        self?.showAlertForError(inError as NSError)
                    }
                }
                else if(!inError.isInvalidPinError) {
                    FTCLSLog("Book: \(notebookName): Open failed invalid Pin")
                        self?.handleNotebookOpenError(for: shelfItem, error: error as NSError?)
                }
                onCompletion?(nil, false)
                return
            }

            guard let notebookToOpen = openedDocument, let doc = notebookToOpen as? FTNoteshelfDocument, error == nil else {
                self?.view.isUserInteractionEnabled = true
                self?.openingBookInProgress = false
                NotificationCenter.default.post(name: NSNotification.Name.shelfItemRemoveLoader, object: shelfItem, userInfo: nil)
                onCompletion?(nil, false)
                return
            }
            let shouldInsertCover = doc.propertyInfoPlist()?.object(forKey: INSERTCOVER) as? Bool ?? false
            if shouldInsertCover {
                doc.insertCoverForPasswordProtectedBooks { success, error in
                    doc.propertyInfoPlist()?.setObject(false, forKey: INSERTCOVER)
                    processDocumentOpen()
                }
            } else {
                processDocumentOpen()
            }
            
            func processDocumentOpen() {
                var shouldAnimate = animate

                if self?.applicationState() != .active {
                    shouldAnimate = false
                }

                var docInfo = FTDocumentOpenInfo(document: notebookToOpen, shelfItem: shelfItem, index: pageIndex ?? -1)
                if let userActivity = self?.view.window?.windowScene?.userActivity{
                    if let pageIndex = userActivity.currentPageIndex {
                        docInfo = FTDocumentOpenInfo(document: notebookToOpen, shelfItem: shelfItem, index: pageIndex)
                        userActivity.currentPageIndex = nil //Clear it as we don't need this anywhere else
                    }
                }
                docInfo.documentOpenToken = token ?? FTDocumentOpenToken()

                if let rootController = self?.parent as? FTRootViewController {
                    rootController.switchToPDFViewer(docInfo, animate: shouldAnimate ,onCompletion: {
                        self?.openingBookInProgress = false
                        self?.view.isUserInteractionEnabled = true
                        if(addToRecent) {
                            FTNoteshelfDocumentProvider.shared.addShelfItemToList(shelfItem, mode: .recent)
                        }
                        NotificationCenter.default.post(name: NSNotification.Name.shelfItemRemoveLoader, object: shelfItem, userInfo: nil)
                        notebookToOpen.isJustCreatedWithQuickNote = isQuickCreate
                        onCompletion?(notebookToOpen, true)
                    })
                }
            }
        }
    }
#endif
    private func downloadShelfItem(_ shelfItem: FTShelfItemProtocol) {
        do {
            if(CloudBookDownloadDebuggerLog) {
                FTCLSLog("Book: \(shelfItem.displayTitle): Download Requested")
            }
            try FileManager().startDownloadingUbiquitousItem(at: shelfItem.URL)
        }
        catch let nserror as NSError {
            FTCLSLog("Book: \(shelfItem.displayTitle): Download Failed :\(nserror.description)")
            FTLogError("Notebook download failed", attributes: nserror.userInfo)
        }
    }
    func handleNotebookOpenError(for shelfItem: FTShelfItemProtocol, error: NSError?) {
        FTLogError("Open Notebook Failed", attributes: error?.userInfo);
        runInMainThread {
            if(nil != error) {
                error!.showAlert(from: self)
                return;
            }
            else {
                UIAlertController.showSupportDialog(with: NSLocalizedString("Support", comment: "Support"), message: NSLocalizedString("DocumentSupport", comment: "Document has some problem..."), from: self, supportHandler: { [weak self] in
                    if let weakSelf = self {
                        let contentgenerator = FTNBKContentGenerator()
                        let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: weakSelf, withText:"");
                        runInMainThread {
                            let itemToExport = FTItemToExport.init(shelfItem: shelfItem);
                            contentgenerator.generateSupportContent(forItem: itemToExport, andCompletionHandler: { (item, error, _) -> (Void) in
                                if(error == nil) {
                                    loadingIndicatorViewController.hide()
                                    weakSelf.sendDocumentToSupportTeam(shelfItem, andFilePath: item!.representedObject as! String)
                                }
                                else
                                {
                                    loadingIndicatorViewController.hide {
                                        UIAlertController.showAlert(withTitle: "Noteshelf", message: "Error in generating file, please try again", from: weakSelf, withCompletionHandler: {
                                        });
                                    }
                                }
                            });
                        }
                    }
                });
            }
        }
    }
}
extension FTShelfSplitViewController: FTCategoryDropDelegate {
    func moveDraggedShelfItem(_ item : FTShelfItemProtocol,
                              toCollection collection: FTShelfItemCollection,
                              onCompletion: @escaping (NSError?, [FTShelfItemProtocol]) -> Void){
        collection.moveShelfItems([item], toGroup: nil, toCollection: collection, onCompletion: { error, shelfItems in
            onCompletion(error, shelfItems)
        })
    }
    func endDragAndDropOperation() {
        self.currentShelfViewModel?.endDragAndDropOperation()
    }
}

// MARK: Media Content Delegate

extension FTShelfSplitViewController: FTShelfMediaDelegate, FTShelfTagsPageDelegate, FTShelfBookmarksPageDelegate {
    func openNotebook(shelfItem: FTShelfItemProtocol, page: Int) {
        self.openNotebook(shelfItem, shelfItemDetails: nil, animate: false, isQuickCreate: false, pageIndex: page)
    }

    func openNotebook(shelfItem: FTDocumentItemProtocol, page: Int) {
        self.openNotebook(shelfItem, shelfItemDetails: nil, animate: false, isQuickCreate: false, pageIndex: page)
    }
}
extension FTShelfSplitViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        print("inside performDrop of split view")
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        self.currentShelfViewModel?.endDragAndDropOperation()
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        self.currentShelfViewModel?.endDragAndDropOperation()
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .move)
    }
}
extension FTShelfSplitViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController){
        // Incase of sharing, we are presenting it as formsheet so on dismiss of it, restoring shelf to normal state
        let presentedController = presentationController.presentedViewController.children.first
        if currentShelfViewModel?.mode == .selection && presentedController is UIActivityViewController {
            currentShelfViewModel?.resetShelfModeTo(.normal)
            self.shareItems.removeAll()
        }
    }
}
@nonobjc extension UIViewController {
    func add(_ child: UIViewController, frame: CGRect) {
        addChild(child)
        child.view.frame = frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
extension FTShelfSplitViewController: UISplitViewControllerDelegate {
#if !targetEnvironment(macCatalyst)
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        //NotificationCenter.default.post(name: NSNotification.Name("SplitDisplayModeChangeNotification"), object: nil, userInfo: ["splitDisplayMode":displayMode.rawValue])
        self.currentShelfViewModel?.isSidebarOpen = displayMode == .oneBesideSecondary
        self.currentShelfViewModel?.showCompactBottombar = !self.traitCollection.isRegular || (displayMode == .oneBesideSecondary && self.traitCollection.isRegular && !isInLandscape) ||  (displayMode == .oneBesideSecondary && isInLandscape && self.view.frame.width <= 809)
    }
#endif
}
extension FTShelfSplitViewController {
    //MARK:- Noteshelf Support Handling
    func sendDocumentToSupportTeam(_ shelfItem: FTShelfItemProtocol, andFilePath filePath:String){
        if MFMailComposeViewController.canSendMail() {
            let mailComposeViewController = MFMailComposeViewController();
            mailComposeViewController.modalPresentationStyle = .formSheet;
            mailComposeViewController.mailComposeDelegate = self;
            mailComposeViewController.setSubject(NSLocalizedString("Support", comment: "Support"));
            mailComposeViewController.addSupportMailID();
            mailComposeViewController.setMessageBody(NSLocalizedString("DocumentSupportDisclaimer", comment: "DISCLAIMER (Read Carefully..."), isHTML: false)

            if let notebookData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                mailComposeViewController.addAttachmentData(notebookData, mimeType: "application/ns2", fileName: shelfItem.displayTitle.appendingFormat(".%@", nsBookExtension));
            }

            if let userData = FTZenDeskManager.customFieldsString().data(using: String.Encoding.utf8) {
                mailComposeViewController.addAttachmentData(userData, mimeType: "application/txt", fileName: "Additional Info");
            }

            self.present(mailComposeViewController, animated: true, completion: nil);
        }
        else {
            UIAlertController.showAlert(withTitle: "", message: "EmailNotSetup".localized, from: self,withCompletionHandler: nil);
        }
    }
}
extension FTShelfSplitViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?){
        controller.dismiss(animated: true, completion: nil)
    }
}
