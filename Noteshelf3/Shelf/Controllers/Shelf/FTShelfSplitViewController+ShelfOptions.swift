//
//  FTShelfSplitViewController+ShelfOptions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 28/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import PhotosUI
import FTCommon
import FTNewNotebook
import FTTemplatesStore
import SafariServices

extension FTShelfSplitViewController: FTShelfViewModelProtocol {
    func createNewNotebookInside(collection: FTShelfItemCollection,
                                 group: FTGroupItemProtocol?,
                                 notebookDetails: FTNewNotebookDetails?,
                                 isQuickCreate: Bool,
                                 mode:ThemeDefaultMode = .basic,
                                 onCompletion: @escaping (NSError?, FTShelfItemProtocol?) -> ()) {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("shelf.newNotebook.creating", comment: "Creating"));
        if isQuickCreate {
            FTNotebookCreation().quickCreateNotebook(collection: collection, group: group) {[weak self] error, shelfItem in
                loadingIndicatorView.hide()
                if error != nil {
                    runInMainThread {
                        self?.showAlertForError(error)
                    }
                }else {
                    if FTDeveloperOption.bookScaleAnim, let notebookItem = shelfItem {
                        self?.showNotebookAskPasswordIfNeeded(notebookItem,
                                                              animate: true,
                                                              pin: notebookDetails?.documentPin?.pin,
                                                              addToRecent: true,
                                                              isQuickCreate: true, createWithAudio: false,
                                                              onCompletion: nil);
                    }
                    onCompletion(error,shelfItem)
                }
            }
        } else {
            if var notebookDetails = notebookDetails {
                FTNotebookCreation().createNewNotebookInside(collection: collection, group: group, notebookDetails: notebookDetails,mode: mode) { [weak self] error, shelfItemProtocol in
                    loadingIndicatorView.hide()
                    if error != nil {
                        runInMainThread {
                            self?.showAlertForError(error)
                        }
                    }else {
                        if FTDeveloperOption.bookScaleAnim, let notebookItem = shelfItemProtocol {
                            self?.showNotebookAskPasswordIfNeeded(notebookItem,
                                                                  animate: true,
                                                                  pin: notebookDetails.documentPin?.pin,
                                                                  addToRecent: true,
                                                                  isQuickCreate: false, createWithAudio: false,
                                                                  onCompletion: nil);
                        }
                        onCompletion(error,shelfItemProtocol)
                    }
                }
            }
        }
    }

    func showInEnclosingFolder(forItem shelfItem: FTShelfItemProtocol) {
        FTCLSLog("NotebookContextMenu - Show Enclosed Folder")
        if let rootController = self.parent as? FTRootViewController{
            rootController.getShelfItemDetails(relativePath: shelfItem.URL.relativePathWRTCollection()) { (collection, _, _) in
                if let shelfCollection = collection {
                    if let parent = shelfItem.parent {
                            self.showGroup(with: parent, animate: true)
                        } else {
                            self.showCategory(shelfCollection)
                        }
                    }
                }
        }
    }
    func moveShelfItem(_ items: [FTShelfItemProtocol], ofCollection collection: FTShelfItemCollection, toGroup group: FTGroupItemProtocol?, onCompletion: @escaping (() -> Void)) {
        let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Moving", comment: "Moving"));
        FTGrouping(collection: collection, parentGroup: group).move(items) {error,movedItems in
            if error == nil {
                self.showToastMessageForMoveOperationOfShelfItems(items, withCollectionTitle: collection.displayTitle, withGroupTitle: group?.displayTitle)
            }
            loadingIndicatorView.hide()
            onCompletion()
        }
    }

    func groupShelfItems(_ items: [FTShelfItemProtocol], ofColection collection: FTShelfItemCollection,parentGroup: FTGroupItemProtocol?, withGroupTitle title: String, showAlertForGroupName: Bool, onCompletion: @escaping (() -> Void)) {
        if showAlertForGroupName {
            self.showAlertOn(viewController: self, title: "Group Title", message: "", textfieldPlaceHolder: "Group", submitButtonTitle: "Create Group", cancelButtonTitle: "Cancel") { title in
                var groupTitle: String = "Group"
                if let title = title, !title.isEmpty {
                    groupTitle = title
                }
                let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Grouping", comment: "Grouping"));
                self.groupShelfItems(items, ofColection: collection, parentGroup: parentGroup, withGroupTitle: groupTitle) {error,groupItem in
                    if error == nil {
                        self.showToastMessageForMoveOperationOfShelfItems(items, withCollectionTitle: collection.displayTitle, withGroupTitle: groupItem?.displayTitle)
                    }
                    loadingIndicatorView.hide()
                    onCompletion()
                }
            } cancelAction: {
                onCompletion()
            }
        }else{
            let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Grouping", comment: "Grouping"));
            self.groupShelfItems(items, ofColection: collection, parentGroup: parentGroup, withGroupTitle: title) { error,groupItem in
                if error == nil {
                    self.showToastMessageForMoveOperationOfShelfItems(items, withCollectionTitle: collection.displayTitle, withGroupTitle: groupItem?.displayTitle)
                }
                loadingIndicatorView.hide()
                onCompletion()
            }
        }
    }

    func shareShelfItems(_ items: [FTShelfItemProtocol], onCompletion: @escaping (() -> Void)) {
        self.shareNotebooksOrGroups(items, onCompletion: onCompletion)
    }

    func beginImportingOfContentTypes(_ items: [FTImportItem], completionHandler: ((Bool, [FTShelfItemProtocol]) -> Void)?) {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        self.beginImporting(items: items, completionHandler: completionHandler)
    }

    func changeCoverForShelfItem(_ items: [FTShelfItemProtocol], withTheme theme: FTThemeable, onCompletion: @escaping (() -> Void)) {
            var selectedItemsSet = Set<String>()
            selectedItemsSet = Set(items.compactMap({$0.uuid}))

            let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Saving", comment: "Saving"));

            func updateCoverForCurrentItem() {

                let uuid = selectedItemsSet.first!;
                if let shelfItem = items.first(where: {uuid == $0.uuid}) {
                    if let document = FTDocumentFactory.documentForItemAtURL(shelfItem.URL) as? FTNoteshelfDocument {
                        if document.isPinEnabled() {
                            authenticateDocument(document, shelfItem);
                        }
                        else {
                            openAndUpdateCover(for: shelfItem, pin: nil);
                        }
                    }
                }
            }

            func authenticateDocument(_ document: FTNoteshelfDocument, _ shelfItem: FTShelfItemProtocol) {
                FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                             onviewController: self)
                { (pin, success,_) in
                    if(success) {
                        openAndUpdateCover(for: shelfItem, pin: pin);
                    }
                    else {
                        processNextItemIfNeeded();
                    }
                }
            }

            func openAndUpdateCover(for shelfItem: FTShelfItemProtocol,pin: String?) {
                if let parent = shelfItem.parent as? FTGroupItem {
                    parent.invalidateTop3Notebooks()
                }
                let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .write);
                request.pin = pin;
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { (token, document, error) in
                    if let _document = document, let nsDoc = _document as? FTNoteshelfDocument {
                        //todo update school
                        let propertyInfoPlist = shelfItem.URL.appendingPathComponent(METADATA_FOLDER_NAME).appendingPathComponent(ASSIGNMENTS_PLIST);
                        let coverStyle = FTCoverStyle.clearWhite
                        var isEncrypted: Bool = false
                        if let pin, !pin.isEmpty  {
                            isEncrypted = true
                        }
                        var isFirstPageCover = false
                        if  let firstPage = nsDoc.pages().first {
                            isFirstPageCover = firstPage.isCover
                        }
                        if !isFirstPageCover && !theme.hasCover {
                            processNextItemIfNeeded();
                        } else if !nsDoc.pages().isEmpty, let firstPage = nsDoc.pages().first as? FTThumbnailable, !theme.hasCover, isFirstPageCover {
                            //If first page is cover and no cover is selected, we should delete the first cover page
                            nsDoc.deletePages([firstPage])
                            let newImage = nsDoc.transparentThumbnail(isEncrypted: isEncrypted)
                            nsDoc.shelfImage = newImage
                            FTURLReadThumbnailManager.sharedInstance.addImageToCache(image: newImage, url: shelfItem.URL);
                            FTNoteshelfDocumentManager.shared.saveAndClose(document: _document,
                                                                           token: token) { (_) in
                                FTRecentEntries.updateImageInGroupContainerForUrl(_document.URL)
                                processNextItemIfNeeded();
                            }
                        } else {
                            updateCoverPageIfNeeded(with: theme, nsDoc: nsDoc) { error, success in
                                let newImage = nsDoc.transparentThumbnail(isEncrypted: isEncrypted)
                                nsDoc.shelfImage = newImage
                                FTURLReadThumbnailManager.sharedInstance.addImageToCache(image: newImage, url: shelfItem.URL);
                                FTNoteshelfDocumentManager.shared.saveAndClose(document: _document,
                                                                               token: token) { (_) in
                                    FTRecentEntries.updateImageInGroupContainerForUrl(_document.URL)
                                    processNextItemIfNeeded();
                                }
                            }
                        }
                    }
                    else {
                        processNextItemIfNeeded();
                    }
                }
            }
        
        func updateCoverPageIfNeeded(with theme: FTThemeable, nsDoc: FTNoteshelfDocument, onCompletion: @escaping ((NSError?, Bool) -> Void)) {
            let coverInfo = FTDocumentInputInfo()
            coverInfo.isCover = theme.hasCover
            var defaultFileURL = Bundle.main.url(forResource: "cover_template", withExtension: "pdf");
            let url = theme.themeFileURL.appendingPathComponent("template.pdf")
            if FileManager().fileExists(atPath: url.path) {
                defaultFileURL = url
            }
            var error: NSError?
            if  FileManager().fileExists(atPath: url.path) {
                let tempPath = FTUtils.copyFileToTempLoc(FTUtils.getUUID(), defaultFileURL!.path as NSString, error: &error)
                let inputUrl = Foundation.URL(fileURLWithPath: tempPath!)
                coverInfo.inputFileURL = inputUrl
                // If first page is cover, update it with selected cover page
                // Else if first page is page, insert new cover at 0 index
                if let page = nsDoc.pages().first, page.isCover {
                    nsDoc.updatePageTemplate(page: page, info: coverInfo) { error, success in
                        onCompletion(error, success)
                    }
                } else {
                    coverInfo.insertAt = 0
                    nsDoc.insertFileFromInfo(coverInfo) { success, error in
                        onCompletion(error, success)
                    }
                }
            } else {
                onCompletion(nil, false)
            }
        }

            func processNextItemIfNeeded() {
                selectedItemsSet.removeFirst();
                if selectedItemsSet.isEmpty {
                    loadingIndicatorView.hide();
                    onCompletion()
                }
                else {
                    updateCoverForCurrentItem();
                }
            }

            if !selectedItemsSet.isEmpty {
                updateCoverForCurrentItem();
            }
    }

    func showCoverViewOnShelfWith(models: [FTShelfItemViewModel]) {
        if let controller = FTChooseCoverViewController.viewControllerInstance(coverSelectionType: .changeCover, coversInfoDelegate: self, currentTheme: nil) {
            controller.coverUpdateDelegate = self
            if !models.isEmpty, let model = models.first {
                if model.coverImage.hasNoCover {
                    controller.coverImagePreview = UIImage(named: "defaultNoCover")
                } else {
                    controller.coverImagePreview = model.coverImage
                }
            }
#if !targetEnvironment(macCatalyst)
            self.present(controller, animated: true);
#else
            controller.modalPresentationStyle = .formSheet
            let navController = UINavigationController(rootViewController: controller)
            controller.title = "Covers"
            let insetBy: CGFloat = 20
            var preferedSize = self.view.frame.insetBy(dx: insetBy, dy: 0).size
            if let size = self.view.window?.windowScene?.sizeRestrictions?.minimumSize {
                preferedSize = CGSize(width: size.width - 2 * insetBy, height: size.height)
            }
            navController.navigationBar.isTranslucent = false
            self.ftPresentFormsheet(vcToPresent: navController, contentSize: preferedSize)
#endif
        }
    }

    func showMoveItemsPopOverWith(selectedShelfItems: [FTShelfItemProtocol]) {
        let shelfItemsViewModel = FTShelfItemsViewModel(selectedShelfItems: selectedShelfItems)
        shelfItemsViewModel.selectedShelfItemsForMove = selectedShelfItems
        shelfItemsViewModel.delegate = self
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: shelfItemsViewModel, purpose: .shelf)
        controller.title = ""
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        if self.traitCollection.isRegular {
            self.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        }else {
            self.ftPresentPopover(vcToPresent: navController, contentSize: CGSize(width: self.detailNavigationController?.view.frame.width ?? 330 , height: 440),hideNavBar: false)
        }
    }
    func favoriteShelfItem(_ item: FTShelfItemProtocol, toPin: Bool) {
        FTNoteshelfDocumentProvider.shared.favoriteSelectedItems([item], isToPin: toPin, onController: self)
        if toPin {
            self.showToastOfType(.addedToFavorites, withSubString: "")
        }else {
            self.showToastOfType(.removedFromFavorites, withSubString: "")
        }
        NotificationCenter.default.post(name: NSNotification.Name.shelfItemMakeFavorite, object: item, userInfo: nil)
    }
    func moveItemsToTrash(items: [FTShelfItemProtocol], _ onCompletion: (([FTShelfItemProtocol]) -> Void)?) {
        self.moveToTrash(items: items) { shelfItems in
            if !shelfItems.isEmpty {
                self.showToastMessageForMoveOperationOfShelfItems(items, withCollectionTitle: NSLocalizedString("shelf.bottomBar.trash", comment: "Trash"), withGroupTitle: nil)
            }
            onCompletion?(shelfItems)
        }
    }
    func hideCurrentGroup(animated: Bool, onCompletion: (() -> Void)?) {
        self.hideGroup(animate: true, onCompletion: onCompletion)
    }

    func showNewBookPopverOnShelf() {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        FTCreateNotebookViewController.showFromViewController(self)
    }

    func showPaperTemplateFormSheet() {
        let currentBundle = Bundle(for: FTCreateNotebookViewController.self)
        let storyboard = UIStoryboard.init(name: "FTPapers", bundle: currentBundle)
        guard let paperTemplateVc = storyboard.instantiateViewController(withIdentifier: "FTPaperTemplateViewController") as? FTPaperTemplateViewController else {
            return
        }
        paperTemplateVc.source = .shelf

        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        let dataSource = basicTemplatesDataSource.basictemplateDateSourceForMode(.quickCreate)
        let paperVariantsDataModel = FTPaperTemplatesVariantsDataModel(templateColors: dataSource.colorModel,
                                                                       lineHeights: dataSource.lineHeightsModel,
                                                                       sizes: dataSource.sizeModel)
        let selPaperTheme = FTThemesLibrary(libraryType: .papers).getDefaultTheme(defaultMode: .quickCreate)
        let variants = basicTemplatesDataSource.variantsForMode(.quickCreate)
        let selectedPaperVariantsAndTheme =
        FTSelectedPaperVariantsAndTheme(templateColorModel: variants.color,
                                        lineHeight: variants.lineHeight,
                                        orientation: variants.orientaion,
                                        size: variants.templateSize,
                                        selectedPaperTheme: selPaperTheme)
        guard let basicThemes = FTBasicTemplatesDataSource.shared.fetchThemesForMode(.quickCreate).first else{
            fatalError("Error in fetching basicThemes")
        }
        let paperTemplateDataManager = FTPaperTemplateDataHelper(variantsData: paperVariantsDataModel, selectedVariantData: selectedPaperVariantsAndTheme, basicPaperThemes: basicThemes)

        paperTemplateVc.configure(varaintsData: paperTemplateDataManager, delegate: self.currentShelfViewModel)
        let navController = FTPaperTemplateNavigationController(rootViewController: paperTemplateVc)
        paperTemplateVc.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        self.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
    }

    func showDropboxErrorInfoScreen() {
        let storyboard = UIStoryboard(name: "FTSettings_Accounts", bundle: nil);
        if let backUpOptionsVc = storyboard.instantiateViewController(withIdentifier: FTErrorInfoViewController.className) as? FTErrorInfoViewController {
            let navController = UINavigationController(rootViewController: backUpOptionsVc)
            self.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        }
    }

    func showEvernoteErrorInfoScreen() {
        let storyboard = UIStoryboard(name: "FTSettings_Accounts", bundle: nil);
        if let settingsController = storyboard.instantiateViewController(withIdentifier: FTEvernoteSettingsViewController.className) as? FTEvernoteSettingsViewController  {
            settingsController.hideBackButton = true
            let navController = UINavigationController(rootViewController: settingsController)
            self.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        }
    }

    //TODO: (AK) Discuss with RK
    func openNotebook(_ shelfItem: FTShelfItemProtocol, shelfItemDetails: FTCurrentShelfItem?, animate: Bool, isQuickCreate: Bool, pageIndex: Int?) {
        if !shelfItem.shelfCollection.isTrash  {
            if !self.openingBookInProgress {
                self.openNotebookAndAskPasswordIfNeeded(shelfItem, animate: animate, presentWithAnimation: false, pin: shelfItemDetails?.pin, addToRecent: true, isQuickCreate: isQuickCreate,createWithAudio: false, pageIndex: pageIndex, onCompletion: nil)
            }else {
                NotificationCenter.default.post(name: NSNotification.Name.shelfItemRemoveLoader, object: shelfItem, userInfo: nil)
            }
        } else {
            UIAlertController.showAlert(withTitle: "", message: "trash.alert.cannotOpenNotebook".localized, from: self, withCompletionHandler: nil)
        }
    }
    
    func setLastOpenedGroup(_ groupURL: URL?) {
        if let rootController = self.parent as? FTRootViewController {
            rootController.setLastOpenedGroup(groupURL)
        }
    }
    func showAlertForError(_ error: NSError?) {
        let alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        let okayAction = UIAlertAction(title: NSLocalizedString("ok", comment: "ok").uppercased(), style: .default)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
    private func getSizeClass() -> AppState {
        let appState = AppState(sizeClass: .regular)
        if let sizeClass = UserInterfaceSizeClass(self.traitCollection.horizontalSizeClass) {
            appState.sizeClass = sizeClass
        }
        return appState
    }
    func deleteItems(_ items : [FTShelfItemProtocol],  shouldEmptyTrash:Bool, onCompletion: @escaping((Bool) -> Void))
    {
        let alertTitle = shouldEmptyTrash ? "trash.alert.title" : "shelf.deleteCategoryAlert.title"
        let deleteButtonTitle = shouldEmptyTrash ? "shelf.emptyTrash" : "shelf.alerts.delete"
        let alertController = UIAlertController(title: alertTitle.localized, message: nil, preferredStyle: UIAlertController.Style.alert)
        let emptyTrashAction = UIAlertAction(title: deleteButtonTitle.localized, style: .destructive) { _ in
            deleteShelfItems()
        }
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .default)
        alertController.addAction(cancelAction)
        alertController.addAction(emptyTrashAction)
        alertController.preferredAction = cancelAction
        self.present(alertController, animated: true, completion: nil)

        func deleteShelfItems() {
            var selectedItems = items;
            let totalItemsSelected = selectedItems.count;

            let progress = Progress();
            progress.isCancellable = false;
            progress.totalUnitCount = Int64(totalItemsSelected);
            progress.localizedDescription = String(format: NSLocalizedString("DeletingPagesNofN", comment: "Deleting..."), 1, totalItemsSelected);

            let smartProgress = FTSmartProgressView.init(progress: progress);
            smartProgress.showProgressIndicator(progress.localizedDescription,
                                                onViewController: self);

            func emptyItemFromTrash() {
                if let item = selectedItems.first {

                    let currentProcessingIndex = totalItemsSelected - selectedItems.count + 1;
                    let statusMsg = String(format: NSLocalizedString("DeletingPagesNofN", comment: "Deleting..."), currentProcessingIndex, totalItemsSelected);
                    progress.localizedDescription = statusMsg;

                    runInMainThread {
                        if(item is FTGroupItemProtocol) {
                            self.shelfItemCollection?.shelfItems(FTShelfSortOrder.byName,
                                                                parent: item as? FTGroupItemProtocol,
                                                                searchKey: nil,
                                                                onCompletion:
                                                                    { (items) in
                                self.shelfItemCollection?.removeShelfItem(item,
                                                                         onCompletion:
                                                                            { (error, _) in
                                    if(nil == error) {
                                        for eachItem in items {
                                            self.clearCache(documentUUID: (eachItem as? FTDocumentItemProtocol)?.documentUUID);
                                        }
                                    }
                                    progress.completedUnitCount += 1;

                                    selectedItems.removeFirst();
                                    emptyItemFromTrash();
                                });
                            });
                        }
                        else {
                            let documentUUID = (item as? FTDocumentItemProtocol)?.documentUUID;
                            self.shelfItemCollection?.removeShelfItem(item,
                                                                     onCompletion:
                                                                        { (error, _) in
                                self.clearCache(documentUUID: documentUUID);

                                progress.completedUnitCount += 1;

                                selectedItems.removeFirst();
                                emptyItemFromTrash();
                            });
                        }
                    }
                }
                else {
                    smartProgress.hideProgressIndicator();
                    let toastTitle = FTShelfToastType.deletedPermanently.getLocalisedTitleWith("")
                    let toastSubTitle = FTShelfToastType.deletedPermanently.getLocalisedSubtitleWith(items.count)
                    self.showToastWithTitle(toastTitle, subTitle: toastSubTitle)
                    onCompletion(true)
                }
            }
            emptyItemFromTrash();
        }
    }
    func duplicateDocuments(_ items : [FTShelfItemProtocol], onCompletion: @escaping((Bool) -> Void)) {

        func actualNumberOfBooks(items : [FTShelfItemProtocol]) -> Int {
            var count = 0
            for item in items {
                if item is FTDocumentItemProtocol {
                    count += 1
                } else if let group = item as? FTGroupItemProtocol {
                    if group.childrens.isEmpty {
                        count += 1
                    } else {
                        count += actualNumberOfBooks(items: group.childrens)
                    }
                }
            }
            return count
        }

        guard FTIAPManager.shared.premiumUser.canAddFewMoreBooks(count: actualNumberOfBooks(items: items)) else {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }

        FTCLSLog("Duplicating Documents");
        let dupString = NSLocalizedString("DuplicatingPagesNofN", comment: "Duplicating...");

        let duplicatingItems : [FTShelfItemProtocol] = items

        let count = duplicatingItems.count
        let currentItem = 1;

        let progress = Progress();
        progress.isCancellable = false;
        progress.totalUnitCount = Int64(count);
        progress.localizedDescription = String(format: dupString, currentItem, count);

        let smartProgressView = FTSmartProgressView.init(progress: progress);
        smartProgressView.showProgressIndicator(progress.localizedDescription, onViewController: self);
        runInMainThread {
            self.duplicateDocuments(duplicatingItems,
                                    index: 0,
                                    progress : progress,
                                    duplicatedList: [FTShelfItemProtocol](),
                                    onCompletion:
                { _ in
                onCompletion(true)
                smartProgressView.hideProgressIndicator();
            });
        };
    }
    func renameDocuments(_ items: [FTShelfItemProtocol], onCompletion: @escaping (() -> Void)) {
        var originalTitle = "";
        if items.count == 1 {
            originalTitle = items[0].displayTitle
        }
        let headerTitle: String
        if items.filter({$0 is FTGroupItemProtocol}).isEmpty { // only notebooks
            headerTitle = NSLocalizedString("NotebookTitle", comment: "Notebook Title")
        } else if items.filter({$0 is FTGroupItemProtocol}).count == items.count { //only groups
            headerTitle = NSLocalizedString("GroupTitle", comment: "Group Title");
        } else { // combination of notebooks and groups
            headerTitle = NSLocalizedString("Title", comment: "Title");
        }

        self.showAlertOn(viewController: self, title: headerTitle, message: "", textfieldPlaceHolder: originalTitle, textfiledValue: originalTitle, submitButtonTitle: NSLocalizedString("Rename", comment: "Rename"), cancelButtonTitle: NSLocalizedString("Cancel", comment: "Cancel")) { title in

            var text = title
            if(nil != text) {
                text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
            }
            if let enteredText = text,!enteredText.isEmpty, originalTitle != enteredText {
                self.renameShelfItems(items, toTitle: text!, onCompletion: onCompletion)
            }
        } cancelAction: {

        }
    }

    func showGlobalSearchController() {
        self.navigateToGlobalSearch()
    }
    
    func openGetInspiredPDF(_ url: URL,title: String) {
#if targetEnvironment(macCatalyst)
        if let doc = PDFDocument(url: url) {
            let controller = FTPDFViewController(document: doc, title: title);
            let navController = UINavigationController(rootViewController: controller);
            navController.modalPresentationStyle = .formSheet;
            navController.isModalInPresentation = true;
            self.present(navController, animated: true);
        }
#else
        let interactionContorller = UIDocumentInteractionController(url: url);
        interactionContorller.delegate = self;
        interactionContorller.name = title;
        interactionContorller.presentPreview(animated: true);
#endif
    }
    func openDiscoveryItemsURL(_ url: URL?) {
        if let url {
            let safariController = SFSafariViewController(url: url);
            safariController.modalPresentationStyle = .fullScreen
            safariController.modalTransitionStyle = .coverVertical
            self.present(safariController, animated: true);
        }
    }
}

