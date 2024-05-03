//
//  FTRootViewController.swift
//  Noteshelf
//
//  Created by Amar on 12/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import SafariServices
import FTDocumentFramework
import FTNewNotebook
import CoreSpotlight

protocol FTOpenCloseDocumentProtocol : NSObjectProtocol {
    func openRecentItem(shelfItemManagedObject: FTDocumentItemWrapperObject, addToRecent: Bool)
    func closeDocument(shelfItemManagedObject:FTDocumentItemWrapperObject, animate: Bool, onCompletion : (() -> Void)?)
}

// iCloud Retry
private var currentRetryCount = 1
private var maxRetryCount = 5

class FTRootViewController: UIViewController, FTIntentHandlingProtocol,FTViewControllerSupportsScene {

    var addedObserverOnScene: Bool = false;

    weak var docuemntViewController : FTDocumentViewController?;
    fileprivate var rootContentViewController: FTShelfPresentable?;
    fileprivate var isFirstTime = true;
    fileprivate var isOpeningDocument = false;

    fileprivate var isImportInProgress = false
    fileprivate lazy var importItemsQueue = [FTImportItem]()
    fileprivate weak var launchScreenController : UIViewController?;

    fileprivate weak var pencilInteraction : NSObject?;

    private var importController : FTImportedDocViewController?
    private weak var noteBookSplitController: FTNoteBookSplitViewController?
    var contentView : UIView!;

    private var keyValueObserver: NSKeyValueObservation?;
    private weak var themeNotificationObserver: NSObjectProtocol?;

    override func isAppearingThroughModelScale() {
         (self.rootContentViewController as? FTShelfSplitViewController)?.isAppearingThroughModelScale()
     }

    // MARK: - Life cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        FTImportStorageManager.clearImportFilesIfNeeded();
        FTDocumentsSpotlightIndexManager.shared.configure();
        
        self.contentView = UIView.init(frame: self.view.bounds);
        self.contentView.backgroundColor = UIColor.clear;

