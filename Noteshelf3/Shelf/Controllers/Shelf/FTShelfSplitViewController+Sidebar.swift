//
//  FTShelfSplitViewController+Sidebar.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 12/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTTemplatesStore
import FTNewNotebook
import Reachability

extension FTShelfSplitViewController: FTSideMenuViewControllerDelegate {
    func didCurrentCollectionRenamed(_ collection: FTShelfItemCollection) {
        if currentShelfViewModel?.collection.uuid == collection.uuid,let shelfParentVC = detailNavigationController?.viewControllers.first as? FTShelfViewControllerNew {
            shelfParentVC.shelfViewModel.collection = collection
            shelfParentVC.title = collection.displayTitle
        }
    }

    func showHomeView() {
        self.isInNonCollectionMode = true
        if !self.isRegularClass() { // In Compact modes, we are navigating to home on every tap on home option
            showHomeDetailedVC()
        } else if let detailController = self.detailController(), !detailController.isKind(of: FTShelfHomeViewController.self) { // In regular modes, avoiding refreshing shelf again if we are already in home.
            showHomeDetailedVC()
        } else if let navigationVC = self.viewController(for: .secondary) as? UINavigationController,
                  ((navigationVC.viewControllers.first?.isKind(of:FTShelfHomeViewController.self)) != nil),
            navigationVC.viewControllers.count > 1 {
            showHomeDetailedVC() // Executes incase of show in enclosing folder option. As we are adding controller on to same nav stack which contains home, above condition fails. So to explicitly show home on tap of home option in sidebar this block is used.
        }
        else if currentShelfViewModel == nil { // Executes when shifting from non collection types to home.
            showHomeDetailedVC()
        }

        func showHomeDetailedVC(){
            if detailNavigationController != nil {
                detailNavigationController?.popToRootViewController(animated: false)
            }
            let secondaryViewController = getSecondaryViewControllerForHomeOption()
            self.shelfItemCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
            self.updateRootVCToDetailNavController(rootVC: secondaryViewController)
        }
    }
    
    func saveLastSelectedNonCollectionType(_ type: FTSideBarItemType) {
        self.isInNonCollectionMode = true
        if let rootController = self.parent as? FTRootViewController {
            rootController.setLastSelectedNonCollectionType(type)
        }
    }
    
    func saveLastSelectedTag(_ tag: String) {
        if let rootController = self.parent as? FTRootViewController {
            rootController.setLastSelectedTag(tag)
        }
    }
    
    func openBookmarks() {
        if let detailController = detailController(), detailController.isKind(of: FTShelfBookmarksViewController.self) {
            self.showDetailViewController(detailController, sender: self)
        } else {
            self.updateRootVCToDetailNavController(rootVC: getBookmarkVC())
        }
    }
    
    func didTapOnUpgradeNow() {
        let reachability: Reachability = Reachability.forInternetConnection()
        let status: NetworkStatus = reachability.currentReachabilityStatus();
        if status == NetworkStatus.NotReachable {
            UIAlertController.showAlert(withTitle: "MakeSureYouAreConnected".localized, message: "", from: self, withCompletionHandler: nil)
            return
        } else {
            FTIAPurchaseHelper.shared.presentIAPIfNeeded(on: self);
        }
    }
    
    func presentIAPScreen() {
        let reachability: Reachability = Reachability.forInternetConnection()
        let status: NetworkStatus = reachability.currentReachabilityStatus();
        if status == NetworkStatus.NotReachable {
            UIAlertController.showAlert(withTitle: "MakeSureYouAreConnected".localized, message: "", from: self, withCompletionHandler: nil)
            return
        } else {
            FTIAPurchaseHelper.shared.presentIAPIfNeeded(on: self);
        }
    }

    
    func openTags(for tag: String, isAllTags: Bool) {
        if let detailController = self.detailController(), let controller = detailController as? FTShelfTagsViewController {
            controller.selectedTag = isAllTags ? nil : FTTagModel(text: tag)
            self.showDetailViewController(detailController, sender: self)
            controller.reloadContent()
        } else {
            self.updateRootVCToDetailNavController(rootVC: getTagsVC(for: tag))
        }
    }