extension FTShelfSplitViewController: FTShelfItemsViewModelDelegate {

    func shelfItemsViewController(_ viewController: FTShelfItemsViewControllerNew, didFinishPickingShelfItemsForBottomToolBar collectionShelfItem: FTShelfItemCollection!, toGroup: FTGroupItemProtocol?, selectedShelfItems:[FTShelfItemProtocol]) {
        viewController.dismiss(animated: true) {
            self.move(selectedShelfItems, toGroup: toGroup, toCollection: collectionShelfItem) { [weak self] status in
                if status {
                    self?.showToastMessageForMoveOperationOfShelfItems(selectedShelfItems, withCollectionTitle: collectionShelfItem.displayTitle, withGroupTitle: toGroup?.displayTitle)
                }
                self?.currentShelfViewModel?.addObserversForShelfItems()
                self?.currentShelfViewModel?.resetShelfModeTo(.normal)
            }
        }
    }
    func showToastMessageForMoveOperationOfShelfItems(_ shelfItems:[FTShelfItemProtocol], withCollectionTitle collectionTitle: String, withGroupTitle groupTitle: String?){
        let movedItemsCount = shelfItems.count
        let selectedItemsHasOnlyNotebooks: Bool = shelfItems.first(where: {$0 is FTGroupItemProtocol}) == nil ? true: false
        let selectedItemsHasOnlyGroups: Bool = shelfItems.filter({$0 is FTGroupItemProtocol}).count == movedItemsCount ? true : false
        let selectedItemsHasBothNotebooksAndGroups: Bool = (selectedItemsHasOnlyNotebooks || selectedItemsHasOnlyGroups) ? false : true
        let title:String = groupTitle != nil ? FTShelfToastType.movedItems.getLocalisedTitleWith(groupTitle ?? "") :
        FTShelfToastType.movedItems.getLocalisedTitleWith(collectionTitle)
        let subTitle:String
        if selectedItemsHasBothNotebooksAndGroups {
            subTitle = FTShelfToastType.movedItems.getLocalisedSubtitleWith(movedItemsCount)
        }else if selectedItemsHasOnlyNotebooks {
            subTitle = FTShelfToastType.movedNotebooks.getLocalisedSubtitleWith(movedItemsCount)
        }else {
            subTitle = FTShelfToastType.movedGroups.getLocalisedSubtitleWith(movedItemsCount)
        }
        self.showToastWithTitle(title, subTitle: subTitle)
    }
    func createNewCategporyForMoving(selectedShelfItems: [FTShelfItemProtocol],
                                      viewController: FTShelfItemsViewControllerNew) {
        self.showAlertOn(viewController: viewController,
                         title: NSLocalizedString("shelf.alert.newCategoryTitle", comment: "New Category"),
                           message:"" ,
                           textfieldPlaceHolder: NSLocalizedString("shelf.alert.newCategoryTextFieldPlaceHolder", comment: "New Category"),
                           submitButtonTitle: NSLocalizedString("save", comment: "Save"),
                           cancelButtonTitle: NSLocalizedString("shelf.alert.cancel", comment: "Cancel")) { title in
            var categoryTitle: String? = title;
            if(nil != title) {
                categoryTitle = title!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
            }
            if(nil == title || title!.isEmpty) {
                categoryTitle = NSLocalizedString("NewCategory", comment: "Untitle");
            }
            viewController.dismiss(animated: true) {
                self.currentShelfViewModel?.addObserversForShelfItems()
                if let newtitle = categoryTitle?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                    FTNoteshelfDocumentProvider.shared.createShelf(newtitle, onCompletion: { [weak self] (error, collection) in
                        if nil == error, let newCollection = collection {
                            self?.move(selectedShelfItems, toGroup: nil, toCollection: newCollection, completion: { status in
                                self?.currentShelfViewModel?.resetShelfModeTo(.normal)
                            })
                        }
                    });
                }
            }
        } cancelAction: {
            
        }
    }
    func createNewGroupForMoving(selectedShelfItems: [FTShelfItemProtocol],
                                 atShelfItemCollection shelfItemCollection: FTShelfItemCollection,
                                 inGroup: FTGroupItemProtocol?,
                                 viewController: FTShelfItemsViewControllerNew){
        self.showAlertOn(viewController: viewController,
                         title: NSLocalizedString("shelf.alert.newGroupTitle", comment: "New Group"),
                           message:"",
                           textfieldPlaceHolder: NSLocalizedString("shelf.alert.newGroupTextFieldPlaceHolder", comment: "New Group"),
                         submitButtonTitle: NSLocalizedString("ok", comment: "ok").uppercased(),
                           cancelButtonTitle: NSLocalizedString("shelf.alert.cancel", comment: "Cancel")) { title in
            var categoryTitle: String? = title;
            if(nil != title) {
                categoryTitle = title!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
            }
            if(nil == title || title!.isEmpty) {
                categoryTitle = NSLocalizedString("Group", comment: "Untitle");
            }
            viewController.dismiss(animated: true) {
                self.currentShelfViewModel?.addObserversForShelfItems()
                if let newtitle = categoryTitle?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                    shelfItemCollection.createGroupItem(newtitle,
                                                        inGroup: inGroup,
                                                        shelfItemsToGroup: nil) { [weak self] (error, groupItem) in
                        if error == nil {
                            self?.move(selectedShelfItems, toGroup: groupItem, toCollection: shelfItemCollection, completion: { status in
                                self?.currentShelfViewModel?.resetShelfModeTo(.normal)
                            })
                        }
                    }
                }
            }
        } cancelAction: {

        }
    }
}
//MARK: Alert with textfield
extension FTShelfSplitViewController {
    func showAlertOn(viewController: UIViewController,
                     title: String,
                     message: String,
                     textfieldPlaceHolder: String,
                     textfiledValue:String = "",
                     submitButtonTitle : String,
                     cancelButtonTitle: String,
                     submitAction: @escaping (_ title:String?) -> (),
                     cancelAction: @escaping () -> ()){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.setDefaultStyle(.defaultStyle);
            textField.setStyledPlaceHolder(textfieldPlaceHolder, style: .defaultStyle);
            textField.autocapitalizationType = UITextAutocapitalizationType.words;
            textField.setStyledText(textfiledValue);
        }
        let mainAction = UIAlertAction(title: submitButtonTitle, style: .default ) { _ in
            let textField = alertController.textFields![0] as UITextField
            submitAction(textField.text)
        }
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            cancelAction()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(mainAction)
        alertController.preferredAction = mainAction
        viewController.present(alertController, animated:true)
    }
    fileprivate func duplicateDocuments(_ documents : [FTShelfItemProtocol],
                                        index : Int,
                                        progress : Progress,
                                        duplicatedList: [FTShelfItemProtocol],
                                        onCompletion:@escaping (([FTShelfItemProtocol]) -> Void))
    {
        if(index < documents.count) {
            let str = String.init(format: NSLocalizedString("DuplicatingPagesNofN", comment: "Duplicating..."), index+1, documents.count);
            progress.localizedDescription = str;

            runInMainThread({
                let doucmentItem = documents[index];
                if let groupItem = doucmentItem as? FTGroupItemProtocol, let collection = groupItem.shelfCollection {
                    self.createGroup(name: groupItem.title,
                                     inGroup: groupItem.parent,
                                     items: [],
                                     shelfCollection: collection,
                                     onCompeltion: { (_, duplicatedGroup) in
                                        self.duplicateGroupItems(items: groupItem.childrens, toGroup: duplicatedGroup) { (_, duplicatedGroup) in
                                            var duplicated = duplicatedList
                                            if let duplicatedGroup = duplicatedGroup {
                                                duplicated.append(duplicatedGroup)
                                                self.duplicateDocuments(documents,
                                                                        index: index + 1,
                                                                        progress : progress,
                                                                        duplicatedList: duplicated,
                                                                        onCompletion: onCompletion);
                                                progress.completedUnitCount += 1;
                                            } else {
                                                self.duplicateDocuments(documents,
                                                                        index: index + 1,
                                                                        progress : progress,
                                                                        duplicatedList: duplicated,
                                                                        onCompletion: onCompletion);
                                                progress.completedUnitCount += 1;
                                            }
                                        }
                                     })
                } else {
                    FTDocumentFactory.duplicateDocumentAtURL(doucmentItem.URL, onCompletion: { (_, document) in
                        if let duplicatedDocument = document {
                            doucmentItem.shelfCollection.addShelfItemForDocument(duplicatedDocument.URL,
                                                                                 toTitle: doucmentItem.title,
                                                                                 toGroup: doucmentItem.parent,
                                                                                 onCompletion:
                                                                                    { (_, shelfItem) in
                                                                                        var duplicated = duplicatedList
                                                                                        if let item = shelfItem {
                                                                                            duplicated.append(item)
                                                                                        }
                                                                                        self.duplicateDocuments(documents,
                                                                                                                index: index + 1,
                                                                                                                progress : progress,
                                                                                                                duplicatedList: duplicated,
                                                                                                                onCompletion: onCompletion);
                                                                                        progress.completedUnitCount += 1;
                                                                                    });
                        }
                        else {
                            self.duplicateDocuments(documents,
                                                    index: index + 1,
                                                    progress : progress,
                                                    duplicatedList: duplicatedList,
                                                    onCompletion: onCompletion);
                            progress.completedUnitCount += 1;
                        }
                    });
                }
            });
        }
        else {
            onCompletion(duplicatedList);
        }
    }
    private func createGroup(name: String?,
                     inGroup: FTGroupItemProtocol?,
                     items: [FTShelfItemProtocol],
                     shelfCollection: FTShelfItemCollection,
                     onCompeltion:((NSError?,FTGroupItemProtocol?)->())?)
    {
        let groupName: String;
        let groupNameWithourTrailingScpaes = name?.trimmingCharacters(in: .whitespaces);
        if let inName = groupNameWithourTrailingScpaes, !inName.isEmpty {
            groupName = inName;
        }
        else {
            groupName = NSLocalizedString("Group", comment: "Group")
        }

        shelfCollection.createGroupItem(groupName,
                                        inGroup: inGroup,
                                        shelfItemsToGroup: items)
        { [weak self] (error, groupItem) in
            if nil == error {
                self?.updatePublishedRecords(itmes: items,
                                             isDeleted: false,
                                             isMoved: true);
            }
            onCompeltion?(error,groupItem);
        }
    }
    private func duplicateGroupItems(items: [FTShelfItemProtocol],
                                         toGroup: FTGroupItemProtocol?,
                                         onCompletion:@escaping ((NSError?, FTGroupItemProtocol?) -> Void)) {
        var originalGroupItems = items
        if originalGroupItems.isEmpty {
            onCompletion(nil, toGroup)
            return
        }
        let eachItem = originalGroupItems.removeFirst()
        if let groupItem = eachItem as? FTGroupItemProtocol {
            self.duplicateGroup(groupItem, toGroup: toGroup) { (error, group) in
                self.duplicateGroupItems(items: originalGroupItems, toGroup: toGroup) { error, group in
                    onCompletion(error, group)
                }
            }
        }
        else {
            FTDocumentFactory.duplicateDocumentAtURL(eachItem.URL) { (error, document) in
                if let doc = document {
                    toGroup?.shelfCollection.addShelfItemForDocument(doc.URL,
                        toTitle: eachItem.title,
                        toGroup: toGroup,
                        onCompletion: { (_, _) in
                            self.duplicateGroupItems(items: originalGroupItems, toGroup: toGroup) { error, group in
                                //self.reloadSnapShot(with: false)
                                onCompletion(error, group)
                            }
                        })
                }
                else {
                    onCompletion(error, toGroup)
                }
            }
        }
    }
    private func duplicateGroup(_ groupItem : FTGroupItemProtocol,
                        toGroup: FTGroupItemProtocol?,
                        onCompletion:@escaping ((NSError?, FTGroupItemProtocol?) -> Void)) {
        guard let collection = groupItem.shelfCollection else {
            onCompletion(NSError.init(domain: "DuplicateError", code: 1000, userInfo: nil), nil)
            return;
        }

        self.createGroup(name: groupItem.title,
                         inGroup: toGroup,
                         items: [],
                         shelfCollection: collection,
                         onCompeltion: { (_, duplicatedGroup) in
                            self.duplicateGroupItems(items: groupItem.childrens, toGroup: duplicatedGroup) { (nsError, duplicatedGroup) in
                                onCompletion(nsError, duplicatedGroup)
                            }
                         })
    }
    private func renameShelfItems(_ itemsToRename: [FTShelfItemProtocol], toTitle title: String, onCompletion: @escaping (() -> Void)) {
        var renameItems = itemsToRename

        let totalItemsSelected = itemsToRename.count;
        let progress = Progress();
        progress.isCancellable = false;
        progress.totalUnitCount = Int64(totalItemsSelected);
        progress.localizedDescription = String(format: NSLocalizedString("RenamingBooksNofN", comment: "Renaming..."), 1, totalItemsSelected);

        let smartProgress = FTSmartProgressView.init(progress: progress);
        smartProgress.showProgressIndicator(progress.localizedDescription,
                                            onViewController: self);
        //********************
        func renameEachShelfItem(_ shelfItem: FTShelfItemProtocol, ofShelfItemCollection shelfItemCollection: FTShelfItemCollection) {
            let currentProcessingIndex = totalItemsSelected - renameItems.count;
            let statusMsg = String(format: NSLocalizedString("RenamingBooksNofN", comment: "Renaming..."), currentProcessingIndex, totalItemsSelected);
            progress.localizedDescription = statusMsg;

            runInMainThread {

                shelfItemCollection.renameShelfItem(shelfItem, toTitle: title, onCompletion: {[weak self] (error, updatedShelfItem) in
                    guard let `self` = self else {
                        smartProgress.hideProgressIndicator();
                        return
                    }
                    if(nil != error) {
                        smartProgress.hideProgressIndicator();
                        UIAlertController.showConfirmationDialog(with: error!.description, message: "", from: self, okHandler: {
                        });
                    }
                    else {
                        //**************************
                        if let documentItem = updatedShelfItem as? FTDocumentItemProtocol, let docUUID = documentItem.documentUUID {
                            FTCloudBackUpManager.shared.startPublish();

                            if let shelfItem = updatedShelfItem,
                                FTENPublishManager.shared.isSyncEnabled(forDocumentUUID: docUUID) {
                                FTENPublishManager.recordSyncLog("User renamed notebook: \(String(describing: shelfItem.displayTitle))");

                                let evernotePublishManager = FTENPublishManager.shared;
                                evernotePublishManager.updateSyncRecord(forShelfItem: shelfItem,
                                                                        withDocumentUUID: docUUID);
                                evernotePublishManager.startPublishing();
                            }
                            progress.completedUnitCount += 1
                            if !renameItems.isEmpty{
                                performRenameOperation()
                            }
                            else {
                                resetToNormalState()
                            }
                        } else if let _ = updatedShelfItem as? FTGroupItemProtocol {
                            progress.completedUnitCount += 1
                            if !renameItems.isEmpty{
                                performRenameOperation()
                            }
                            else {
                                resetToNormalState()
                            }
                        }
                        else {
                            resetToNormalState()
                        }
                    }
                })
            }
        }
        //********************

        //********************
        func resetToNormalState() {
            smartProgress.hideProgressIndicator();
            onCompletion()
        }
        //********************

        func performRenameOperation(){
            let shelfItem = renameItems.removeFirst()
            if shelfItem.shelfCollection.isStarred {
                self.getShelfItemFromSource(shelfItem) { shelfItemProcotol in
                    if let renamingShelfItem = shelfItemProcotol {
                        renameEachShelfItem(renamingShelfItem, ofShelfItemCollection: renamingShelfItem.shelfCollection)
                    }else{
                        resetToNormalState()
                    }
                }
            } else {
                renameEachShelfItem(shelfItem, ofShelfItemCollection: shelfItem.shelfCollection)
            }
        }
        if !renameItems.isEmpty {
            performRenameOperation()
        }
        else {
            resetToNormalState()
        }
    }
    func getShelfItemFromSource(_ item: FTShelfItemProtocol,onCompeltion : @escaping (FTShelfItemProtocol?)->()) {
        var collectionName: String?
        let relativePath = item.URL.relativePathWRTCollection();
        if let _collectionName = relativePath.collectionName() {
            collectionName = _collectionName.deletingPathExtension;
        }
        FTNoteshelfDocumentProvider.shared.shelfCollection(title: collectionName) { (shelfitemcollection) in
            if let collection = shelfitemcollection {
                var groupItem : FTGroupItemProtocol?;
                if let groupPath = relativePath.relativeGroupPathFromCollection() {
                    let url = collection.URL.appendingPathComponent(groupPath);
                    groupItem = collection.groupItemForURL(url);
                }
                let shelfItem = collection.documentItemWithName(title: relativePath.documentName(), inGroup: groupItem);
                onCompeltion(shelfItem)
            }else {
                onCompeltion(nil)
            }
        }
    }
    func groupShelfItems(_ items: [FTShelfItemProtocol], ofColection collection: FTShelfItemCollection,parentGroup: FTGroupItemProtocol?, withGroupTitle title: String, onCompletion: @escaping ((NSError?,FTGroupItemProtocol?)->())) {
            FTGrouping(collection: collection, parentGroup: parentGroup).createGroup(name: title, items: items) { error, groupItem in
                onCompletion(error, groupItem)
            }
    }
}
extension FTShelfSplitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return FTUtils.validateFileName(fromTextField: textField, shouldChangeCharactersIn: range, replacementString: string);
    }
}