        self.contentView.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleLeftMargin];
        self.view.addSubview(self.contentView);

        if(self.isFirstTime) {
            FTCLSLog("Launch Screen Added");
            let launchInstanceStoryboard = UIStoryboard(name: "Launch Screen", bundle: nil);
            let viewController = launchInstanceStoryboard.instantiateInitialViewController();
            self.addChild(viewController!);
            self.view.addSubview(viewController!.view);
            self.addConstraintForView(viewController!.view, withrespectTo: self.contentView)
            self.launchScreenController = viewController;
            if let activityView = viewController?.view.viewWithTag(120) as? UIActivityIndicatorView {
                activityView.isHidden = false;
                activityView.startAnimating();
            }
        }

        DispatchQueue.main.async {
            self.updateProviderIfNeeded();
        }
        FTUserDefaults.defaults().addObserver(self, forKeyPath: "iCloudOn", options: .new, context: nil);

        self.themeNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.FTShelfThemeDidChange, object: nil, queue: nil) { [weak self] _ in
            runInMainThread {
                self?.themeDidChange();
            }
        }
        if #available(iOS 12.1, *) {
            self.addPencilInteractionDelegate();
        }
        
        self.keyValueObserver = FTUserDefaults.defaults().observe(\.showStatusBar, options: [.new]) { [weak self] (userdefaults, change) in
            self?.refreshStatusBarAppearnce();
        }
    }

    fileprivate func themeDidChange() {
        self.refreshStatusBarAppearnce();
    }

    deinit {
#if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
#endif
        FTUserDefaults.defaults().removeObserver(self, forKeyPath: "iCloudOn");
        //FTWatchRecordingStorageManager.shared.unregisterObserver(self)
        if #available(iOS 12.1, *) {
            if let interaction = self.pencilInteraction as? UIPencilInteraction {
                self.view.removeInteraction(interaction);
                self.pencilInteraction = nil;
            }
        }
        if let _themeObserver = self.themeNotificationObserver {
            NotificationCenter.default.removeObserver(_themeObserver);
        }
        
        self.keyValueObserver?.invalidate();
        self.keyValueObserver = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.themeDidChange();
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        if FTWhatsNewManger.canShowWelcomeScreen(onViewController: self) {
            FTWelcomeScreenViewController.showWelcome(presenterController: self, onDismiss: {
                [weak self] in
                self?.addShelfToolbar();
                self?.updateProvider({
                });
            });
            self.refreshStatusBarAppearnce();
            track("Welcome_Viewed", screenName: FTScreenNames.welcomeScreen)
        }
        else {
            self.addShelfToolbar();
        }
    }

    override var prefersStatusBarHidden: Bool {
        if let splitVC = self.noteBookSplitController,
           !(splitVC.isBeingDismissed || splitVC.isBeingPresented) {
            return splitVC.prefersStatusBarHidden;
        }
        else if self.presentedViewController is FTWelcomeScreenViewController {
            return self.presentedViewController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
        }
        return super.prefersStatusBarHidden;
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        if let splitVC = self.noteBookSplitController,
           !(splitVC.isBeingDismissed || splitVC.isBeingPresented) {
            return true;
        }
        return super.prefersHomeIndicatorAutoHidden;
    }

    // MARK: - Switch Shelf/PDF Render -
    private func switchToShelf(_ shelfItem: FTDocumentItemWrapperObject?,
                               documentViewController: FTDocumentViewController?,
                               animate anim: Bool,
                               onCompletion : (() -> Void)?)
    {
        if let item = shelfItem?.documentItem as? FTDocumentItem {
            self.rootContentViewController?.shelfViewDidMovedToFront(with: item);
        }
        let animate : Bool = anim
        self.view.isUserInteractionEnabled = false;
        //added below code to resolve a crash related to EAGLCOntext setcurrentContext. This may resolve the issue.
        FTENPublishManager.shared.currentOpenedDocumentUUID = nil;
        self.setLastOpenedDocument(nil);

        //Cloud Backup
        ////
        if(nil != shelfItem) {
            let autobackupItem = FTAutoBackupItem(URL: shelfItem!.URL, documentUUID: shelfItem!.documentUUID);
            FTCloudBackUpManager.shared.startPublish();
        }

        func finalizeBlock() {
            self.view.isUserInteractionEnabled = true;
            self.refreshStatusBarAppearnce();
            onCompletion?();
        }

        func removeDocumentViewController() {
            if(nil != documentViewController) {
                noteBookSplitController?.willMove(toParent: nil);
                noteBookSplitController?.view.removeFromSuperview();
                noteBookSplitController?.removeFromParent();
                self.noteBookSplitController = nil
            }
            self.refreshStatusBarAppearnce();
            self.view.layoutIfNeeded();
        }

        let closeWithoutAnim : () -> () = {
            removeDocumentViewController();
            finalizeBlock()
        }

        if self.rootContentViewController?.isInSearchMode == true { //To ignore maintaining the book scroll position while search is active
            closeWithoutAnim();
            return
        }
        
        self.closeNotebookSplitController(splitVC: self.noteBookSplitController,
                                               animate: animate,
                                               onCompletion: {
            self.noteBookSplitController = nil;
            finalizeBlock();
        })
    }

    
    fileprivate func deskController(docInfo: FTDocumentOpenInfo) -> FTNoteBookSplitViewController {
        // Detail Controller
        let splitVC = FTNoteBookSplitViewController.viewController(docInfo, bounds: self.contentView.bounds, delegate: self);
        self.docuemntViewController = splitVC.documentViewController;
        
        splitVC.view.frame = self.contentView.bounds;
        splitVC.view.layoutIfNeeded();
        
        return splitVC;
    }

    // MARK: - Provider update -
    private weak var localAppActieObserver: NSObjectProtocol?
    fileprivate func updateProviderIfNeeded() {
        if(UserDefaults.standard.bool(forKey: WelcomeScreenViewed)
           || (!UserDefaults.standard.bool(forKey: WelcomeScreenViewed)
               && UserDefaults.standard.double(forKey: WelcomeScreenReminderTime) > 0)) {
            if UIApplication.shared.applicationState != .active {
                FTCLSLog("Update Provider - App is not active");
                localAppActieObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main, using: { _ in
                    if let _observer = self.localAppActieObserver {
                        NotificationCenter.default.removeObserver(_observer)
                    }
                    FTCLSLog("Update Provider - App active");
                    self.updateProviderIfNeeded();
                })
                return;
            }
            FTCLSLog("Update Provider - Start");
            self.scheduleLaunchWaitError()
            self.updateProvider({
                self.cancelLaunchWaitError()
                FTCLSLog("Update Provider - End");
                FTBetaAlertHandler.showiOS13BetaAlertIfNeeded(onViewController: self);
                FTOneDriveAlertHandler.showOneDriveAuthenticationAlertIfNeeded(self)
            });
        }
    }
    
    fileprivate func updateProvider(_ onCompletion :(() -> (Void))?)
    {
        self._updateProvider { _ in
            onCompletion?();
        }
    }

    fileprivate func _updateProvider(_ onCompletion :((Bool) -> (Void))?)
    {
        FTNoteshelfDocumentProvider.shared.updateProviderIfRequired { isUpdated in
            if(isUpdated || nil == self.rootContentViewController) {
                FTMobileCommunicationManager.shared.startWatchSession()
                let collectionName = self.lastSelectedCollectionName();
                FTCLSLog("Fetching Collection");
                self.shelfCollection(title: collectionName, pickDefault: false, onCompeltion: { collectionToShow in
                    FTCLSLog("Collection Fetched");
                    NotificationCenter.default.post(name: .didChangeUnfiledCategoryLocation, object: nil);
                    if let isInNonCollectionMode = self.isInNonCollectionMode(),
                       isInNonCollectionMode {
                        let lastSelectedContentTypeRawString = (self.lastSelectedNonCollectionType() ?? "home")
                        self.showShelf(isInNonCollectionMode: isInNonCollectionMode,
                                       lastSelectedSideBarContentType: FTSideBarItemType(rawValue: lastSelectedContentTypeRawString) ?? .home,
                                       lastSelectedTag: (self.lastSelectedTag() ?? ""))
                    } else if collectionName == collectionToShow?.title, let collection = collectionToShow {
                        self.showShelf(updateWithLastSelected: collection);
                    } else {
                        // if collection from user activity is nil we are showing "Home" now instead of "All Notes" collection
                        self.showShelf(isInNonCollectionMode: true,
                                       lastSelectedSideBarContentType: .home,
                                       lastSelectedTag: "")
                    }
                    self.showIcloudMessage();
                    onCompletion?(true);
                });
            }
            else {
                onCompletion?(false);
            }
        }
    }

    fileprivate func showIcloudMessage() {
        let messageType = FTNSiCloudManager.shared().messageTypeToShow;
        weak var weakSelf = self;
        switch messageType {
        case .kiCloudStartUsingMessageAction:
            let controller = UIAlertController(title: NSLocalizedString("iCloudAvailable", comment: "iCloudAvailable"), message: NSLocalizedString("iCloudAvailableMessage", comment: "Automatically store your documents.."), preferredStyle: UIAlertController.Style.alert);
            let laterAction = UIAlertAction(title: NSLocalizedString("Later", comment: "Later"), style: .cancel, handler: { _ in
                weakSelf?.refreshShelfCollection(setToDefault:false, animate: false,onCompletion: nil)
            });
            laterAction.accessibilityLabel = "iCloudLater";
            controller.addAction(laterAction);
            let useIcloudAction = UIAlertAction(title: NSLocalizedString("UseiCloud", comment: "Use iCloud"), style: .default, handler: { _ in
                FTNSiCloudManager.shared().setiCloud(on: true);
                weakSelf?.updateProvider(nil);
            });
            controller.addAction(useIcloudAction);

            self.present(controller, animated: true, completion: nil);
        case .kiCloudNotAvailableMessageAction:
            let controller = UIAlertController(title: NSLocalizedString("Error", comment: "iCloudUserTurnedOff"), message: NSLocalizedString("icloud.sync.issue.message", comment: "NotUsingiCloudMessage"), preferredStyle: UIAlertController.Style.alert);
            controller.addAction(UIAlertAction(title: "retry".localized, style: UIAlertAction.Style.default, handler: { _ in
                track("icloud_notavailable_retry", params: ["count": "\(currentRetryCount)"])
                weakSelf?.retryiCloudUnavaialbility()
            }))
            controller.addAction(UIAlertAction(title: "LearnMore".localized, style: UIAlertAction.Style.cancel, handler: { _ in
                track("icloud_notavailable_learn", params: ["count": "\(currentRetryCount)"])
                weakSelf?.showiCloudHelp()
            }))
            track("icloud_notavailable")
            self.present(controller, animated: true, completion: nil);
        case .kiCloudUserTurnedOffAction:
            let controller = UIAlertController(title: NSLocalizedString("iCloudUserTurnedOff", comment: "iCloudUserTurnedOff"), message: NSLocalizedString("iCloudUserTurnedOffMessage", comment: "iCloudUserTurnedOffMessage"), preferredStyle: UIAlertController.Style.alert);
            let continueAction = UIAlertAction(title: NSLocalizedString("ContinueUsingICloud", comment: "ContinueUKeep using iCloudsingICloud"), style: .cancel, handler: { _ in
                FTNSiCloudManager.shared().setiCloud(on: true);
                weakSelf?.updateProvider(nil);
            });
            controller.addAction(continueAction);
            let keepLocalAction = UIAlertAction(title: NSLocalizedString("KeepALocalCopy", comment: "Keep on my iPad"), style: .default, handler: { _ in
                self.view.isUserInteractionEnabled = false;

                let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Moving", comment: "Moving..."));
                DispatchQueue.main.async {
                    FTNoteshelfDocumentProvider.shared.moveContentsFromCloudToLocal(onCompletion: { (_) in
                        FTURLReadThumbnailManager.sharedInstance.clearStoredThumbnailCache()
                        FTNoteshelfDocumentProvider.shared.refreshCurrentShelfCollection {
                            weakSelf?.shelfCollection(title: nil, pickDefault: false, onCompeltion: { (collection) in
                                FTNoteshelfDocumentProvider.shared.resetProviderCache()
                                (weakSelf?.rootContentViewController as? FTShelfSplitViewController)?.updateSidebarCollections()
                                weakSelf?.rootContentViewController?.currentShelfViewModel?.collection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection;
                                weakSelf?.refreshShelfCollection(setToDefault: true, animate: true) {
                                    loadingIndicatorViewController.hide();
                                    self.view.isUserInteractionEnabled = true;
                                }
                            });
                        }
                    });
                }
            });
            controller.addAction(keepLocalAction);

            let deleteFromLocal = UIAlertAction.init(title: NSLocalizedString("DeleteALocalCopy",comment:"Delete on my iPad"), style: .destructive, handler: { (_) in
                FTURLReadThumbnailManager.sharedInstance.clearStoredThumbnailCache()
                FTNoteshelfDocumentProvider.shared.resetProviderCache();
                (weakSelf?.rootContentViewController as? FTShelfSplitViewController)?.updateSidebarCollections()
                weakSelf?.refreshShelfCollection(setToDefault: false, animate: true,onCompletion: nil);
            });
            controller.addAction(deleteFromLocal);

            self.present(controller, animated: true, completion: nil);

        case .kiCloudUserTurnedOnAction:
            //move from local to icloud
            self.view.isUserInteractionEnabled = false;

            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Moving", comment: "Moving..."));
            DispatchQueue.main.async {
                FTNoteshelfDocumentProvider.shared.moveContentsFromLocalToiCloud(onCompletion: { (_, error) in                    (error as NSError?)?.showAlert(from: self.view.window?.visibleViewController)
                    FTURLReadThumbnailManager.sharedInstance.clearStoredThumbnailCache()
                    FTNSiCloudManager.shared().setiCloudWas(on: true);
                    FTNoteshelfDocumentProvider.shared.refreshCurrentShelfCollection {
                        weakSelf?.shelfCollection(title: nil, pickDefault: false, onCompeltion: { (collection) in
                            weakSelf?.rootContentViewController?.currentShelfViewModel?.collection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection;
                            weakSelf?.refreshShelfCollection(setToDefault: true, animate: true) {
                                loadingIndicatorViewController.hide();
                                self.view.isUserInteractionEnabled = true;
                            }
                        });
                    }
                });
            };
        default:
            self.refreshShelfCollection(setToDefault: false, animate: false, onCompletion: nil)
        }
    }

    fileprivate func refreshShelfCollection(setToDefault: Bool,animate: Bool, onCompletion : (() -> Void)?) {
        self.rootContentViewController?.refreshShelfCollection(setToDefault: setToDefault,animate: animate, onCompletion: { [weak self] in
            self?.maintainPreviousLaunchStateIfNeeded();
            onCompletion?()
        })
    }

    fileprivate func maintainPreviousLaunchStateIfNeeded() {
        if self.isFirstTime {
            FTCLSLog("Maintaining Previous State");
            self.isFirstTime = false;
            self.setupSafeModeIfNeeded()
            if self.userActivity?.activityType == CSSearchableItemActionType,
               let shelfItemUUID = self.userActivity?.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                FTCLSLog("Opening Book from spotlight");
                self.openShelfItem(spotLightHash: shelfItemUUID);
            }
            else if let document = self.lastOpenedDocument() {
                FTCLSLog("Opening last opened book");
                self.showLastOpenedDocument(relativePath: document, animate: false);
            }
            else if let isInNonCollectionMode = self.isInNonCollectionMode(),
                    !isInNonCollectionMode,let lastOpenedGroup = self.userActivity?.lastOpenedGroup {
                self.getShelfItemDetails(relativePath: lastOpenedGroup,
                                         igrnoreIfNotDownloaded: true)
                { [weak self] (_, groupItem, _) in
                    if let group = groupItem, group.shelfCollection.uuid == self?.rootContentViewController?.shelfItemCollection?.uuid {
                        self?.showLastOpenedGroup(group)
                    }
                }
            }
            self.removeLaunchScreen(true);
        }
    }
    // MARK: - Show Shelf -
    fileprivate func showShelf(updateWithLastSelected collection:FTShelfItemCollection? = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection ,
                               isInNonCollectionMode: Bool = false,
                               lastSelectedSideBarContentType sideBarContentType: FTSideBarItemType = .home,
                               lastSelectedTag: String = "") {
        FTCLSLog("Shelf UI Created");
        // Upodating created notebok count here, assuming, by this time provider will be ready and the books count is updated.
        FTIAPManager.shared.premiumUser.updateNoOfBooks(nil)
        //Instantiate Shelf view controller
        if(nil == self.rootContentViewController) {
            let controller =  FTShelfSplitViewController(style: .doubleColumn)
            controller.preferredDisplayMode = .oneBesideSecondary
            controller.configureSecondaryController(isInNonCollectionMode: isInNonCollectionMode,
                                                    lastSelectedContentType : sideBarContentType,
                                                    lastSelectedTag: lastSelectedTag,
                                                    lastSelectedCollection: collection)
            self.addChild(controller)
            controller.view.frame = self.contentView.bounds;
            self.contentView.addSubview(controller.view)
            self.addConstraintForView(controller.view, withrespectTo: self.contentView)
            self.refreshStatusBarAppearnce();
            controller.didMove(toParent: self)
            self.rootContentViewController = controller
        }
        else {
            let collectionTypes: [FTSideBarItemType] = [.home,.starred,.unCategorized,.trash,.category,.ns2Category]
            if collectionTypes.contains(where: {$0 == sideBarContentType}),let collection {
                self.rootContentViewController?.shelfItemCollection = collection
                (self.rootContentViewController as? FTShelfSplitViewController)?.sideMenuController?.showSidebarItemWithCollection(collection)
                self.rootContentViewController?.currentShelfViewModel?.collection = collection
            } else {
                self.rootContentViewController?.shelfItemCollection = nil
            }
        }
        configureSceneNotifications()
        FTCacheTagsProcessor.shared.createCacheTagsPlistIfNeeded()
        return
    }
    private func showLastOpenedGroup(_ group: FTShelfItemProtocol) {
        var resetGroup = true
        var reqParents:  [FTShelfItemProtocol] = []
        reqParents.append(group)
        reqParents.append(contentsOf: group.getParentsOfShelfItemTillRootParent())
        for parent in reqParents.reversed() {
            resetGroup = false
            self.rootContentViewController?.showGroup(with: parent, animate: false)
        }
        if(resetGroup) {
            self.setLastOpenedGroup(nil);
        }
    }
    // MARK: - Show shelf for add new
    func  quickOpenShelfForAddNew() {
        /*if let trashMode = self.shelfViewController?.shelfItemCollection.isTrash, trashMode == true {
         UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("NoNotebookCreationInTrash", comment: "You are in trash folder right now. Select any category to create a notebook."), from: self, withCompletionHandler: nil);
         return
         }*/
        self.closeAnyActiveOpenedBook { () -> Void in
           // self.rootContentViewController?.createQuickNoteBook()
        };
    }
    
    fileprivate func retryiCloudUnavaialbility() {
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Loading", comment: "Loading..."));
        runInMainThread(1.0) {
            loadingIndicatorViewController.hide() { [weak self] in
                self?._updateProvider({ [weak self] isUpdated in
                    if(!isUpdated) {
                        runInMainThread {
                            if currentRetryCount < maxRetryCount {
                                currentRetryCount += 1
                                self?.showIcloudMessage();
                            } else {
                                track("icloud_retry_exceed")
                                fatalError("icloud_retry_exceed")
                            }
                        }
                    }
                })
            }
        }
    }

    private func closeAnyActiveOpenedBook(completion: @escaping () -> Void) {

        self.updateProvider { () -> Void in

            if self.rootContentViewController != nil {

                if let _docuemntViewController = self.docuemntViewController {
                    self.saveApplicationStateByClosingDocument(true, keepEditingOn: false, onCompletion: { [weak _docuemntViewController] success in
                        if(success) {
                            self.switchToShelf(_docuemntViewController?.documentItemObject, documentViewController: _docuemntViewController,
                                               animate: true,
                                               onCompletion: {
                                self.dismissPresentedViewController({ () -> Void in
                                    completion()
                                })

                            });
                        }
                    })
                } else {
                    self.dismissPresentedViewController({ () -> Void in
                        completion()
                    })
                }

            } else {
                completion()
            }
        };
    }

    // MARK: - open Document from today widget
    func openDocumentForSelectedNotebook(_ path: URL, isSiriCreateIntent: Bool) {
        if let docController = self.docuemntViewController, !docController.canContinueToImportFiles() {
            let result = path.isPinEnabledForDocument()
            if result {
                track("opening_password_protected_doc")
                docController.showAlertAskingToEnterPwdToContinueOperation();
                return;
            } else{
                docController.avoidAskingPwd();
            }
        }
        let relativePath = path.relativePathWRTCollection();

        if(isSiriCreateIntent && FTNoteshelfDocumentProvider.shared.isProviderReady) {
            var collectionName : String?;
            if let _collectionName = path.relativePathWRTCollection().collectionName() {
                collectionName = _collectionName.deletingPathExtension;
            }
            self.shelfCollection(title: collectionName) { (shelfitemcollection) in
                if let collection = shelfitemcollection {
                    var groupItem : FTGroupItemProtocol?;
                    if let groupPath = relativePath.relativeGroupPathFromCollection() {
                        let url = collection.URL.appendingPathComponent(groupPath);
                        groupItem = collection.groupItemForURL(url);
                    }
                    let shelfItem = collection.documentItemWithName(title: relativePath.documentName(),
                                                                    inGroup: groupItem);
                    if(nil == shelfItem) {
                        _ = (shelfitemcollection as? FTShelfCacheProtocol)?.addItemToCache(path)
                    }
                    self.openDocumentAtRelativePath(relativePath, inShelfItem: shelfItem, animate: false, addToRecent: true, bipassPassword: true, onCompletion: nil);
                }
            }
        }
        else {
            self.openDocumentAtRelativePath(relativePath, inShelfItem: nil,
                                            animate: false,
                                            addToRecent: true,
                                            bipassPassword: true, onCompletion: nil);
        }
}
    
    func openNotebook(using schemeUrl: URL) {
        let queryItems = schemeUrl.getQueryItems()
        guard let documentId = queryItems.docId,
              let pageId = queryItems.pageId else {
            return
        }

        guard let docVc = self.docuemntViewController else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: documentId) { docItem in
                guard let shelfItem = docItem else {
                    self.handeDocumentUnAvailablity(for: documentId)
                    return
                }
                let relativePath = shelfItem.URL.relativePathWRTCollection()
                self.getShelfItemDetails(relativePath: relativePath) { [weak self] collection, group, shelfItem in
                    self?.showCollection(collection: collection!,
                                         groupitem: group,
                                         shelfItem: shelfItem!,
                                         addToRecent: false,
                                         passcode: nil,
                                         pageUUID: pageId,
                                         shouldAskforPasscode: true,
                                         onCompletion: nil)
                }
            }
            return
        }

        if documentId == currentDocumentLinkingId {
            docVc.navigateToPage(with: pageId)
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: documentId) { docItem in
                guard let shelfItem = docItem else {
                    docVc.handeDocumentUnAvailablity(for: documentId)
                    return
                }
                guard shelfItem.URL.downloadStatus() == .downloaded else {
                    // Book is not downloaded yet
                    UIAlertController.showDocumentNotDownloadedAlert(for: shelfItem.URL, from: docVc)
                    return
                }

                // After copy paste of same book text link in other book, document id will not be SELF any more.
                //Incase If document id falls for current book, if condition helps
                if documentId == self.docuemntViewController?.documentItemObject.documentUUID {
                    docVc.navigateToPage(with: pageId)
                } else {
                    let relativePath = shelfItem.URL.relativePathWRTCollection()
                    self.openDocumentIfNeeded(using: relativePath, and: pageId, onCompletion: {_,_ in
                    })
                }
            }
        }
    }

    func startNS2ToNS3Migration() {
        self.prepareProviderIfNeeded {
            self.closeAnyActiveOpenedBook {
                #if targetEnvironment(macCatalyst)
                self.nsToolbar?.isVisible = false
                #endif
                FTMigrationViewController.showMigration(on: self)
            }
        }
    }

    func showPremiumUpgradeScreen() {
        self.prepareProviderIfNeeded {
            self.closeAnyActiveOpenedBook {
                self.rootContentViewController?.presentIAPScreen()
            }
        }
    }

    func prepareProviderIfNeeded(onCompletion: (() -> ())?) {
        if(nil == self.rootContentViewController) {
            //This need to be un commented once we add the new migration UI
            self.isFirstTime = false;
            self.setLastOpenedGroup(nil);
            self.setLastOpenedDocument(nil);
            self.updateProvider {
                runInMainThread {
                    self.removeLaunchScreen(true);
                }
                onCompletion?()
            };
        } else {
            onCompletion?()
        }
    }

    // MARK: - Last Opened document/Group/Collection -
    fileprivate func showLastOpenedDocument(relativePath docPath: String,
                                            animate: Bool = false)
    {
        self.getShelfItemDetails(relativePath: docPath,
                                 igrnoreIfNotDownloaded: true)
        { [weak self] (_, groupItem, itemToOpen) in
            if let shelfItem = itemToOpen, let selfObject = self {
                let isPasswordEnabled = shelfItem.isPinEnabledForDocument();

                if (isPasswordEnabled && !selfObject.isOpeningDocument) {
                    selfObject.setLastOpenedGroup(nil);
                    selfObject.setLastOpenedDocument(nil);
                    selfObject.removeLaunchScreen(true);
                } else {
                    var isAllNotesMode: Bool = false
                    if let userActivity = self?.userActivity {
                        isAllNotesMode = userActivity.isAllNotesMode
                    }
                    if let group = groupItem, !isAllNotesMode {
                        var reqParents:  [FTShelfItemProtocol] = []
                        reqParents.append(group)
                        reqParents.append(contentsOf: group.getParentsOfShelfItemTillRootParent())
                        for parent in reqParents.reversed() {
                            self?.rootContentViewController?.showGroup(with: parent, animate: false)
                        }
                    }
                    if isPasswordEnabled && selfObject.isOpeningDocument {
                        selfObject.removeLaunchScreen(true);
                    }
                    selfObject.isOpeningDocument = false

                    if selfObject.rootContentViewController != nil {
                        selfObject.rootContentViewController?.showNotebookAskPasswordIfNeeded(shelfItem, animate: animate, pin: nil, pageUUID: nil, addToRecent: true, isQuickCreate: false, createWithAudio: false, onCompletion: {[weak self] (_, _) in
                            if !isPasswordEnabled{
                                self?.removeLaunchScreen(true);
                            }
                        });
                    }
                }
            } else {
                self?.removeLaunchScreen(true);
            }
        };
    }
    fileprivate func setupSafeModeIfNeeded() {
        if FTUserDefaults.isInSafeMode() {
            self.setLastOpenedGroup(nil);
            self.setLastOpenedDocument(nil);

            self.removeLaunchScreen(true);
            return;
        }
        switchToCrashSafeModeIfNeeded()
    }
    fileprivate func lastSelectedCollectionName() -> String? {
        var collectionName : String?

        if let openedDoc = self.lastOpenedDocument() {
            if let _collectionName = openedDoc.collectionName() {
                collectionName = _collectionName.deletingPathExtension;
            }
        } else if let openedGroup = self.lastOpenedGroup() {
            if let _collectionName = openedGroup.collectionName() {
                collectionName = _collectionName.deletingPathExtension;
            }
        }

        if collectionName == nil {
            let lastCollection = self.lastSelectedCollection()
            if let name = lastCollection as NSString? {
                collectionName = name.deletingPathExtension
            }
        }
        return collectionName;
    }

    func saveApplicationStateByClosingDocument(_ shouldClose: Bool, keepEditingOn: Bool, onCompletion: ((Bool) -> Void)?) {
        docuemntViewController?.saveApplicationStateByClosingDocument(shouldClose, keepEditingOn: keepEditingOn, onCompletion: onCompletion)
    }

    // MARK: Create and open new notebook
    func createAndOpenNewNotebook(_ url: URL) {
        self.docuemntViewController?.avoidAskingPwd();
        self.openInFileForURL(url) { () -> Void in
            self.quickOpenShelfForAddNew()
        }
    }

    func createNotebookWithAudio() {
        closeAnyActiveOpenedBook {
           // self.rootContentViewController?.createNotebookWithAudio()
        }
    }

    func createNotebookWithCameraPhoto() {
        closeAnyActiveOpenedBook {
            //self.rootContentViewController?.createNotebookWithCameraPhoto()
        }
    }

    func createNotebookWithScannedPhoto() {
        closeAnyActiveOpenedBook {
            //self.rootContentViewController?.createNotebookWithScannedPhoto()
        }
    }

    func openTemplatesScreen(url: URL) {
        if let controller = rootContentViewController as? FTShelfSplitViewController {
            controller.selectAndOpenTemplates(with: url)
        }
    }
    
    // MARK: - open PDF

    func importItem(_ item: FTImportItem) {
        if let docController = self.docuemntViewController, !docController.canContinueToImportFiles() {
            docController.showAlertAskingToEnterPwdToContinueOperation();
            return;
        }
        guard let url = item.importItem as? URL else {
            return;
        }
        self.openInFileForURL(url) { () -> Void in
            if url.pathExtension.lowercased() == "zip" {
                FTNBKZipFileExtracter.extractNBKContents(for: url,
                                                         viewController: self,
                                                         onCompletion: { (inItem) in
                    if let _item = inItem {
                        self.addItemToImportQueue(_item)
                    }
                })
            }
            else {
                self.addItemToImportQueue(item)
            }
        }
    }

    // MARK: - Open In -
    func openInFileForURL(_ url: URL, completion : (() -> Void)?) {
        if(nil == self.rootContentViewController) {
            self.isFirstTime = false;
            self.setLastOpenedGroup(nil);
            self.setLastOpenedDocument(nil);
            self.updateProvider {
                runInMainThread {
                    self.removeLaunchScreen(true);
                }
                self.openInFileForURL(url, completion: completion);
            };
            return;
        }
        
        FTIAPManager.shared.premiumUser.prepare {
            self.dismissPresentedViewController({ () -> Void in
                completion?()
            })
        }
    }

    // For eg. if any other notebook is open, close it first so that new notebook can open
    func dismissPresentedViewController(_ completion:(() -> Void)?) {
        if(!Thread.current.isMainThread) {
            DispatchQueue.main.async {
                self.dismissPresentedViewController(completion);
            }
            return;
        };

        if(self.docuemntViewController != nil) {
            FTCLSLog("Open in: inside notebook");
            if let window = Application.keyWindow,
               window.rootViewController is FTBlurViewController,

                let controller = self.view.window?.visibleViewController as? FTPinRequestViewController {
                controller.dismiss(animated: false) {
                    self.docuemntViewController?.removeBlurEffectForPassword(false)
                }
            }
            if let presentedViewController = self.rootContentViewController?.presentedViewController{
                //Added to dismiss, when we're coming via Home Screen Quick Actions.
                if presentedViewController is UIImagePickerController ||
                    presentedViewController.isKind(of: FTScanDocumentService.controllerForScanning()) {
                    presentedViewController.dismiss(animated: false) {
                        completion?()
                    }
                }else if let navController = presentedViewController as? UINavigationController {
                    // To handle dropped office docs
                    if navController.topViewController is FTFinderViewController ||
                        navController.topViewController is FTShelfItemsViewController {
                        if(navController.isBeingDismissed) {
                            completion?()
                        }
                    }
                    else {
                        presentedViewController.dismiss(animated: false) {
                            completion?()
                        }
                    }
                } else if presentedViewController is UISplitViewController {
                    //                    presentedViewController.dismiss(animated: false) {
                    //                        completion?()
                    //                    }
                    completion?()
                }
                else {
                    completion?()
                }
            }
            else
            {
                completion?()
            }
        } else {
            if let presentedViewController = self.rootContentViewController?.presentedViewController {
                if(presentedViewController.isBeingDismissed) {
                    completion?()
                }
                else if let navC = presentedViewController as? UINavigationController,
                        navC.topViewController is FTImportedDocViewController {
                    completion?()
                }
                else {
                    presentedViewController.dismiss(animated: true, completion: {
                        completion?()
                    });
                }
            } else {
                completion?()
            }
        }
    }

    private func importItemIntoDesk(for item: FTImportItem,
                                    completion:((_ shelfItem: FTShelfItemProtocol?, _ completed:Bool) -> Void)?)
    {
        weak var docController = self.docuemntViewController;
        if(item.shouldSwitchToRoot()) {
            track("import_document", params: ["type" : nsBookExtension])
            self.saveApplicationStateByClosingDocument(true, keepEditingOn: false, onCompletion: { success in
                if(success) {
                    self.switchToShelf(docController?.documentItemObject,
                                       documentViewController: docController,
                                       animate: true,
                                       onCompletion: {
                        if self.rootContentViewController != nil {
                            self.rootContentViewController?.importItemAndAutoScroll(item,
                                                                                    shouldOpen: false,
                                                                                    completionHandler:
                                                                                        { (item, completed) in
                                completion?(item,completed)
                            })
                        }
                        else {
                            completion?(nil,false)
                        }
                    });
                } else {
                    item.removeFileItems();
                    completion?(nil,false)
                }
            });
            return;
        }
        guard let url = item.importItem as? URL else {
            completion?(nil,false)
            return;
        }
        if isAudioFile(url.path) {
            if isSupportedAudioFile(url.path) {
                track("import_document", params: ["type" : url.lastPathComponent])
                importAudioFile(fromURL: url) { (compltd) in
                    completion?(nil,compltd)
                }
            } else {
                let alertController = UIAlertController(title: "",
                                                        message: NSLocalizedString("NotSupportedFormat", comment: "Note supported format"),
                                                        preferredStyle: .alert);
                let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Ok"), style: .cancel, handler: { _ in
                    completion?(nil,false)
                });
                alertController.addAction(cancelAction);
                self.present(alertController, animated: true, completion: nil);
            }
        }
        else {
            let message = url.lastPathComponent + "\n" + NSLocalizedString("InsertDocumentCurrentOrNew", comment: "Insert into...")
            let alertController = UIAlertController(title: "",
                                                    message: message,
                                                    preferredStyle: .alert);
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
                item.removeFileItems();
                completion?(nil,true)
            });
            alertController.addAction(cancelAction);

            let insertHere = UIAlertAction(title: NSLocalizedString("InsertHere", comment: "Insert Here"), style: .default, handler: { _ in
                docController?.insertNewPage(fromItem: url, onCompletion: { (complted) in
                    completion?(nil,complted)
                })
            });
            alertController.addAction(insertHere);

            let createNew = UIAlertAction(title: NSLocalizedString("CreateNew", comment: "Create New"), style: .default, handler: { _ in
                self.saveApplicationStateByClosingDocument(true, keepEditingOn: false, onCompletion: { success in
                    if(success) {
                        self.switchToShelf(docController?.documentItemObject, documentViewController: docController, animate: true, onCompletion: {
                            self.openInFileForURL(url,completion: {
                                if self.rootContentViewController != nil {
                                    self.rootContentViewController?.importItemAndAutoScroll(item,
                                                                                            shouldOpen: false,
                                                                                            completionHandler: { (item, completed) in
                                        completion?(item,completed)
                                    })

                                }
                            })
                        });
                    } else {
                        item.removeFileItems()
                        completion?(nil,false)
                    }
                });
            });
            alertController.addAction(createNew);
            if(Thread.current.isMainThread) {
                self.noteBookSplitController?.present(alertController, animated: true, completion: nil);
            }
            else {
                DispatchQueue.main.async {
                    self.noteBookSplitController?.present(alertController, animated: true, completion: nil);
                }
            }
        }
    }

    fileprivate func importAudioFile(fromURL url: URL,
                                     onCompletion : ((_ complted:Bool) -> Void)?) {
        weak var docController = self.docuemntViewController;
        let message = url.lastPathComponent + "\n" + NSLocalizedString("InsertAudioCurrentOrNew", comment: "Insert into...")
        let alertController = UIAlertController(title: "",
                                                message: message,
                                                preferredStyle: .alert);
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { _ in
            try? FileManager().removeItem(at: url);
            onCompletion?(false)
        });
        alertController.addAction(cancelAction);

        let insertHere = UIAlertAction(title: NSLocalizedString("InsertHere", comment: "Insert Here"), style: .default, handler: { _ in
            let item = FTAudioFileToImport.init(withURL: url);
            item.fileName = url.deletingPathExtension().lastPathComponent;
            docController?.addRecordingToPage(actionType: .addToCurrentPage, audio: item, onCompletion: { complted, _ in
                onCompletion?(complted)
            })
        });
        alertController.addAction(insertHere);

        let createNew = UIAlertAction(title: NSLocalizedString("CreateNew", comment: "Create New"), style: .default, handler: { _ in
            let item = FTAudioFileToImport.init(withURL: url);
            item.fileName = url.deletingPathExtension().lastPathComponent;
            docController?.addRecordingToPage(actionType: .addToNewPage, audio: item, onCompletion: { complted, _ in
                onCompletion?(complted)
            })
        });
        alertController.addAction(createNew);
        self.present(alertController, animated: true, completion: nil);
    }

    // MARK: - Spot light open -
    func openShelfItem(spotLightHash: String) {
        self.openDocumentAtRelativePath(spotLightHash, inShelfItem: nil,
                                        animate: false,
                                        addToRecent: true,
                                        igrnoreIfNotDownloaded: true,
                                        bipassPassword: true, onCompletion: nil);
    }