    func showSettings() {
        let storyboard = UIStoryboard(name: "FTNewSettings", bundle: nil);
        if let settingsController = storyboard.instantiateViewController(withIdentifier: "FTGlobalSettingsController") as? FTGlobalSettingsController {
            let navController = UINavigationController(rootViewController: settingsController)
            navController.modalPresentationStyle = .formSheet
            self.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        }
    }
    func emptyTrash(_ collection: FTShelfItemCollection, showConfirmationAlert: Bool, onCompletion: @escaping ((Bool) -> Void)) {
        if showConfirmationAlert {
            let alertController = UIAlertController(title: "trash.alert.title".localized, message: nil, preferredStyle: UIAlertController.Style.alert)
            let emptyTrashAction = UIAlertAction(title: "shelf.emptyTrash".localized, style: .destructive) { _ in
                FTNoteshelfDocumentProvider.emptyTrashCollection(collection, onController: self) {
                    onCompletion(true)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel".localized, style: .default)
            alertController.addAction(cancelAction)
            alertController.addAction(emptyTrashAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            FTNoteshelfDocumentProvider.emptyTrashCollection(collection, onController: self) {
                onCompletion(true)
            }
        }
    }
     func saveLastSelectedCollection(_ collection: FTShelfItemCollection?) {
         self.isInNonCollectionMode = false
         if let rootController = self.parent as? FTRootViewController, let selectedCollection = collection {
             rootController.setLastSelectedCollection(selectedCollection.URL)
         }
     }
    func showDetailedViewForCollection(_ collection: FTShelfItemCollection) {
        if !self.isRegularClass()  { // In Compact modes, on every tap of sidebar option we are navigating to respective detailed view
            showCategoryDetaiedVC()
        } else if (currentShelfViewModel?.collection.uuid != collection.uuid || currentShelfViewModel?.groupItem != nil) { // In regular modes, avoiding refreshing shelf again if current category is same as recent tapped category. Note: If shelf is showing group, even on tapping current category, we are popping to categories detailed view.
            showCategoryDetaiedVC()
        }

        func showCategoryDetaiedVC() {
            if detailNavigationController != nil {
                detailNavigationController?.popToRootViewController(animated: false)
            }
            let secondaryViewController = getSecondaryViewControllerWith(collection: collection, groupItem: nil)
            self.shelfItemCollection = collection
            self.updateRootVCToDetailNavController(rootVC: secondaryViewController)
            if let detailNavVC = detailNavigationController {
                detailNavVC.viewControllers.first?.title = collection.displayTitle
            }
        }
    }

    func openTemplates() {
        if let detailController = self.detailController(), detailController.isKind(of: FTStoreContainerViewController.self) {
            self.showDetailViewController(detailController, sender: self)
        } else {
            self.updateRootVCToDetailNavController(rootVC: getTemplatesVC())
        }
    }

    func openPhotos() {
        if let detailController = self.detailController(), detailController.isKind(of: FTShelfContentPhotoViewController.self) {
            self.showDetailViewController(detailController, sender: self)
        } else {
            self.updateRootVCToDetailNavController(rootVC: getPhotosVC())
        }
    }

    func openAudio() {
        if let detailController = self.detailController(), detailController.isKind(of: FTShelfContentAudioViewController.self)  {
            self.showDetailViewController(detailController, sender: self)
        } else {
            self.updateRootVCToDetailNavController(rootVC: getAudioVC())
        }
    }
    
    func didTapOnCategoriesOverlay() {
        self.exitFromGlobalSearch()
    }

    func detailController() -> UIViewController? {
        if let detailController = self.viewController(for: .secondary) as? UINavigationController, let controller = detailController.viewControllers.first {
            return controller
        }
        return nil
    }
    private func updateRootVCToDetailNavController(rootVC: UIViewController) {
        self.detailNavigationController = UINavigationController(rootViewController: rootVC)
        if let detailNavVC = detailNavigationController {
            detailNavVC.navigationBar.prefersLargeTitles = true
            self.showDetailViewController(detailNavVC, sender: self)
        }
    }
    private func getTemplatesVC() -> UIViewController {
        return FTStoreContainerViewController.templatesStoreViewController(delegate: self,premiumUser: FTIAPManager.shared.premiumUser)
    }
    private func getPhotosVC() -> UIViewController {
        FTShelfContentPhotoViewController(delegate: self, menuOverlayInfo: shelfMenuDisplayInfo)
    }
    private func getAudioVC() -> UIViewController {
        FTShelfContentAudioViewController(delegate: self, menuOverlayInfo: shelfMenuDisplayInfo)
    }
    private func getBookmarkVC() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTShelfBookmarksViewController") as? FTShelfBookmarksViewController else {
            fatalError("FTShelfBookmarksViewController doesnt exist")
        }
        viewController.delegate = self
        return viewController
    }
    private func getTagsVC(for selectedTag: String) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "FTShelfTagsViewController") as? FTShelfTagsViewController else {
            fatalError("FTShelfTagsViewController doesnt exist")
        }
        viewController.delegate = self
        viewController.selectedTag = (selectedTag == "sidebar.allTags".localized) ? nil : FTTagModel(text: selectedTag);
        return viewController
    }
    
    func getViewControllerBasedOn(sideBarItemType: FTSideBarItemType, selectedTag: String = "") -> UIViewController {
        self.isInNonCollectionMode = true
        if sideBarItemType == .home {
            return getSecondaryViewControllerForHomeOption()
        } else if sideBarItemType == .media {
            return getPhotosVC()
        } else if sideBarItemType == .audio {
            return getAudioVC()
        } else if sideBarItemType == .bookmark{
            return getBookmarkVC()
        } else if sideBarItemType == .tag {
            return getTagsVC(for: selectedTag)
        } else {
            return getTemplatesVC() // templates
        }
    }
    func updateSidebarCollections(){
        self.sideMenuController?.updateSideMenuItemsCollections()
    }
 }