extension FTShelfSplitViewController: FTShelfNewNoteDelegate {
    func didTapAudioNote() {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        self.createAudioNotebook()
    }
    func didTapPhotoLibrary() {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        FTPHPicker.shared.presentPhPickerController(from: self, selectionLimit: 1)
    }

    func didTapTakePhoto() {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        FTImagePicker.shared.showImagePickerController(from: self)
    }

    func didClickImportNotebook() {
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        if(nil == self.importFileHandler) {
            self.importFileHandler = FTImportFileHandler(withDelegate: self);
        }
        self.importFileHandler?.importFile(onViewController: self);
    }
    
    func didTapOnNewGroup() {
        self.showAlertOn(viewController: self, title: "Group Title", message: "", textfieldPlaceHolder: "Group", submitButtonTitle: "Create Group", cancelButtonTitle: "Cancel") {[weak self] title in
            guard let self = self else {
                return
            }
            var groupTitle: String = "Group"
            if let title = title, !title.isEmpty {
                groupTitle = title
            }
            if let collection = self.currentShelfViewModel?.collection {
                self.currentShelfViewModel?.removeObserversForShelfItems()
                let loadingIndicatorView =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Grouping", comment: "Grouping"));
                self.createGroup(name: groupTitle, inGroup: self.currentShelfViewModel?.groupItem, items: [], shelfCollection: collection) { error, group in
                    loadingIndicatorView.hide()
                    self.currentShelfViewModel?.addObserversForShelfItems()
                    if let group {
                        self.showGroup(with: group, animate: true)
                    }
                }
            }
        } cancelAction: {}
    }
    