#if targetEnvironment(macCatalyst)
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        var canPerform = super.canPerformAction(action, withSender: sender)
//        if(action == #selector(orderFrontPreferencesPanel(_:))) {
//            canPerform = true;
//#if DEBUG
//            debugPrint("App del \(action) canPerform:\(canPerform)");
//#endif
//        }
//        return canPerform;
//    }

//    @objc func orderFrontPreferencesPanel(_ sender : Any?)
//    {
//        if let navController = self.presentedViewController as? UINavigationController,
//           navController.viewControllers.first is FTGlobalSettingsController {
//            return;
//        }
//    }
#endif

    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "iCloudOn" {
            self.updateProviderIfNeeded();
        }
    }
}

fileprivate extension FTRootViewController {
    func shelfCollection(title : String?,
                         pickDefault : Bool = false,
                         onCompeltion : @escaping (FTShelfItemCollection?)->())
    {
        FTNoteshelfDocumentProvider.shared.shelfCollection(title: title,
                                                           pickDefault: pickDefault, onCompeltion: onCompeltion);
    }
}

//MARK:- Open Doc hash -
extension FTRootViewController
{

    func openDocumentWithoutAnimation(relativePath: String,
                                      inShelfItem: FTShelfItemProtocol?,
                                      addToRecent: Bool = false,
                                      igrnoreIfNotDownloaded: Bool,
                                      bipassPassword: Bool = false, onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?) {
        let finalizeBlock: (FTLoadingIndicatorViewController) -> Void = { [weak self] indicatorView in
            indicatorView.hide();

            self?.removeLaunchScreen(true);
            self?.view.isUserInteractionEnabled = true;
        };

        let indicatorView = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("LoadingNotebook", comment: "Opening..."), andDelay: 1);
        self.view.isUserInteractionEnabled = false;

