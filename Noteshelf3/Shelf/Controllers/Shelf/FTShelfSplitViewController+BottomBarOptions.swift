//
//  FTShelfSplitViewController+BottomBarOptions.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 06/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTShelfSplitViewController {

    func moveToTrash(items : [FTShelfItemProtocol],
                          _ onCompletion:(([FTShelfItemProtocol]) -> Void)?)
    {
        var notDownloadedItems = [FTShelfItemProtocol]();
        var deletedItems = items;
        items.forEach{ (eachItem) in
            if let docItem = eachItem as? FTDocumentItemProtocol, !docItem.isDownloaded {
                notDownloadedItems.append(docItem);
            }
        }
        let totalItemsSelected = deletedItems.count;
        let progress = Progress();
        progress.isCancellable = false;
        progress.totalUnitCount = Int64(totalItemsSelected);
        progress.localizedDescription = String(format: NSLocalizedString("DeletingPagesNofN", comment: "Deleting..."), 1, totalItemsSelected);

        let smartProgress = FTSmartProgressView.init(progress: progress);
        smartProgress.showProgressIndicator(progress.localizedDescription,
                                            onViewController: self);

        func deleteItems() {
            if let firstItemToDelete = deletedItems.first {
                if let collection =  firstItemToDelete.shelfCollection, collection.isStarred {
                    self.getShelfItemFromSource(firstItemToDelete) { shelfItemProtocol in
                        if let shelfItem = shelfItemProtocol {
                            moveItemToTrash(shelfItem)
                        }else {
                            smartProgress.hideProgressIndicator()
                            onCompletion?([])
                        }
                    }
                } else {
                    moveItemToTrash(firstItemToDelete)
                }
            }
            func moveItemToTrash(_ item: FTShelfItemProtocol) {
                    let currentProcessingIndex = totalItemsSelected - deletedItems.count + 1;
                    let statusMsg = String(format: NSLocalizedString("DeletingPagesNofN", comment: "Deleting..."), currentProcessingIndex, totalItemsSelected);
                    progress.localizedDescription = statusMsg;

                    runInMainThread { [weak self] in
                        if let group = item as? FTGroupItemProtocol {
                            FTNoteshelfDocumentProvider.shared.moveGroupToTrash(group) { (error, movedItems) in
                                processDeletedItems(error, items: movedItems)
                            }
                        } else {
                            FTNoteshelfDocumentProvider.shared.moveItemstoTrash([item],
                                                                            onCompletion:
                            { (error, movedItems) in
                            processDeletedItems(error, items: movedItems)
                        })
                        }
                        func processDeletedItems(_ error: NSError?, items: [FTShelfItemProtocol]) {
                            if(nil == error)
                            {
                                self?.updatePublishedRecords(itmes: items,
                                                             isDeleted: true,
                                                             isMoved: false);
                            }
                            progress.completedUnitCount += 1;
                            deletedItems.removeFirst()
                            if deletedItems.isEmpty {
                                smartProgress.hideProgressIndicator()
                                onCompletion?(items)
                            } else {
                                deleteItems()
                            }
                        }
                    }
                }
            }

        self.showAlertForDeletingNonDownloadedItems(notDownloadedItems.count,
                                                    totalItemsSelected : totalItemsSelected,
                                                    onCompletion:
            { (shouldConitnue) in
                if(shouldConitnue) {
                    deleteItems();
                }else{
                    smartProgress.hideProgressIndicator()
                }
        });
    }
    private func showAlertForDeletingNonDownloadedItems(_ totalNotDonwloaded : Int,
                                                        totalItemsSelected : Int,
                                                        onCompletion : @escaping (Bool) -> ())
    {
        if(totalNotDonwloaded == 0) {
            onCompletion(true);
        }
        else {
            var message = NSLocalizedString("DeleteBooksConfirmationNotDownloadedYet", comment: "Some notebooks are not downloaded yet..");
            if(totalItemsSelected == 1) {
                message = NSLocalizedString("DeleteBookConfirmationNotDownloadedYet", comment: "This notebook is not downloaded yet..");
            }
            let alertController = UIAlertController.init(title: message, message: nil, preferredStyle: .alert);

            let okAction = UIAlertAction.init(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (_) in
                onCompletion(true);
            });
            alertController.addAction(okAction);

            let cancel = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (_) in
                onCompletion(false);
            });
            alertController.addAction(cancel);

            self.present(alertController, animated: true, completion: nil);
        }
    }
    func updatePublishedRecords(itmes movedItems: [FTShelfItemProtocol],
                                isDeleted: Bool = false,
                                isMoved: Bool = false)
    {
        movedItems.forEach { (movedItem) in
            guard let documentItem = movedItem as? FTDocumentItemProtocol,
                let documentUUID = documentItem.documentUUID else {
                    return;
            }

            let autobackupItem = FTAutoBackupItem(URL: documentItem.URL,
                                                  documentUUID: documentUUID);
            if(isDeleted) {
                FTSiriShortcutManager.shared.removeShortcutSuggestionForUUID(documentUUID)
                FTShortcutStorage.removeShortcutDataForUUID((documentUUID))

                FTCloudBackUpManager.shared.shelfItemDidGetDeleted(autobackupItem);
            }
            else {
                FTCloudBackUpManager.shared.startPublish();
            }

            let evernotePublishManager = FTENPublishManager.shared;
            if evernotePublishManager.isSyncEnabled(forDocumentItem: documentItem) {
                if(isDeleted) {
                    FTENPublishManager.recordSyncLog("User deleted notebook: \(String(describing: documentUUID))");
                    evernotePublishManager.disableSync(for: documentItem);
                    evernotePublishManager.disableBackupForShelfItem(withUUID: documentUUID);
                }
                else {
                    evernotePublishManager.updateSyncRecord(forShelfItem: documentItem,
                                                            withDocumentUUID: documentUUID)
                }
            }
        }
    }
    func clearCache(documentUUID : String?) {
        if let docID = documentUUID {
            let thumbnailPath = URL.thumbnailFolderURL().appendingPathComponent(docID);
            try? FileManager.default.removeItem(at: thumbnailPath);
        }
    }
    func restoreShelfItem( items : [FTShelfItemProtocol],onCompletion:@escaping((Bool) -> Void)) {

        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                from: self,
                                                withText: NSLocalizedString("notebook.restoring", comment: "Restoring..."))

        startRestore(items: items, onCompletion: onCompletion)
        func startRestore(items : [FTShelfItemProtocol],onCompletion:@escaping((Bool) -> Void)){
            var itemsToMove = items;
            self.restoringItems = items

            guard !itemsToMove.isEmpty else {
                loadingIndicatorViewController.hide()
                if let toastMessage = self.restoringToastMessage, !toastMessage.isEmpty{
                    self.showToastMessage(toastMessage);
                    self.restoringToastMessage = nil
                }
                onCompletion(true)
                return;
            }
            let item = itemsToMove.removeFirst();

            var restoreBookLocation: String?
            var restoreBook = true;

            let finalizedBlock: (Error?) -> () = { [weak self] (error) in
                //self?.shelfBottomToolBar?.view.isUserInteractionEnabled = true
                if let error, error is FTPremiumUserError {
                    loadingIndicatorViewController.hide()
                    guard let self = self else { return }
                    FTIAPurchaseHelper.shared.showIAPAlert(on: self);
                    onCompletion(false)
                } else if let nsError = error as NSError? {
                    loadingIndicatorViewController.hide()
                    if !nsError.isInvalidPinError {
                        nsError.showAlert(from: self);
                    }
                    onCompletion(false)
                }
                else {
                    startRestore(items: itemsToMove, onCompletion: onCompletion)
                   //self?.restoreShelfItem(items: itemsToMove, onCompletion: onCompletion);
                }
            };
            // self.shelfBottomToolBar?.view.isUserInteractionEnabled = false
            let filePath = item.URL.appendingPathComponent(NOTEBOOK_RECOVERY_PLIST);
            if FileManager.default.fileExists(atPath: filePath.path),
               let plist = FTNotebookRecoverPlist(url: filePath, isDirectory: false,document: nil) {
                if plist.recovertType == .book {
                    guard let location = plist.recoverLocation else {
#if DEBUG || BETA
                        fatalError("Recover location missing")
#endif
                        return
                    }
                    restoreBookLocation = location;
                    try? FileManager.default.removeItem(at: filePath);
                }
                else {
                    restoreBook = false;
                    self.performContextMenuOperationForRecover(item) { (error) in
                        finalizedBlock(error)
                    }
                    track("Shelf_LongPressNB_Trash_RecoverPages", params: [:],screenName: FTScreenNames.shelfScreen)
                }
            }
            if(restoreBook) {
                let moveToUnfiled : () -> () = {
                    FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { [weak self] collectionItem in
                        if let uncategorizedCategory = collectionItem {
                            self?.restore(item,
                                          toCollection: uncategorizedCategory,
                                          group: nil,
                                          onCompletion: { (error) in
                                if let items = self?.restoringItems, items.count == 1{
                                    self?.restoringToastMessage =
                                    String(format: NSLocalizedString("NotebookRestoredToCategory", comment: "Notebook restored to %@ category."), NSLocalizedString("Uncategorized", comment: "Uncategorized"))
                                }
                                finalizedBlock(error)
                            });
                        }
                    }
                };

                if let location = restoreBookLocation {
                    FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: location) { [weak self] (collection, group, _) in
                        if let _collection = collection {
                            if let path = group?.URL.path, !path.contains(location) {
                                moveToUnfiled();
                            } else { // if group is nil(Category level) or if actual parent exists
                                self?.restore(item,
                                              toCollection: _collection,
                                              group: group,
                                              onCompletion: { (error) in
                                    if self?.restoringItems.count == 1 {
                                        self?.restoringToastMessage =
                                        String(format: NSLocalizedString("NotebookRestoredToCategory", comment: "Notebook restored to %@ category."), _collection.displayTitle)
                                    }
                                    finalizedBlock(error);
                                });
                            }
                        }
                        else {
                            moveToUnfiled();
                        }
                    }
                }
                else {
                    moveToUnfiled();
                }
            }
        }
    }
    private func restore(_ shelfItem: FTShelfItemProtocol,
                 toCollection shelfItemCollection: FTShelfItemCollection,
                 group: FTShelfItemProtocol?,
                 onCompletion: @escaping (Error?) -> ())
    {
        self.shelfItemCollection?.moveShelfItems([shelfItem],
                                            toGroup: group,
                                            toCollection: shelfItemCollection,
                                            onCompletion: { [weak self] (error, movedItems) in
                                                if(nil == error) {
                                                    self?.updatePublishedRecords(itmes: movedItems,
                                                                                 isDeleted: shelfItemCollection.isTrash,
                                                                                 isMoved: true);
                                                }
                                                onCompletion(error);
                                            });
    }

    func showToastMessage(_ message : String){
        if FTShelfThemeStyle.isDarkColorTheme(){
            showToastWith(toastMessage: message, backgroundColor: UIColor.init(hexWithAlphaString: "#3E4652-0.9"), textColor:UIColor.init(hexWithAlphaString: "#F7F7F2-1.0"))
        }else{
            showToastWith(toastMessage: message, backgroundColor: UIColor.init(hexWithAlphaString: "#FCFCFA-0.9") , textColor: UIColor.init(hexWithAlphaString: "#383838-1.0"))
        }
    }
    func showToastWith(toastMessage : String,backgroundColor : UIColor,textColor : UIColor)
    {
//        let toastView = FTToastView()
//        toastView.backgroundColor = backgroundColor
//        toastView.messageLabel.textColor = textColor
//        let widthOfToastMessage = toastMessage.widthOfString(usingFont: toastView.messageLabel.font)
//        let toastViewWidth = widthOfToastMessage + 38.0
//        self.view.layoutIfNeeded()
//        let navAndStatusBarHeight = UIApplication.shared.statusBarFrame.size.height +
//        (self.navigationController?.navigationBar.frame.height ?? 0.0)
//        let toastViewFrame = CGRect(x: self.view.frame.width/2.0 - toastViewWidth/2.0, y:navAndStatusBarHeight + 6 , width: toastViewWidth, height: 30.0)
//        toastView.showToast(frame: toastViewFrame, message: toastMessage, containerView: self.view, image: nil)
    }
    func performContextMenuOperationForRecover(_ shelfItem: FTShelfItemProtocol, completion:@escaping (Error?) -> Void) {

        let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                                                   from: self,
                                                                                   withText: NSLocalizedString("Moving", comment: "Moving..."))
        self.recoverDeletedPagesFromTrash(shelfItem) { [weak self] (shelfItemDisplayTitle,success, error) in
            if success == true {
                loadingIndicatorViewController.hide()
                let docID = (shelfItem as? FTDocumentItemProtocol)?.documentUUID;
                self?.shelfItemCollection?.removeShelfItem(shelfItem,
                                                          onCompletion:
                    { (error, _) in
                        if error == nil {
                            if let uuid = docID {
                                let thumbnailPath = URL.thumbnailFolderURL().appendingPathComponent(uuid);
                                try? FileManager.default.removeItem(at: thumbnailPath);
                            }
                            if let recoveredItemTitle = shelfItemDisplayTitle{
                                let title = recoveredItemTitle.count > 15 ? recoveredItemTitle.prefix(15) + ".." : recoveredItemTitle
                                let message = String(format: NSLocalizedString("PageRestoredToNotebook", comment: "Page has been restored to %@."), title)
                                self?.restorePageToastMessage = message
                                if self?.restoringItems.count == 1, let toastMessage = self?.restorePageToastMessage{
                                    self?.showToastMessage(toastMessage)
                                    self?.restorePageToastMessage = nil
                                }
                            }
                        }
                        /*self?.loadShelfItems(onCompletion: {
                            debugPrint("Items reloaded")
                        })*/
                });
                completion(error)
            } else {
                loadingIndicatorViewController.hide()
                guard FTIAPManager.shared.premiumUser.canAddFewMoreBooks(count: 1) else {
                    completion(FTPremiumUserError.nonPremiumError)
                    return;
                }
                if let error, error.isInvalidPinError {
                    completion(error)
                    return;
                }
                FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { [weak self] collectionItem in
                    if let uncategorizedCategory = collectionItem {
                        self?.move([shelfItem], toGroup: nil, toCollection: uncategorizedCategory, completion: { (_) in
                            completion(error)
                        })
                    }else{
                        completion(error)
                    }
                }
            }
        }
    }

    private func recoverDeletedPagesFromTrash(_ shelfItem: FTShelfItemProtocol, onCompletion: @escaping ((String?,Bool,Error?) -> Void)) {

        let options = FTFetchShelfItemOptions()
        let fileItem = FTNotebookRecoverPlist(url: shelfItem.URL.appendingPathComponent(NOTEBOOK_RECOVERY_PLIST), isDirectory: false,document: nil)
        let sourceFileDocumentUUID = fileItem?.documentUUID

        FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option:options) { (shelfItems) -> (Void) in
            if let sourceItemUUID = sourceFileDocumentUUID {
                let destinationShelfItem = shelfItems.first { (item) -> Bool in
                    if let docItem = item as? FTDocumentItemProtocol,
                       let uuid = docItem.documentUUID {
                        return uuid.caseInsensitiveCompare(sourceItemUUID) == .orderedSame
                    }
                    return false
                }

                if let destItem = destinationShelfItem {
                    let blockToOpenBook : (String?) -> () = { (pin) in
                        let openRequest = FTDocumentOpenRequest(url: destItem.URL, purpose: .write);
                        openRequest.pin = pin;
                        FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (tokenID, document, error) in
                            if let notebook = document as? FTDocumentRecoverPages {
                                _ = notebook.recoverPagesFromDocumentAt(shelfItem.URL) { (nserror) in
                                    FTNoteshelfDocumentManager.shared.closeDocument(document: document!,
                                                                                    token: tokenID) { (_) in
                                        onCompletion(destItem.displayTitle,(nserror == nil),nserror)
                                    }
                                }
                            }
                            else {
                                onCompletion(nil,false,error)
                            }
                        }
                    }

                    if destinationShelfItem != nil {
                        FTDocumentPasswordValidate.validateShelfItem(shelfItem: destItem,
                                                                     onviewController: self)
                        { (pin, success,_) in
                            if(success) {
                                blockToOpenBook(pin);
                            }
                            else {
                                onCompletion(nil,false,FTDocumentOpenErrorCode.error(.invalidPin))
                            }
                        }
                    }
                } else {
                    onCompletion(nil,false,nil)
                }
            } else {
                onCompletion(nil,false,nil)
            }
        }
    }
    func move(_ shelfItems: [FTShelfItemProtocol],
              toGroup groupShelfItem: FTGroupItemProtocol?,
              toCollection shelfItemCollection: FTShelfItemCollection, completion: @escaping (Bool) -> ()) {

        let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Moving", comment: "Moving..."));

        guard let item = shelfItems.first else {
            loadingIndicatorViewController.hide {
                completion(true)
            }
            return
        }
        item.shelfCollection.moveShelfItems(shelfItems,
                                            toGroup: groupShelfItem,
                                            toCollection: shelfItemCollection,
                                            onCompletion:
            {[weak self] (error, movedItems) in
                if nil == error {
                    self?.updatePublishedRecords(itmes: movedItems,
                                                 isDeleted: shelfItemCollection.isTrash,
                                                 isMoved: true);
                }
                loadingIndicatorViewController.hide {
                    completion(true)
                }
        });
    }
}