    func didClickScanDocument(){
        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            return;
        }
        let scanService = FTScanDocumentService.init(delegate: self);
        scanService.startScanningDocument(onViewController: self);
    }
}

extension FTShelfSplitViewController: FTPHPickerDelegate {

    func didFinishPicking(results: [PHPickerResult], photoType: PhotoType) {
        if photoType != .photoLibrary {
            return
        }
        FTPHPicker.shared.processResultForUIImages(results: results) { phItems in
            let images = phItems.map { $0.image }
            if images.count == 0 {
                return
            }

            let progress = Progress()
            progress.totalUnitCount = Int64(1)
            progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");

            let ftsmartMessage = FTSmartProgressView.init(progress: progress)
            ftsmartMessage.showProgressIndicator(NSLocalizedString("Importing", comment: "Importing..."),
                                                 onViewController: self)

            self.currentShelfViewModel?.removeObserversForShelfItems()
            FTPDFFileGenerator().generatePDFFile(withImages: Array(images), onCompletion: {(filePath) in
                let subProcess = self.startImporting(filePath, title: "Untitled", isImageSource: true, collection: self.shelfItemCollection, groupItem: self.currentShelfViewModel?.groupItem) { [weak self] shelfItem, error in
                    progress.completedUnitCount += 1
                    ftsmartMessage.hideProgressIndicator();
                    if error == nil {
                        if let shelfItemProtocol = shelfItem {
                            self?.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItemProtocol, isQuickCreated: false)
                        }
                    } else {
                        // show failure alert or toast
                    }
                    self?.currentShelfViewModel?.addObserversForShelfItems()
                }
                progress.addChild(subProcess, withPendingUnitCount: 1);
            })
        }
    }
}