        self.getShelfItemDetails(relativePath: relativePath) { [weak self] collection, group, shelfItem in
            if(nil != collection && nil != shelfItem) {
                if(!bipassPassword && shelfItem!.isPinEnabledForDocument()) {
                    finalizeBlock(indicatorView);
                    return;
                }
                if let controller = self?.docuemntViewController {
                    FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem!,
                                                                 onviewController: controller,
                                                                 onCompletion:
                                                                    { [weak self] pin, success,_ in
                        if(success) {
                            weak var splitController = self?.noteBookSplitController

                            self?.showCollection(collection: collection!,
                                                 groupitem: group,
                                                 shelfItem: (inShelfItem != nil) ? inShelfItem! : shelfItem!,
                                                 addToRecent: addToRecent,
                                                 passcode: pin,
                                                 shouldAskforPasscode: false,
                                                 onCompletion:
                                                    { (doc, success) in
                                finalizeBlock(indicatorView);
                                if let oldRenderView = splitController, let newController = self?.noteBookSplitController {
                                    UIView.transition(from: oldRenderView.view,
                                                      to: newController.view,
                                                      duration: 0.2,
                                                      options: UIView.AnimationOptions.transitionCrossDissolve,
                                                      completion: { _ in
                                        oldRenderView.willMove(toParent: nil);
                                        oldRenderView.view.removeFromSuperview();
                                        oldRenderView.removeFromParent();
                                    });
                                }
                                onCompletion?(doc, success)
                            });
                        } else {
                            finalizeBlock(indicatorView)
                            onCompletion?(nil, false)
                        }
                    })
                } else {
                    finalizeBlock(indicatorView);
                    self?.showCollection(collection: collection!,
                                         groupitem: group,
                                         shelfItem: shelfItem!,
                                         addToRecent: addToRecent,
                                         passcode: nil,
                                         shouldAskforPasscode: true,
                                         onCompletion: onCompletion);
                }
            } else {
                finalizeBlock(indicatorView);
                UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("NotebookNotAvailable", comment: "NotebookNotAvailable"), from: self!, withCompletionHandler: nil)
                onCompletion?(nil, false)
            }
        }
    }

    func showCollection(collection: FTShelfItemCollection,
                        groupitem: FTGroupItemProtocol?,
                        shelfItem: FTShelfItemProtocol,
                        addToRecent: Bool = true,
                        passcode: String?,
                        pageUUID: String? = nil,
                        shouldAskforPasscode: Bool,
                        onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?) {
        self.rootContentViewController?.showNotebookAskPasswordIfNeeded(shelfItem, animate: false, pin: shouldAskforPasscode ? nil : passcode, pageUUID: pageUUID, addToRecent: addToRecent, isQuickCreate: false, createWithAudio: false, onCompletion: onCompletion)
    }
}

