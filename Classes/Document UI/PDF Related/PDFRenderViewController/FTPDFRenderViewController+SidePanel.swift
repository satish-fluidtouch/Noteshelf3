//
//  FTPDFRenderViewController+SidePanel.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 26/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

extension FTPDFRenderViewController : FTShelfItemPickerDelegate {
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingCollectionShelfItem collectionShelfItem: FTShelfItemCollection!, groupToMove groupShelfItem: FTGroupItemProtocol, toGroup: FTGroupItemProtocol?) {
        //TODO: check if this method is required to implement in the case
    }
    
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingShelfItemsForBottomToolBar collectionShelfItem: FTShelfItemCollection!, toGroup: FTGroupItemProtocol?) {

    }
    
    func shelfItemsViewControllerDidCancel(_ viewController: FTShelfItemsViewController) {
        
    }
    
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingShelfItem shelfItem: FTShelfItemProtocol, isNewlyCreated: Bool) {
        self.openNotebook(shelfItem, controllerToDismiss: viewController, addToRecent: isNewlyCreated)
    }

    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingGroupShelfItem groupShelfItem: FTGroupItemProtocol?, atShelfItemCollection shelfItemCollection: FTShelfItemCollection!, isNewlyCreated: Bool) {
        
    }
}

extension FTPDFRenderViewController : FTSidePanelShelfItemPickerDelegate {
    func currentShelfItemInSidePanelController() -> FTShelfItemProtocol? {
        return self.shelfItemManagedObject.shelfItemProtocol;
    }
    
    func currentGroupShelfItemInSidePanelController() -> FTGroupItemProtocol? {
        return self.shelfItemManagedObject.parent;
    }
}

extension FTPDFRenderViewController: FTShelfCategoryDelegate {
    func shelfCategory(_ viewController : UIViewController, didSelectShelfItem item: FTShelfItemProtocol, inCollection : FTShelfItemCollection?)
    {
        FTCLSLog("SidePanel - book selected");
        self.openNotebook(item, controllerToDismiss: viewController, addToRecent: true)
    }
    
    func performToolbarAction(_ viewController : UIViewController, actionType: FTCategoryToolbarActionType, actionView : UIView) {
        let storyboard = UIStoryboard(name: "FTNewSettings", bundle: nil);
        if let settingsController = storyboard.instantiateViewController(withIdentifier: "FTGlobalSettingsController") as? FTGlobalSettingsController {
            let navController = UINavigationController(rootViewController: settingsController)
            navController.modalPresentationStyle = .formSheet
            viewController.present(navController, animated: true, completion: nil);
        }
    }
}

extension FTPDFRenderViewController {
    func openNotebook(_ shelfItem: FTShelfItemProtocol, controllerToDismiss:UIViewController, addToRecent: Bool) {
        if let documentItem = shelfItem as? FTDocumentItemProtocol {
            if !documentItem.isDownloaded {
                do {
                    _ = try FileManager().startDownloadingUbiquitousItem(at: documentItem.URL);
                }
                catch let error as NSError {
                    FTLogError("Notebook download failed", attributes: error.userInfo);
                }
                return
            }
        }

//        controllerToDismiss.dismiss(animated: false, completion: nil);
        self.noteBookSplitViewController()?.preferredDisplayMode = .secondaryOnly
        if self.pdfDocument.URL != shelfItem.URL {
            self.openRecentItem(shelfItemManagedObject: FTDocumentItemWrapperObject.init(documentItem: shelfItem), addToRecent: addToRecent)
        }
    }
}