extension FTShelfSplitViewController: FTImagePickerDelegate {
    func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            let importItem = FTImportItem(item: image)
            self.currentShelfViewModel?.removeObserversForShelfItems()
            self.beginImporting(items: [importItem]) { [weak self] status, shelfItemsList in
                if status {
                    if let shelfItemProtocol = shelfItemsList.first {
                        self?.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItemProtocol, isQuickCreated: false)
                    }
                }
                self?.currentShelfViewModel?.addObserversForShelfItems()
            }
        }
    }
}

extension FTShelfSplitViewController: FTTagsViewControllerDelegate {
    func didDismissTags() {
        let items = self.selectedTagItems.values.reversed();
        self.selectedTagItems.removeAll()
        FTShelfTagsUpdateHandler.shared.updateTagsFor(items: items, completion: nil)
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

    func addTagsViewController(didTapOnBack controller: FTTagsViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func tagsViewControllerFor(items: [FTShelfItemProtocol], onCompletion: @escaping ((Bool) -> Void)) {
        var tagsItems = [FTShelfTagsItem]()
        items.forEach { item in
            if let shelfItem = item as? FTDocumentItemProtocol , let docUUID = shelfItem.documentUUID {
                let tagItem = FTTagsProvider.shared.shelfTagsItemForBook(shelfItem: shelfItem, tags: [])
                let docTags = FTCacheTagsProcessor.shared.documentTagsFor(documentUUID: docUUID)
                tagItem.setTags(docTags)
                tagsItems.append(tagItem)
            }
        }
        let tags = self.commonTagsFor(items: tagsItems)
        let tagItems = FTTagsProvider.shared.getAllTagItemsFor(tags)
        FTTagsViewController.presentTagsController(onController: self, tags: tagItems)
    }

    func didAddTag(tag: FTTagModel) {
        updateShelfTagItemsFor(tag: tag)
    }

    func didUnSelectTag(tag: FTTagModel) {
        updateShelfTagItemsFor(tag: tag)
    }

    func updateShelfTagItemsFor(tag: FTTagModel) {
        let selectedItems = (self.currentShelfViewModel?.selectedShelfItems as! [FTDocumentItemProtocol])
        if let tagModel = FTTagsProvider.shared.getTagItemFor(tagName: tag.text) {
            tagModel.updateTagForBooks(shelfItems: selectedItems) { [weak self] items in
                guard let self = self else {return}
                items.forEach { item in
                    if let docUUID = item.documentUUID {
                        self.selectedTagItems[docUUID] = item
                    }
                }
            }
        }
    }

}

extension UIBezierPath {
    convenience init(shouldRoundRect rect: CGRect, topLeftRadius: CGSize = .zero, topRightRadius: CGSize = .zero, bottomLeftRadius: CGSize = .zero, bottomRightRadius: CGSize = .zero){

        self.init()

        let path = CGMutablePath()

        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

        if topLeftRadius != .zero{
            path.move(to: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y))
        } else {
            path.move(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }

        if topRightRadius != .zero{
            path.addLine(to: CGPoint(x: topRight.x-topRightRadius.width, y: topRight.y))
            path.addCurve(to:  CGPoint(x: topRight.x, y: topRight.y+topRightRadius.height), control1: CGPoint(x: topRight.x, y: topRight.y), control2:CGPoint(x: topRight.x, y: topRight.y+topRightRadius.height))
        } else {
             path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))
        }

        if bottomRightRadius != .zero{
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y-bottomRightRadius.height))
            path.addCurve(to: CGPoint(x: bottomRight.x-bottomRightRadius.width, y: bottomRight.y), control1: CGPoint(x: bottomRight.x, y: bottomRight.y), control2: CGPoint(x: bottomRight.x-bottomRightRadius.width, y: bottomRight.y))
        } else {
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y))
        }

        if bottomLeftRadius != .zero{
            path.addLine(to: CGPoint(x: bottomLeft.x+bottomLeftRadius.width, y: bottomLeft.y))
            path.addCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius.height), control1: CGPoint(x: bottomLeft.x, y: bottomLeft.y), control2: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius.height))
        } else {
            path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y))
        }

        if topLeftRadius != .zero{
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y+topLeftRadius.height))
            path.addCurve(to: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y) , control1: CGPoint(x: topLeft.x, y: topLeft.y) , control2: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y))
        } else {
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }

        path.closeSubpath()
        cgPath = path
    }
}
extension FTShelfSplitViewController {
    func showToastOfType(_ type: FTShelfToastType, withSubString subString: String, withItemCount itemCount:Int = 1){
        let title = type.getLocalisedTitleWith(subString)
        let subTitle = type.getLocalisedSubtitleWith(itemCount)
        let toastConfig = FTToastConfiguration(title: title, subTitle: subTitle)
        FTToastHostController.showToast(from: self, toastConfig: toastConfig)
    }
    func showToastWithTitle(_ title:String,subTitle: String) {
        let toastConfig = FTToastConfiguration(title: title, subTitle: subTitle)
        FTToastHostController.showToast(from: self, toastConfig: toastConfig)
    }
}
enum FTShelfToastType {
    case addedToFavorites
    case removedFromFavorites
    case movedNotebooks
    case movedGroups
    case movedItems
    case deletedPermanently
    case trashedNotebooks
    case trashedGroups
    case trashedItems