// for siri Shortcuts

extension FTRootViewController {

    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)

        guard let activity = activity.siriShortcutActivity else {
            return
        }

        switch activity {
        case .openNotebook(let notebook):
            if let url = notebook["notebookURL"] as? URL {
                self.openDocumentForSelectedNotebook(url, isSiriCreateIntent: false)
            }
        case .createAudioNotebook:
            self.createAndOpenNewNotebook(URL(fileURLWithPath: "www.google.com"))
        case .createNotebook:
            self.createAndOpenNewNotebook(URL(fileURLWithPath: "www.google.com"))
        }
    }
}

extension FTRootViewController {
    fileprivate func removeLaunchScreen(_ animated : Bool)
    {
        if let launchscreen = self.launchScreenController {
            FTCLSLog("Update Provider - Launch Screen Removed");
            if(!animated) {
                launchscreen.view.removeFromSuperview();
                launchscreen.removeFromParent();
            }
            else {
                UIView.animate(withDuration: 0.2, animations: { [weak launchscreen] in
                    launchscreen?.view.alpha = 0;
                }) { [weak launchscreen] (_) in
                    launchscreen?.view.removeFromSuperview();
                    launchscreen?.removeFromParent();
                }
            }
        }
    }
}

extension FTRootViewController: UIPencilInteractionDelegate {

