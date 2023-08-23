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
    func showHomeView() {

        if !self.isRegularClass() { // In Compact modes, we are navigating to home on every tap on home option
            showHomeDetailedVC()
        } else if let detailController = self.detailController(), !detailController.isKind(of: FTShelfHomeViewController.self) { // In regular modes, avoiding refreshing shelf again if we are already in home.
            showHomeDetailedVC()
        } else if currentShelfViewModel == nil { // Executes when shifting from non collection types to home.
            showHomeDetailedVC()
        }

        func showHomeDetailedVC(){
            if detailNavigationController != nil {
                detailNavigationController?.popToRootViewController(animated: false)
            }
            let secondaryViewController = getSecondaryViewControllerForHomeOption()
            self.updateRootVCToDetailNavController(rootVC: secondaryViewController)
            if let detailNavVC = detailNavigationController {
                detailNavVC.viewControllers.first?.title = "sidebar.topSection.home".localized
            }
        }
    }
    
    func saveLastSelectedNonCollectionType(_ type: FTSideBarItemType) {
        if let rootController = self.parent as? FTRootViewController {
            rootController.setLastSelectedNonCollectionType(type)
            if type == .home { // As home represents all notes we are sitting all notes explicitly
                self.shelfItemCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
            }
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
    
    func openTags(for tag: String){
        if let detailController = self.detailController(), let controller = detailController as? FTShelfTagsViewController {
            controller.selectedTag = (tag == "sidebar.allTags".localized) ? nil : FTTagModel(text: tag)
            self.showDetailViewController(detailController, sender: self)
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
            let alertController = UIAlertController(title: "Are you sure you want empty your Trash?", message: nil, preferredStyle: UIAlertController.Style.alert)
            let emptyTrashAction = UIAlertAction(title: "Empty Trash", style: .destructive) { _ in
                FTNoteshelfDocumentProvider.emptyTrashCollection(collection, onController: self) {
                    onCompletion(true)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .default)
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
         if let rootController = self.parent as? FTRootViewController, let selectedCollection = collection {
             rootController.setLastSelectedCollection(selectedCollection.URL)
             self.shelfItemCollection = selectedCollection
         }
     }
    func showDetailedViewForCollection(_ collection: FTShelfItemCollection) {
        if !self.isRegularClass()  { // In Compact modes, on every tap of sidebar option we are navigating to respective detailed view
            showCategoryDetaiedVC()
        } else if (currentShelfViewModel?.collection.title != collection.title || currentShelfViewModel?.groupItem != nil) { // In regular modes, avoiding refreshing shelf again if current category is same as recent tapped category. Note: If shelf is showing group, even on tapping current category, we are popping to categories detailed view.
            showCategoryDetaiedVC()
        }

        func showCategoryDetaiedVC() {
            if detailNavigationController != nil {
                detailNavigationController?.popToRootViewController(animated: false)
            }
            let secondaryViewController = getSecondaryViewControllerWith(collection: collection, groupItem: nil)
            saveLastSelectedCollection(collection)
            self.updateRootVCToDetailNavController(rootVC: secondaryViewController)
            if let detailNavVC = detailNavigationController {
                detailNavVC.viewControllers.first?.title = collection.displayTitle
            }
        }
    }

    func showSearchResultCollection(_ collection: FTShelfItemCollection) {
        self.saveLastSelectedCollection(collection)
        self.shelfItemCollection = collection
        self.sideMenuController?.selectSideMenuCollection(collection)
        let categoryVc = getSecondaryViewControllerWith(collection: collection, groupItem: nil)
        self.globalSearchController?.navigationController?.pushViewController(categoryVc, animated: true)
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

    private func detailController() -> UIViewController? {
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
        FTShelfContentPhotoViewController(delegate: self)
    }
    private func getAudioVC() -> UIViewController {
        FTShelfContentAudioViewController(delegate: self)
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
 }

extension FTShelfSplitViewController: FTStoreContainerDelegate {
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
                        _ = self.startImporting(url.path, title: fileName, isImageSource: false, collection: coll, groupItem: nil) { [weak self] (shelfItem, error) in
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
        let bgColor = isDark ? UIColor.black : UIColor.white
        let lineColorHex = FTBasicThemeCategory.getCustomLineColorHex(bgHex: bgColor.hexStringFromColor())
        let dict = ["colorName": FTTemplateColor.custom.displayTitle,
                    "colorHex": bgColor.hexStringFromColor(),
                    "horizontalLineColor": lineColorHex,
                    "verticalLineColor":  lineColorHex]
        let customThemeColor = FTThemeColors(dictionary: dict)
        let theme = FTStoreTemplatePaperTheme(url: url)
        theme.customvariants = varients
        varients.selectedDevice = FTDeviceDataManager().getCurrentDevice()
        varients.selectedColor = customThemeColor
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

                let coverinfo = FTCoverDataSource.shared.generateCoverTheme(image: coverImage, coverType: .custom, shouldSave: false)
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
        FTNotebookCreation().createNewNotebookInside(collection: collection, group: groupItem, notebookDetails: notebookDetails) { error, shelfItem in
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
