//
//  FTFinderViewController_Delegates.swift
//  Noteshelf3
//
//  Created by Sameer on 01/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import FTNewNotebook

extension FTFinderViewController:  UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let cell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell
        if collectionView != self.collectionView || cell == nil  {
            return []
        }
        return selectedItems(at: indexPath, for: session)
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        let cell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell
        if collectionView != self.collectionView || cell == nil {
            return []
        }
        let pageItem = self.filteredPages[indexPath.row]

        var canAddToDragSession:Bool = true

        session.items.forEach { dragItem in
            if let item = dragItem.localObject as? FTThumbnailable {
                if item.uuid == pageItem.uuid {
                    canAddToDragSession = false
                }
            }
        }

        if canAddToDragSession {
            return self.selectedItems(at: indexPath, for: session)
        }

        return []
    }
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell:FTFinderThumbnailViewCell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell {
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
            let dragPreview = UIDragPreviewParameters.init()
            dragPreview.backgroundColor = UIColor.clear
            if let thumbNailImage = cell.imageViewPage {
                var itemBounds = thumbNailImage.bounds
                itemBounds.origin.x += 3
                itemBounds.origin.y += 3
                itemBounds.size.width -= 6
                itemBounds.size.height -= 6
                dragPreview.visiblePath = UIBezierPath.init(rect: thumbNailImage.convert(itemBounds, to: cell))
                return dragPreview
            }
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell:FTFinderThumbnailViewCell = collectionView.cellForItem(at: indexPath) as? FTFinderThumbnailViewCell {
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
            let dropPreview = UIDragPreviewParameters.init()
            dropPreview.backgroundColor = UIColor.clear
            if let thumbNailImage = cell.imageViewPage {
                var itemBounds = thumbNailImage.bounds
                itemBounds.origin.x += 3
                itemBounds.origin.y += 3
                itemBounds.size.width -= 6
                itemBounds.size.height -= 6
                dropPreview.visiblePath = UIBezierPath.init(rect: thumbNailImage.convert(itemBounds, to: cell))
                return dropPreview
            }
        }
        return nil
    }

    private func selectedItems(at indexPath:IndexPath,for session : UIDragSession) -> [UIDragItem] {
        //Get page Item at index
        let pageItem = self.filteredPages[indexPath.row]
        var itemProvider = NSItemProvider()
        if let item = pageItem as? NSItemProviderWriting {
            itemProvider = NSItemProvider(object: item)
        }
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = pageItem
        return [dragItem]
    }

    private func canSupportDragging() -> Bool {
        return (self.filteredPages.count == self.documentPages.count)
    }
}

extension FTFinderViewController:  UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
#if DEBUG
        debugPrint((session.items.first!).itemProvider.registeredTypeIdentifiers);