    func addPencilInteractionDelegate() {
        if(FTUtils.isDeviceSupportsApplePencil2()) {
            let penInteractionController = UIPencilInteraction();
            penInteractionController.delegate = self;
            self.view.addInteraction(penInteractionController);
            self.pencilInteraction = penInteractionController;
        }
    }

    func pencilInteractionDidTap(_ interaction: UIPencilInteraction)
    {
        if(self.applicationState() == .active) {
            self.performPencilTapOperation();
        }
        else {
            track("pencil_double_tap", params: ["appState" : "background"]);
        }
    }

    fileprivate func performPencilTapOperation() {
        if let docController = self.docuemntViewController {
            var action = FTUserDefaults.applePencilDoubleTapAction();
            if(action == FTApplePencilInteractionType.systemDefault) {
                switch(UIPencilInteraction.preferredTapAction) {
                case .switchEraser:
                    action = FTApplePencilInteractionType.eraser;
                case .switchPrevious:
                    action = FTApplePencilInteractionType.previousTool;
                case .showColorPalette:
                    action = FTApplePencilInteractionType.showColors;
                default:
                    break
                }
            }
            docController.didReceivePencilInteraction(action);
        }
    }
}

extension FTRootViewController {
    private func addItemToImportQueue(_ item:FTImportItem) {
        importItemsQueue.append(item)
        if(!isImportInProgress) {
            isImportInProgress = true
            startProcessingImport(openDoc: item.openOnImport)
        }
    }

    private func startProcessingImport(openDoc : Bool) {

        let blockToComplete : (FTShelfItemProtocol?) -> Void = { [weak self] item in
            if self?.importItemsQueue.isEmpty ?? false {
                self?.isImportInProgress = false;
                if let shelfItem = item {
                    self?.rootContentViewController?.continueProcessingImport(withOpenDoc: openDoc, withItem: shelfItem)
                }
            } else {
                self?.startProcessingImport(openDoc: false);
            }
        }

        if !self.importItemsQueue.isEmpty {
            if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
                FTIAPurchaseHelper.shared.showIAPAlert(on: self);
                self.importItemsQueue.removeAll();
                self.isImportInProgress = false
                FTImportStorageManager.clearImportFilesIfNeeded(true);
                return;
            }
            let importItem = self.importItemsQueue.removeFirst()
            if let docController = self.docuemntViewController {
                if !docController.canContinueToImportFiles() {
                    docController.showAlertAskingToEnterPwdToContinueOperation();
                    blockToComplete(nil)
                } else {
                    self.importItemIntoDesk(for: importItem,
                                            completion:{ item, completed in
                        importItem.completionHandler?(item,completed);
                        blockToComplete(item)
                    });
                }
            }
            else {
                if self.rootContentViewController != nil {
                    self.rootContentViewController?.importItemAndAutoScroll(importItem, shouldOpen: false, completionHandler: { (item, completed) in
                        importItem.completionHandler?(item,completed);
                        blockToComplete(item)
                    })

                }
            }
        } else {
            isImportInProgress = false
        }
    }

    func getShelfItemDetails(relativePath: String,
                             igrnoreIfNotDownloaded: Bool = false,
                             onCompletion : @escaping (FTShelfItemCollection?, FTGroupItemProtocol?, FTShelfItemProtocol?) -> Void) {

        FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: relativePath, igrnoreIfNotDownloaded: igrnoreIfNotDownloaded, onCompletion: onCompletion);
    }

}

//MARK:- State Restoration
extension FTRootViewController {
    //MARK:- State saving
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        FTCLSLog("State is being encoded")
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        var lastOpenedDocument : String?
        var lastOpenedGroup : String?

        if let book = coder.decodeObject(forKey: LastOpenedDocumentKey) as? String {
            lastOpenedDocument = book
        }
        if let group = coder.decodeObject(forKey: LastOpenedGroupKey) as? String {
            lastOpenedGroup = group
        }
        FTCLSLog("State Restoring via Decoding")
    }

    //MARK:- State fetching
    func setLastOpenedDocument(_ documentURL : URL?) {
        self.userActivity?.lastOpenedDocument = documentURL?.relativePathWRTCollection()
    }

    private func lastOpenedDocument() -> String? {
        return userActivity?.lastOpenedDocument;
    }

    func setLastOpenedGroup(_ groupURL : URL?) {
        FTUserDefaults.setNonCollectionModeTo(false)
        self.userActivity?.isInNonCollectionMode = false
        self.userActivity?.lastOpenedGroup = groupURL?.relativePathWRTCollection()
    }

    private func lastOpenedGroup() -> String? {
        return userActivity?.lastOpenedGroup;
    }

    func setLastSelectedCollection(_ collection : URL?) {
        FTUserDefaults.setLastSelectedCollection(collection)
        self.userActivity?.lastSelectedCollection = collection?.relativePathWRTCollection()
        FTUserDefaults.setNonCollectionModeTo(false)
        self.userActivity?.isInNonCollectionMode = false
    }

    private func lastSelectedCollection() -> String? {
        if let collectionName = self.lastOpenedDocument()?.collectionName() {
            return collectionName;
        }
        else if let collectionName = self.lastOpenedGroup()?.collectionName() {
            return collectionName;
        }
        else if let collection = userActivity?.lastSelectedCollection {
            return collection
        } else {
            return FTUserDefaults.lastSelectedCollection()
        }
    }
}