extension FTShelfSplitViewController: FTStoreContainerDelegate {
    func trackEvent(event: String, params: [String : Any]?, screenName: String?) {
        track(event, params: params, screenName: screenName)
    }

    func storeController(_ controller: UIViewController, menuShown isMenuShown: Bool) {
        if let splitContorller = controller.splitViewController as? FTShelfSplitViewController {
            splitContorller.shelfMenuDisplayInfo.isMenuShown = isMenuShown;
        }
    }

    func createNotebookFor(url: URL, onCompletion: @escaping ((Error?) -> Void)) {
        if(!FTDeveloperOption.bookScaleAnim) {
            self.presentedViewController?.dismiss(animated: true)
        }
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection({ collection in
            if let coll = collection {
                let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("shelf.newNotebook.creating", comment: "Creating"));
                FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection({[weak self] collection in
                    guard let self = self else {
                        return
                    }
                    if let coll = collection {
                        let fileName = url.lastPathComponent.deletingPathExtension;
                        _ = self.startImporting(url.path, title: fileName, isImageSource: false, isTemplate: true, collection: coll, groupItem: nil) { [weak self] (shelfItem, error) in
                            loadingIndicatorView.hide()
                            if let shelfItem, error == nil {
                                if FTDeveloperOption.bookScaleAnim {
                                    self?.showNotebookAskPasswordIfNeeded(shelfItem, animate: true, pin: nil, addToRecent: true, isQuickCreate: false, createWithAudio: false, onCompletion: nil)
                                }
                                else {
                                    self?.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItem, isQuickCreated: false)
                                }
                                onCompletion(nil)
                            } else {
                                onCompletion(error)
                            }
                        }
                    }
                })
            }
        })
    }

    func createNotebookForTemplate(url: URL, isLandscape: Bool, isDark: Bool) {
        if(!FTDeveloperOption.bookScaleAnim) {
            self.presentedViewController?.dismiss(animated: true)
        }
        var varients = FTBasicTemplatesDataSource.shared.getDefaultVariants()
        varients.isLandscape = isLandscape
        let bgColor = isDark ? UIColor(hexString: "#1D232F") : UIColor.white
        let lineColorHex = FTBasicThemeCategory.getCustomLineColorHex(bgHex: bgColor.hexStringFromColor())
        let dict = ["colorName": FTTemplateColor.custom.displayTitle,
                    "colorHex": bgColor.hexStringFromColor(),
                    "horizontalLineColor": lineColorHex,
                    "verticalLineColor":  lineColorHex]
        let customThemeColor = FTThemeColors(dictionary: dict)
        let theme = FTStoreTemplatePaperTheme(url: url)
        varients.selectedDevice = FTDeviceDataManager().getCurrentDevice()
        varients.selectedColor = customThemeColor
        theme.customvariants = varients
        let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("shelf.newNotebook.creating", comment: "Creating"));
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection({ collection in
            if let coll = collection {

                self.createNotebookFor(theme:theme,collection: coll, groupItem: nil) { [weak self] (shelfItem, error) in
                    loadingIndicatorView.hide()
                    if let shelfItem, error == nil {
                        if FTDeveloperOption.bookScaleAnim {
                            self?.showNotebookAskPasswordIfNeeded(shelfItem, animate: true, pin: nil, addToRecent: true, isQuickCreate: false, createWithAudio: false, onCompletion: nil)
                        }
                        else {
                            self?.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItem, isQuickCreated: false)
                        }
                    }
                }
            }
        })
    }
    
    func storeController(_ controller: UIViewController,showIAPAlert feature: String?) {
        if let inFeature = feature {
            FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: inFeature, on: controller);
        }
        else {
            FTIAPurchaseHelper.shared.showIAPAlert(on: controller);
        }
    }

    func createNotebookForDairy(fileName: String, title: String, startDate: Date, endDate: Date, coverImage: UIImage, isLandScape: Bool) {
        if(!FTDeveloperOption.bookScaleAnim) {
            self.presentedViewController?.dismiss(animated: true)
        }

        let stockFolder = "StockPapers";
        let url1 = Bundle.main.url(forResource: stockFolder, withExtension: "bundle")!;
        let subFiles = try? FileManager.default.contentsOfDirectory(at: url1, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let planner = subFiles?.filter { $0.lastPathComponent == "\(fileName).nsp" }
        if let plannerUrl = planner?.first {
            if let theme = FTTheme.theme(url: plannerUrl, themeType: .papers) as? FTAutoTemlpateDiaryTheme {
                theme.startDate = startDate
                theme.endDate = endDate

                var varients = FTBasicTemplatesDataSource.shared.getDefaultVariants()
                varients.isLandscape = isLandScape
                varients.selectedDevice = FTDeviceDataManager().getCurrentDevice()
                (theme as FTPaperTheme).setPaperVariants(varients)

                var coverinfo = coverThemeForDiary(for: fileName)
                if coverinfo == nil {
                    //Fall back to cover generation in case any covers are missed in bundle.
                    coverinfo = FTCoverDataSource.shared.generateCoverTheme(image: coverImage, coverType: .custom, shouldSave: false, isDiary: true)
                }
                let notebookDetails = FTNewNotebookDetails(coverTheme: coverinfo, paperTheme: theme, title: title)
                FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection({ [weak self] collection in
                    guard let self = self else { return }
                    if let collection {
                        self.createNewNotebookInside(collection: collection, group: self.groupItemIfExists, notebookDetails: notebookDetails, isQuickCreate: false,mode:.quickCreate) { error, shelfItem in
                            if let shelfItem {
                                self.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItem, isQuickCreated: false)
                            }
                        }
                    }
                })
            }

        }
    }
    
    private func coverThemeForDiary(for fileName: String) -> FTThemeable? {
        let stockFolder = "StockCovers";
        let url1 = Bundle.main.url(forResource: stockFolder, withExtension: "bundle")!;
        let subFiles = try? FileManager.default.contentsOfDirectory(at: url1, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let coverFolder = subFiles?.filter { $0.lastPathComponent == "\(fileName).nsc" }
        if let coverNscUrl = coverFolder?.first {
            return FTTheme.theme(url: coverNscUrl, themeType: .covers)
        }
        return nil
    }

    func generatePDFFile(withImages images: [UIImage]) async -> URL? {
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Importing", comment: "Importing"))
        return await withCheckedContinuation { continuation in
            FTPDFFileGenerator().generatePDFFile(withImages: images, onCompletion: {(filePath) in
                loadingIndicatorViewController.hide()
                let requiredUrl = URL(fileURLWithPath: filePath)
                continuation.resume(returning: requiredUrl)
            })
        }
    }

    func convertFileToPDF(filePath: String) async throws -> URL? {
        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Importing", comment: "Importing"))

        return try await withCheckedThrowingContinuation({ continuation in
          let _ =  FTFileImporter().convertFileToPDF(filePath: filePath) { path, error, isImageSource in
              loadingIndicatorViewController.hide()
                if let error {
                    continuation.resume(throwing: error)
                } else if let path {
                    let requiredUrl = URL(fileURLWithPath: path)
                    continuation.resume(returning: requiredUrl)
                } else {
                    let error = NSError(domain: "com.ft.unknonwn", code: -100)
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    func createNotebookFor(theme : FTTheme,
                           collection:FTShelfItemCollection,
                           groupItem:FTGroupItemProtocol?,
                           onCompletion : ((FTShelfItemProtocol?,Error?) -> Void)?)
    {
        let progress = Progress();
        progress.totalUnitCount = 1;
        progress.localizedDescription = NSLocalizedString("Saving", comment: "Saving...");
        let fileName = theme.themeFileURL.lastPathComponent.deletingPathExtension;
        let defaultCover = FTThemesLibrary(libraryType: .covers).getDefaultTheme(defaultMode: .quickCreate)
        let notebookDetails = FTNewNotebookDetails(coverTheme: defaultCover, paperTheme: theme, documentPin: nil, title: fileName)
        FTNotebookCreation().createNewNotebookInside(collection: collection, group: groupItem, notebookDetails: notebookDetails,mode: .template) { error, shelfItem in
            progress.completedUnitCount += 1;
            if(error == nil) {
                onCompletion!(shelfItem,error)
            }
            else {
                onCompletion!(nil,error);
            }
        }
    }
}