#endif

        if !collectionView.hasActiveDrag {
            return false
        }

        if collectionView != self.collectionView {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        var pages = [FTThumbnailable]()
        var indexesToRemove = [Int]()
        if coordinator.session.localDragSession != nil &&  canSupportDragging() {
            let eventName = (coordinator.items.count == 1) ? "finder_page_reordered" :  "finder_pages_reordered"
            FTFinderEventTracker.trackFinderEvent(with: eventName)
            for pageItem in coordinator.items {
                if let localObject = pageItem.dragItem.localObject as AnyObject as? FTThumbnailable,  let sourceIndexPath = pageItem.sourceIndexPath {
                    indexesToRemove.append(sourceIndexPath.row)
                    pages.append(localObject)
                }
            }
            self.filteredPages.move(fromOffsets: IndexSet(indexesToRemove), toOffset: destinationIndexPath.row)
            self.document?.movePages(pages, toIndex: destinationIndexPath.item)
            runInMainThread {
                self.document?.saveDocument { (success) in
                    FTCLSLog("Finder - Pages Moved");
                    self.createSnapShot()
                }
            }
        } else {
            //TODO: Accept items from outside
        }
    }


    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        collectionView.collectionViewLayout.invalidateLayout();
        clearFocusIndicator(collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        clearFocusIndicator(collectionView)
    }
    
    private func clearFocusIndicator(_ collectionView: UICollectionView) {
        if let layout = collectionView.collectionViewLayout as? FTFinderCollectionViewFlowLayout {
            layout.focusedUUID = nil;
            layout.invalidateLayout();
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        clearFocusIndicator(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let layout = collectionView.collectionViewLayout as? FTFinderCollectionViewFlowLayout else {
            return UICollectionViewDropProposal.init(operation: .cancel)
        }
        if let destinationIndexPath = destinationIndexPath {
            if let cell = collectionView.cellForItem(at: destinationIndexPath) as? FTFinderThumbnailViewCell {
                layout.focusedUUID = cell.page?.uuid
            } else {
                layout.focusedUUID = nil
            }
        } else {
            layout.focusedUUID = nil
        }
        layout.invalidateLayout()
        if session.localDragSession != nil {
            if !canSupportDragging() {
                return UICollectionViewDropProposal(operation: .cancel, intent: .insertAtDestinationIndexPath)
            } else {
                if let index = destinationIndexPath,  snapshotItem(for: index)  is FTPlaceHolderThumbnail {
                        return UICollectionViewDropProposal(operation: .cancel, intent: .insertAtDestinationIndexPath)
                }
                return UICollectionViewDropProposal(operation: .move)
            }
        }
        return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
    }
}

extension FTFinderViewController: FTShelfItemsMovePageDelegate {
    func shelfItemsView(_ viewController: FTShelfItemsViewControllerNew,
                        didFinishWithNewNotebookTitle title: String,
                        collection: FTShelfItemCollection,
                        group: FTGroupItemProtocol?) {
        
        if let topViewController = self.navigationController?.topViewController, topViewController == viewController {
            viewController.performSegue(withIdentifier: "UnwindToViewController", sender: self);
        }
        else {
            viewController.dismiss(animated: true, completion: nil);
        }
        
        var moveItems : NSMutableSet
        
        if updatedItem !=  nil {
            moveItems = NSMutableSet(array: updatedItem!)
        } else {
            moveItems = self.selectedPages
        }
        
        guard var selectedPages = moveItems.allObjects as? [FTThumbnailable] else {
            return;
        }
        
        selectedPages.sort(by: { (one, two) -> Bool in
            if(one.pageIndex() < two.pageIndex()) {
                return true;
            }
            return false;
        });
        
        
        let coverThemeLibrary =   FTThemesLibrary(libraryType: FTNThemeLibraryType.covers)
        let isRandomCoverEnabled = FTUserDefaults.isRandomKeyEnabled()
        let defaultCover: FTThemeable!;
        if isRandomCoverEnabled {
            defaultCover = coverThemeLibrary.getRandomCoverTheme()
        }
        else {
            defaultCover = coverThemeLibrary.getDefaultTheme(defaultMode: .quickCreate);
        }
        let defaultCoverImage = UIImage(contentsOfFile: defaultCover.themeTemplateURL().path);
        
        self.showLoading(withMessage: NSLocalizedString("Creating", comment: "Creating"));
        
        let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
        
        let info = FTDocumentInputInfo();
        info.rootViewController = self;
        info.coverTemplateImage = defaultCoverImage;
        info.overlayStyle = .clearWhite
        info.isTemplate = true;
        info.isNewBook = true;
        
        let pageCount = self.documentPages.count;
        if(selectedPages.count == pageCount) {
            _ = (self.document as? FTDocumentProtocol)?.insertPageAtIndex(pageCount);
        }
        
        if let pages = selectedPages as? [FTPageProtocol] {
            var sessionWindow = self.parent?.view.window
            if sessionWindow == nil {
                sessionWindow = self.view.window
            }
            sessionWindow?.isUserInteractionEnabled = false
            _ = (self.document as? FTDocumentProtocol)?.createDocumentAtTemporaryURL(tempDocURL, purpose: .default,
                                                                                     fromPages: pages,
                                                                                     documentInfo: info,
                                                                                     onCompletion:
                { [weak self] (success, error) in
                    if let nserror = error {
                        nserror.showAlert(from: self);
                        self?.hideLoading();
                        return;
                    }
                    collection.addShelfItemForDocument(tempDocURL,
                                                       toTitle: title,
                                                       toGroup: group)
                    { [weak self] (error, documentItem) in
                        sessionWindow?.isUserInteractionEnabled = true
                        if let shelfItem = documentItem, let weakSelf = self {
                            weakSelf.document?.deletePages(selectedPages);
                            weakSelf.delegate?.finderViewController(weakSelf,
                                                                    didSelectPages:moveItems,
                                                                    toMoveTo: shelfItem);
                            weakSelf.deselectAll();
                        }
                        else {
                            error?.showAlert(from: self);
                        }
                        self?.deselectAll();
                        self?.hideLoading();
                    }
            })
        }
        else {
            self.hideLoading();
        }
    }

    func shelfItemsViewController(_ viewController: FTShelfItemsViewControllerNew, didFinishPickingShelfItem shelfItem: FTShelfItemProtocol, isNewlyCreated: Bool) {
        guard self.document?.fileURL.resolvingSymlinksInPath() != shelfItem.URL.resolvingSymlinksInPath() else {
            UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("CannotMoveToSameNotebook", comment: "Cannot move to same notebook"), from: viewController, withCompletionHandler: nil)
            return;
        }
        
        if let topViewController = self.navigationController?.topViewController, topViewController == viewController {
            viewController.performSegue(withIdentifier: "UnwindToViewController", sender: self);
        }
        else {
            viewController.dismiss(animated: true, completion: nil);
        }
        
        let blockToExecute : (FTShelfItemProtocol) -> () = { (_shelfItem) in
            FTDocumentPasswordValidate.validateShelfItem(shelfItem: _shelfItem,
                                                         onviewController: self) { (pin, success,_) in
                if(success) {
                    self.movePage(toShelfItem: shelfItem,
                                  pin: pin,
                                  isNewlyCreated: isNewlyCreated);
                }
                
            }
        }
        
        if let documentItem = shelfItem as? FTDocumentItemProtocol , !(documentItem.isDownloaded)  {
            self.askForDownloadPermission { (shouldContinue) in
                if(shouldContinue) {
                    self.showLoading(withMessage: NSLocalizedString("Downloading", comment: "Downloading"));
                    DispatchQueue.global().async {
                        FTCLSLog("NFC - Finder item Picker: \(shelfItem.URL.title)");
                        var error : NSError?;
                        let fileCoordinator = NSFileCoordinator.init(filePresenter: nil);
                        fileCoordinator.coordinate(readingItemAt: shelfItem.URL,
                                                   options: NSFileCoordinator.ReadingOptions.forUploading,
                                                   error: &error,
                                                   byAccessor: { (_) in
                                                    while(!documentItem.isDownloaded) {
                                                        RunLoop.current.run(until: Date().addingTimeInterval(1));
                                                    }
                                                    
                                                    DispatchQueue.main.async {
                                                        self.hideLoading();
                                                        blockToExecute(shelfItem);
                                                    }
                        });
                        if(nil == error) {
                            DispatchQueue.main.async {
                                self.hideLoading();
                                error?.showAlert(from: self)
                            }
                        }
                    }                }
            }
        }
        else {
            blockToExecute(shelfItem);
        }
    }
    
    func askForDownloadPermission(_ oncompletion : @escaping (_ shouldContinue : Bool) -> ())
    {
        let alertController = UIAlertController.init(title: "finder.downloadPermissionText".localized, message: nil, preferredStyle: .alert);
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: .default) { (action) in
            oncompletion(true);
        }
        alertController.addAction(okAction);
        
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { (action) in
            oncompletion(false);
        }
        alertController.addAction(cancelAction);
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    func createNewNoteBookForMoving(atShelfItemCollection shelfItemCollection: FTShelfItemCollection, inGroup: FTGroupItemProtocol?, viewController: FTShelfItemsViewControllerNew) {
        UIAlertController.showTextFieldAlertOn(viewController: viewController,
                             title: NSLocalizedString("AddToNewNotebook", comment: "New Notebook.."),
                               textfieldPlaceHolder: NSLocalizedString("shelf.createNotebook.MyNotebook", comment: "My Notebook"),
                               submitButtonTitle: NSLocalizedString("Create", comment: "Create"),
                               cancelButtonTitle: NSLocalizedString("shelf.alert.cancel", comment: "Cancel")) { title in
                var notebookTitle: String? = title;
                if(nil != title) {
                    notebookTitle = title!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                }
                if(nil == title || title!.isEmpty) {
                    notebookTitle = NSLocalizedString("shelf.createNotebook.MyNotebook", comment: "My Notebook");
                }
                viewController.dismiss(animated: true) {
                    if let newtitle = notebookTitle?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                            self.shelfItemsView(viewController, didFinishWithNewNotebookTitle: newtitle, collection: shelfItemCollection, group: inGroup)
                    }
                }
            } cancelAction: {

            }
    }
    
    //MARK:- MovingPageToAnotherDocument
    private func movePage(toShelfItem shelfItem: FTShelfItemProtocol,
                          pin : String?,
                          isNewlyCreated: Bool) {
//        self.comingFromMovePageScreen = true;
        
        var sessionWindow = self.parent?.view.window
        if sessionWindow == nil {
            sessionWindow = self.view.window
        }
        sessionWindow?.isUserInteractionEnabled = false
        self.showLoading(withMessage: NSLocalizedString("Moving", comment: "Moving"));
        
        var moveItems : NSMutableSet
        if updatedItem !=  nil {
            moveItems = NSMutableSet(array: updatedItem!)
        } else {
            moveItems = self.selectedPages
        }
        
        
        let pageCount = self.documentPages.count;
        if(moveItems.count == pageCount) {
            _ = (self.document as! FTDocumentProtocol).insertPageAtIndex(pageCount);
        }
        
        var selectedPages = moveItems.allObjects as! [FTThumbnailable];
        selectedPages.sort(by: { (one, two) -> Bool in
            if(one.pageIndex() < two.pageIndex()) {
                return true;
            }
            return false;
        });
        
        _ = self.document?.movePages(selectedPages,
                                    toDocument: shelfItem.URL,
                                    pin: pin) { [weak self] (error) in
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "Moved  pages to \(shelfItem.displayTitle ?? " ")");
            if let weakSelf = self {
                weakSelf.delegate?.finderViewController(weakSelf, didSelectPages: moveItems, toMoveTo: shelfItem);
                weakSelf.deselectAll();
                weakSelf.hideLoading();
                sessionWindow?.isUserInteractionEnabled = true
            }
            if let _error = error {
                (_error as NSError).showAlert(from: self);
            }
        }
    }
}