//MARK:- FTOpenCloseDocumentProtocol
extension FTRootViewController: FTOpenCloseDocumentProtocol {
    func openRecentItem(shelfItemManagedObject: FTDocumentItemWrapperObject, addToRecent: Bool) {
        self.openDocumentAtRelativePath(shelfItemManagedObject.URL.relativePathWRTCollection(),
                                        inShelfItem: shelfItemManagedObject.documentItemProtocol,
                                        animate: false,
                                        addToRecent: addToRecent,
                                        bipassPassword: true, onCompletion: nil);
    }

    func closeDocument(shelfItemManagedObject:FTDocumentItemWrapperObject, animate: Bool, onCompletion : (() -> Void)?) {

        self.switchToShelf(shelfItemManagedObject,
                           documentViewController: self.docuemntViewController,
                           animate: animate,
                           onCompletion: onCompletion)

    }
}

//MARK:- FTSceneBackgroundHandling
extension FTRootViewController: FTSceneBackgroundHandling {
    func configureSceneNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillEnterForeground(_:)), name: UIApplication.sceneWillEnterForeground, object: self.sceneToObserve)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillResignActive(_:)), name: UIApplication.sceneWillResignActive, object: self.sceneToObserve)
        self.configureForImportAction();
    }

    func sceneWillResignActive(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }
        self.saveApplicationStateByClosingDocument(false, keepEditingOn: true, onCompletion: nil);
    }

    func sceneWillEnterForeground(_ notification: Notification) {
        if(!self.canProceedSceneNotification(notification)) {
            return;
        }
        FTAppConfigHelper.sharedAppConfig().updateAppConfig()
        if FTWhatsNewManger.canShowWelcomeScreen(onViewController: self) {
            FTWelcomeScreenViewController.showWelcome(presenterController: self, onDismiss: nil);
            self.refreshStatusBarAppearnce();
        } else {
            if self.showPremiumUpgradeAdScreenIfNeeded() {
                return;
            }
            var placeOfSlideShow: FTWhatsNewSlideShowPlace = .shelf
            if nil != self.docuemntViewController {
                placeOfSlideShow = .notebook
            }
            if(FTWhatsNewManger.canShow(from: self, placeOfSlideShow: placeOfSlideShow)) {
                FTWhatsNewViewController.showIfNeeded(on: self,
                                                      source: FTSourceScreen.regular, placeOfSlideShow: placeOfSlideShow,
                                                      dismissBlock: nil)
            }
            else {
                FTBetaAlertHandler.showiOS13BetaAlertIfNeeded(onViewController: self);
                FTOneDriveAlertHandler.showOneDriveAuthenticationAlertIfNeeded(self)
                self.presentImportsControllerifNeeded();
            }
        }
    }
}

private extension FTRootViewController {
    func switchToCrashSafeModeIfNeeded() {
        if let attemptsInfo = UserDefaults.standard.object(forKey: "attempts") as? [AnyHashable : Any] {
            let attempt = (attemptsInfo["noOfAttempts"] as? NSNumber)?.intValue ?? 0
            let lastAttempt = TimeInterval((attemptsInfo["lastAttempt"] as? NSNumber)?.doubleValue ?? 0.0)
            let currentTime = Date.timeIntervalSinceReferenceDate
            let isAttemptThresholdReached = ((currentTime - lastAttempt) <= 20 * 60) ? true : false
            if (isAttemptThresholdReached) {
                if (attempt >= 3) {
                    self.setLastOpenedDocument(nil)
                    UserDefaults.standard.removeObject(forKey: "attempts")
                    UserDefaults.standard.synchronize()
                    DispatchQueue.main.async(execute: {
                        let controller = UIAlertController(title: NSLocalizedString("ZendeskSupportAlert", comment: "") , message: nil, preferredStyle: .alert)

                        let okAction = UIAlertAction(title: NSLocalizedString("Support", comment: ""), style: .cancel, handler: { action in
                            FTZenDeskManager.shared.showSupportHelpCenterScreen(controller: self)
                        })
                        controller.addAction(okAction)

                        let cancelAction = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default, handler: nil)
                        controller.addAction(cancelAction)

                        self.present(controller, animated: true)
                    })
                }
            }
        }
    }
}

extension FTRootViewController {
    func openDocumentAtRelativePath(_ relativePath : String,
                                    inShelfItem: FTShelfItemProtocol?,
                                    pageUUID: String? = nil,
                                    animate : Bool = false,
                                    addToRecent : Bool = false,
                                    igrnoreIfNotDownloaded : Bool = false,
                                    bipassPassword : Bool = true, onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?)
    {

        if(false == FTNoteshelfDocumentProvider.shared.isProviderReady) {
            isOpeningDocument = true
            self.setLastOpenedGroup(nil);
            self.setLastOpenedDocument(NSURL(fileURLWithPath: relativePath) as URL);
            onCompletion?(nil, false)
            return;
        }

        self.dismissPresentedViewController { [weak self] in
            guard let self = self else {
                onCompletion?(nil, false)
                return
            }
            if(nil != self.docuemntViewController) {
                let currentDocumentRelativePath = self.docuemntViewController?.relativePath;
                if(currentDocumentRelativePath == relativePath) {
                    onCompletion?(nil, false)
                    return;
                }
            }
            self.openDocumentWithoutAnimation(relativePath: relativePath,
                                              inShelfItem: inShelfItem,
                                              addToRecent: addToRecent,
                                              igrnoreIfNotDownloaded: igrnoreIfNotDownloaded,
                                              bipassPassword: bipassPassword, onCompletion: onCompletion);
        }
    }

    func openDocumentIfNeeded(using relativePath: String, and pageUUID: String, onCompletion: ((FTDocumentProtocol?, Bool) -> Void)?) {
        self.getShelfItemDetails(relativePath: relativePath) { [weak self] collection, group, shelfItem in
            guard let self else { return }
            if let controller = self.docuemntViewController {
                FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem!,
                                                             onviewController: controller,
                                                             onCompletion:
                                                                { [weak self] pin, success,_ in
                    guard let self else { return }
                    if(success) {
                        weak var splitController = self.noteBookSplitController
                        self.showCollection(collection: collection!,
                                            groupitem: group,
                                            shelfItem:  shelfItem!,
                                            addToRecent: false,
                                            passcode: pin,
                                            pageUUID: pageUUID,
                                            shouldAskforPasscode: false,
                                            onCompletion:
                                                { (doc, success) in
                            if success, let oldRenderView = splitController, let newController = self.noteBookSplitController {
                                UIView.transition(from: oldRenderView.view,
                                                  to: newController.view,
                                                  duration: 0.2,
                                                  options: .transitionCrossDissolve,
                                                  completion: { _ in
                                    oldRenderView.remove()
                                })
                            }
                            onCompletion?(doc, success)
                        })
                    } else {
                        onCompletion?(nil, false)
                    }
                })
            }
        }
    }

    func startRecordingOnAudioNotebook() {
        self.docuemntViewController?.startRecordingOnAudioNotebook()
    }

    func switchToPDFViewer(_ documentInfo : FTDocumentOpenInfo,
                           animate anim: Bool,
                           onCompletion : (() -> Void)?) {

        let animate : Bool = anim;
        self.setWindowTitle(documentInfo.shelfItem.displayTitle)

        let shelfItem = documentInfo.shelfItem;
        let document = documentInfo.document;
        self.setLastOpenedDocument(shelfItem.URL);
        self.rootContentViewController?.shelfWillMovetoBack()
        FTENPublishManager.shared.currentOpenedDocumentUUID = documentInfo.document.documentUUID;
        let blockToCall : () -> Void = { [weak self] in
            self?.docuemntViewController?.didCompleteDocumentPresentation();
            onCompletion?();
        };

        DispatchQueue.main.async { [weak self] in
            let oldController = self?.noteBookSplitController;

            FTCLSLog("Book: Preparing Note Split")
            if let splitscreen = self?.deskController(docInfo: documentInfo) {
                self?.presentNotebookSplitController(splitscreen: splitscreen,
                                                     oldController: oldController,
                                                     animate: animate) {
                    if let docitem = shelfItem as? FTDocumentItemProtocol {
                        FTNoteshelfDocumentProvider.shared.addShelfItemToList(shelfItem, mode: .recent)
                        docitem.updateLastOpenedDate();
                        (document as? FTNoteshelfDocument)?.setLastOpenedDate(docitem.fileLastOpenedDate)
                    }
                    FTCLSLog("Book: Note Split Presented")
                    blockToCall();
                }
            }
        }
    }
}