    func getLocalisedTitleWith(_ subString:String) -> String {
        let localisedTitle: String
        switch self {
        case .addedToFavorites:
            localisedTitle = NSLocalizedString("shelf.toast.addedToStarred", comment: "Added To Starred")
        case .removedFromFavorites:
            localisedTitle = NSLocalizedString("shelf.toast.removedFromStarred", comment: "Removed From Starred")
        case .movedNotebooks,.movedGroups,.movedItems:
            localisedTitle = String(format: NSLocalizedString("shelf.toast.moved", comment: "Moved to %@"), subString)
        case .deletedPermanently:
            localisedTitle = NSLocalizedString("shelf.toast.deleted", comment: "Deleted Permanently")
        case .trashedNotebooks,.trashedGroups,.trashedItems:
            localisedTitle = NSLocalizedString("shelf.toast.trashed", comment: "Moved to Trash")
        }
        return localisedTitle
    }
    func getLocalisedSubtitleWith(_ itemCount:Int) -> String {
        let localisedSubTitle: String
        switch self {
        case .addedToFavorites,.removedFromFavorites,.movedNotebooks,.trashedNotebooks,.deletedPermanently:
            localisedSubTitle = itemCount > 1 ? String(format: NSLocalizedString("shelf.toast.subTitle.notebooks", comment: "%d notebooks"), itemCount) : NSLocalizedString("shelf.toast.subTitle.notebook", comment: "%d notebook")
        case .movedGroups,.trashedGroups:
            localisedSubTitle = itemCount > 1 ? String(format: NSLocalizedString("shelf.toast.subTitle.groups", comment: "%d groups"), itemCount) : NSLocalizedString("shelf.toast.subTitle.group", comment: "1 group")
        case .movedItems,.trashedItems:
            localisedSubTitle = String(format: NSLocalizedString("shelf.toast.subTitle.items", comment: "%d items"), itemCount)
        }
        return localisedSubTitle
    }
}
//MARK:- For Audio NB
extension FTShelfSplitViewController {
    func createAudioNotebook() {
        FTPermissionManager.isMicrophoneAvailable(onViewController: self) { [weak self] (available) in
            guard let `self` = self,available else { return }
            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                                                       from: self,
                                                                                       withText: NSLocalizedString("Creating", comment: "Creating..."))
            self.currentShelfViewModel?.removeObserversForShelfItems()
            self.createNotebookWithAudioItem(nil, isiWatchDocument: false,
                                             collection: self.shelfItemCollection,
                                             groupItem: self.currentShelfViewModel?.groupItem) { [weak self](shelfItem, error) in
                guard let `self` = self,available else { return }
                loadingIndicatorViewController.hide();
                if error == nil, let shelfItem {
                    self.currentShelfViewModel?.addObserversForShelfItems()
                    self.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItem, isQuickCreated: true)
                    self.showNotebookAskPasswordIfNeeded(shelfItem, animate: true, pin: nil, addToRecent: false, isQuickCreate: false, createWithAudio: true) { _, success in
                        //For mac, audio note will be added at FTBookSessionRootViewController level.
                        #if !targetEnvironment(macCatalyst)
                        if success, let rootController = self.parent as? FTRootViewController {
                            rootController.startRecordingOnAudioNotebook()
                        }
                        #endif
                    }
                }
            }
        }
    }
    @discardableResult  func createNotebookWithAudioItem(_ item : FTAudioFileToImport?,
                                                                isiWatchDocument: Bool,
                                                            collection:FTShelfItemCollection?,
                                                            groupItem:FTGroupItemProtocol?,
                                                                onCompletion : ((FTShelfItemProtocol?,Error?) -> Void)?) -> Progress {
        let progress = Progress();
        progress.totalUnitCount = 1;
        progress.localizedDescription = NSLocalizedString("Creating", comment: "Creating...");

        var items: [FTAudioFileToImport]?
        if let item {
            items = [item]
        }
        self.createDocumentWithAudioFiles(urls: items,
                                          isiWatchDocument: isiWatchDocument,
                                          onCompletion: {[weak self] (document, error) in
                                            progress.completedUnitCount += 1;
                                            if(nil == error) {
                                                FTCLSLog("Watch Recording : Document created");
                                                if(groupItem != nil) {
                                                    FTCLSLog("Watch Recording :  adding to group");
                                                }
                                                else {
                                                    FTCLSLog("Watch Recording :  adding to shelf");
                                                }
                                                var fileName = NSLocalizedString("shelf.createNotebook.MyNotebook", comment: "My Notebook")
                                                if let item, let itemName = item.fileName {
                                                    fileName = itemName
                                                }
                                                fileName = fileName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                                                guard let document else {
                                                    onCompletion?(nil, error)
                                                    return
                                                }
                                                collection?.addShelfItemForDocument(document.URL,
                                                                                                  toTitle: fileName,
                                                                                                  toGroup: groupItem,
                                                                                                  onCompletion:
                                                    { (inerror, item) in
                                                        if(nil != item){

                                                            //****************************** AutoBackup & AutoPublish
                                                            if nil == inerror{
                                                                FTENPublishManager.applyDefaultBackupPreferences(forItem: item, documentUUID: document.documentUUID)
                                                            }
                                                            //******************************

                                                            onCompletion?(item, error)
                                                        }
                                                        else {
                                                            if let nserror = error as NSError? {
                                                                nserror.showAlert(from: self)
                                                            }
                                                            onCompletion?(nil, error)
                                                        }

                                                });
                                            }
                                            else {
                                                FTCLSLog("Watch Recording : Document creation failed");
                                                if let nserror = error as NSError? {
                                                    nserror.showAlert(from: self)
                                                }
                                                onCompletion?(nil, error)
                                            }
        });
        return progress;
    }
    internal func createDocumentWithAudioFiles(urls : [FTAudioFileToImport]?,
                                               isiWatchDocument: Bool,
                                               onCompletion : @escaping (FTDocumentProtocol?,Error?) -> Void)
    {
        let defaultCover:FTThemeable = FTThemesLibrary(libraryType: .covers).getDefaultTheme(defaultMode: .quickCreate)

        let info = FTDocumentInputInfo();
        info.rootViewController = self;
        info.coverTemplateImage = UIImage.init(contentsOfFile: defaultCover.themeTemplateURL().path);
        info.isNewBook = true;

        let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
        let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL);
        if let watchDoc = ftdocument as? FTDocumentCreateWatchExtension {
            watchDoc.createWatchRecordingDocument(info,
                                                  audioURLS: urls,
                                                  onCompletion:
                { (error, _) in
                    if(nil != error) {
                        onCompletion(nil,error);
                    }
                    else {
                        onCompletion(ftdocument,nil);
                    }
            });
        }
    }
}
extension FTShelfSplitViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {

    }
}

#if targetEnvironment(macCatalyst)
class FTPDFViewController: UIViewController {
    private var pdfDocument: PDFDocument?;
    
    required init(document: PDFDocument,title: String?) {
        super.init(nibName: nil, bundle: nil);
        self.title = title;
        self.pdfDocument = document;
    }
        
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let pdfView = PDFView(frame: CGRect.zero);
        pdfView.displayMode = .singlePageContinuous;
        pdfView.displaysPageBreaks = true;
        pdfView.displayBox = .cropBox;
        self.view = pdfView;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        (self.view as? PDFView)?.autoScales = true;
        (self.view as? PDFView)?.document = self.pdfDocument;
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(self.didTapOnDone(_:)));
    }
    
    @objc func didTapOnDone(_ sender: Any?) {
        self.dismiss(animated: true);
    }
}
#endif