private extension FTRootViewController {
    func closeNotebookSplitController(splitVC: FTNoteBookSplitViewController?,
                                      animate: Bool,
                                      onCompletion : (() -> ())?)
    {
        if let presentingVC = splitVC?.presentingViewController,
           presentingVC.isMember(of: FTCreateNotebookViewController.classForCoder()) {
            presentingVC.presentingViewController?.dismiss(animated: animate,completion: onCompletion);
            return;
        }
        splitVC?.presentingViewController?.dismiss(animated: animate, completion: onCompletion);
    }
    
    func presentNotebookSplitController(splitscreen: FTNoteBookSplitViewController,
                                        oldController: FTNoteBookSplitViewController?,
                                        animate: Bool,onCompletion: (() -> ())?) {
        var snapshotViews = [UIView]();
        if let _oldController = oldController,
            let snapView = _oldController.view.snapshotView(afterScreenUpdates: false) {
            snapshotViews.append(snapView);
            if let view = _oldController.presentingViewController?.view {
                view.addSubview(snapView);
                snapView.addEqualConstraintsToView(toView: view)
            }
        }
        
        self.closeNotebookSplitController(splitVC: oldController, animate: animate, onCompletion: nil);

        var controllerToPresent: UIViewController? = self;
        if let presentedController = self.presentedViewController,
           !presentedController.isBeingDismissed {
            if let createNBController = presentedController as? FTCreateNotebookViewController {
                if let snapView = createNBController.snapshotView() {
                    self.contentView.addSubview(snapView);
                    snapshotViews.append(snapView);
                }
                FTCLSLog("Book: New NB Screen Snapshot")
                presentedController.dismiss(animated: false)
            }
            else {
                controllerToPresent = presentedController;
            }
        }
                    
        self.noteBookSplitController = splitscreen
        #if targetEnvironment(macCatalyst)
        splitscreen.modalTransitionStyle = .crossDissolve
        splitscreen.modalPresentationStyle = .currentContext;
        #else
        splitscreen.transitioningDelegate = splitscreen.contentTransitionDelegate;
        splitscreen.modalPresentationStyle = .custom;
        #endif
        FTCLSLog("Book: Presenting UI")
        let createNotebookController = (self.rootContentViewController as? UIViewController)?.children.filter{$0 is FTCreateNotebookViewController};
        controllerToPresent?.present(splitscreen, animated: animate,completion: { [weak splitscreen] in
            createNotebookController?.forEach { eachItem in
                eachItem.dismiss(animated: false, completion: nil);
            }
            snapshotViews.forEach { eachView in
                eachView.removeFromSuperview();
            }
            splitscreen?.refreshStatusBarAppearnce();
            snapshotViews.removeAll();
            onCompletion?()
        });
    }
}

extension FTRootViewController {
    override var childForStatusBarStyle: UIViewController? {
        let topChildVC = self.view.window?.rootViewController?.children.last
        if topChildVC is FTDocumentRenderViewController {
            return topChildVC
        }
        else{
            return nil
        }
    }
}
extension FTRootViewController { // for non collection types status
    fileprivate func isInNonCollectionMode() -> Bool? {
        if let nonCollectionMode = userActivity?.isInNonCollectionMode {
            return nonCollectionMode
        } else {
            return FTUserDefaults.isInNonCollectionMode()
        }
    }
    fileprivate func lastSelectedNonCollectionType() -> String? {
        if let nonCollectionType = userActivity?.lastSelectedNonCollectionType {
            return nonCollectionType
        } else {
            return FTUserDefaults.lastSelectedNonCollectionType()
        }
    }
    fileprivate func lastSelectedTag() -> String? {
        if let lastSelectedTag = userActivity?.lastSelectedTag {
            return lastSelectedTag
        } else {
            return FTUserDefaults.lastSelectedTag()
        }
    }
    func setLastSelectedNonCollectionType(_ type : FTSideBarItemType) {
        FTUserDefaults.setNonCollectionModeTo(true)
        self.userActivity?.isInNonCollectionMode = true
        FTUserDefaults.setLastSelectedNonCollectionType(type.rawValue)
        self.userActivity?.lastSelectedNonCollectionType = type.rawValue
    }
    func setLastSelectedTag(_ tag : String) {
        FTUserDefaults.setNonCollectionModeTo(true)
        self.userActivity?.isInNonCollectionMode = true
        FTUserDefaults.setLastSelectedTag(tag)
        self.userActivity?.lastSelectedTag = tag
    }
}

private extension FTRootViewController {
    func addShelfToolbar() {
#if targetEnvironment(macCatalyst)
        if let toolbar = self.nsToolbar as? FTShelfToolbar {
            toolbar.switchMode(.shelf);
        }
        else if let windowScene = self.view.uiWindowScene {
            self.titlebar?.toolbar = FTShelfToolbar(windwowScene: windowScene);
        }
#endif
    }
}

extension FTRootViewController: SFSafariViewControllerDelegate {
    private func showiCloudHelp() {
        let url = URL(string: "https://noteshelf-support.fluidtouch.biz/hc/en-us/articles/360046214954")!
        let safari = SFSafariViewController(url: url)
        safari.delegate = self
        self.present(safari, animated: true)
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.retryiCloudUnavaialbility()
    }
}


private var launchTracker: FTAppLauncTracker?
private class FTAppLauncTracker: NSObject {
    weak var rootViewController: FTRootViewController?
    let delayedLaunchKey = "DelayedLaunch";
    var startTime: TimeInterval = Date.timeIntervalSinceReferenceDate;
    
    @objc func log5SecondWaitError() {
        FTLogError("App Launch Failed - 5")
    }
    @objc func log10SecondWaitError() {
        FTLogError("App Launch Failed - 10")
    }
    @objc func log20SecondWaitError() {
        FTLogError("App Launch Failed - 20")
    }
    @objc func log60SecondWaitError() {
        FTLogError("App Launch Failed - 60")
        UserDefaults.standard.setValue(true, forKey: delayedLaunchKey)
    }
    
    func scheduleLaunchWaitError() {
        self.perform(#selector(self.log5SecondWaitError), with: nil, afterDelay: 5);
        self.perform(#selector(self.log10SecondWaitError), with: nil, afterDelay: 10);
        self.perform(#selector(self.log20SecondWaitError), with: nil, afterDelay: 20);
        self.perform(#selector(self.log60SecondWaitError), with: nil, afterDelay: 60);
    }
    
    func cancelLaunchWaitError() {
        NSObject.cancelPreviousPerformRequests(withTarget: self);
        self.logTimeTaken();
    }
    
    func logTimeTaken() {
        let time = Int(Date.timeIntervalSinceReferenceDate - self.startTime)
        if time >= 60 {
            FTLogError("App Launch Time", attributes: ["Time" : time])
        }
        else if UserDefaults.standard.bool(forKey: delayedLaunchKey) {
            FTLogError("App Launch Recovered", attributes: ["Time" : time])
        }
    }
}

fileprivate extension FTRootViewController {
    func scheduleLaunchWaitError() {
        self.cancelLaunchWaitError();
        launchTracker = FTAppLauncTracker();
        launchTracker?.rootViewController = self;
        launchTracker?.scheduleLaunchWaitError();
    }
    
    func cancelLaunchWaitError() {
        launchTracker?.cancelLaunchWaitError();
        launchTracker = nil;
    }
}

private extension FTRootViewController {
    func showPremiumUpgradeAdScreenIfNeeded() -> Bool {
        if !FTIAPurchaseHelper.shared.isPremiumUser && FTCommonUtils.isWithinEarthDayRange() {
            UserDefaults().appScreenLaunchCount += 1
            if self.presentedViewController is FTIAPContainerViewController {
                return true;
            }
            if UserDefaults().appScreenLaunchCount > 1, !UserDefaults().isEarthDayOffScreenViewed {
                self.showPremiumUpgradeScreen()
                UserDefaults().isEarthDayOffScreenViewed = true
                return true;
            }
        }
        return false
    }
}
