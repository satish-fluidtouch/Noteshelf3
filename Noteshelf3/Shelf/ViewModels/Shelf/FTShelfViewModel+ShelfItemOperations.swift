//
//  FTShelfViewModel+ShelfItemOperations.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
//MARK: shelf Item operations
extension FTShelfViewModel {
    func showEnclosingFolderFor(_ item: FTShelfItemProtocol) {
        self.delegate?.showInEnclosingFolder(forItem: item)
    }
    func openShelfItemInNewWindow(_ item: FTShelfItemProtocol){
        self.openItemInNewWindow(item, pageIndex: nil)
    }
    
    func showNewNotePopoverOnRect(_ rect: CGRect){
        self.delegate?.showNewNotePopoverOnRect(rect)
    }
    func moveShelfItems(_ shelfItems : [FTShelfItemProtocol]) {
        delegate?.showMoveItemsPopOverWith(selectedShelfItems: shelfItems)
    }
    func getShelfItemWithPath(_ path: String, collectionName: String) -> FTShelfItemProtocol?{
        var sourceShelfItem: FTShelfItemProtocol?;
        let shelfItemURL = URL(fileURLWithPath: path)
        let relativePath = shelfItemURL.relativePathWRTCollection()
        FTNoteshelfDocumentProvider.shared.shelfCollection(title: collectionName) { [weak self] shelfCollection in
            if let shelfCollection = shelfCollection {
                if(self?.isGroup(shelfItemURL) ?? false) {
                    sourceShelfItem = shelfCollection.groupItemForURL(shelfItemURL)
                }else {
                    var groupItem : FTGroupItemProtocol?;
                    if let groupPath = relativePath.relativeGroupPathFromCollection() {
                        let url = shelfCollection.URL.appendingPathComponent(groupPath);
                        groupItem = shelfCollection.groupItemForURL(url);
                    }
                    sourceShelfItem = shelfCollection.documentItemWithName(title: relativePath.documentName(), inGroup: groupItem)
                }
            }
        }
        return sourceShelfItem
    }
    func moveShelfItemToCollection(item: FTShelfItemProtocol){
        self.removeObserversForShelfItems()
        self.delegate?.moveShelfItem([item], ofCollection: collection, toGroup: groupItem, onCompletion: { [weak self] in
            self?.addObserversForShelfItems()
            FTShelfDraggedItemProvider.shared.draggedNotebook = nil
            self?.resetShelfModeTo(.normal)
        })
    }
    func moveShelfItem(_ dragItem: FTShelfItemProtocol, intoShelfItem destinationShelfItem: FTShelfItemProtocol){
        if let groupItem = destinationShelfItem as? FTGroupItemProtocol{
            self.removeObserversForShelfItems()
            self.delegate?.moveShelfItem([dragItem], ofCollection: collection, toGroup: groupItem, onCompletion: { [weak self] in
                self?.addObserversForShelfItems()
                FTShelfDraggedItemProvider.shared.draggedNotebook = nil
                self?.resetShelfModeTo(.normal)
            })
        } else {
            let destinationShelfItem = destinationShelfItem
            let sourceShelfItem = dragItem
            runInMainThread {
                self.currentDraggedItem = nil
                self.highlightItem = nil
            }
            let groupTitle: String = "Group"
            self.removeObserversForShelfItems()
            self.delegate?.groupShelfItems([sourceShelfItem,destinationShelfItem], ofColection: collection, parentGroup: groupItem, withGroupTitle: groupTitle, showAlertForGroupName: false, onCompletion: { [weak self] in
                self?.addObserversForShelfItems()
                self?.resetShelfModeTo(.normal)
            })
        }
    }
    func openRecentCreatedShelfItem(_ item: FTShelfItemViewModel, animate: Bool = true, isQuickCreatedBook: Bool = false){
        self.processNotebookOpeningFor(item: item)
    }
    func openShelfItem(_ item: FTShelfItemViewModel, animate: Bool = true, isQuickCreatedBook: Bool = false){
        if let documentItem = item.model as? FTDocumentItemProtocol, documentItem.isDownloaded{
            self.setcurrentActiveShelfItem( FTCurrentShelfItem(item.model, isQuickCreated: isQuickCreatedBook, isOpened: true ,pin: nil))
        }
        self.processNotebookOpeningFor(item: item)
    }
    func processNotebookOpeningFor(item: FTShelfItemViewModel){
        let shelfItemProtocol = item.model
        if let documentItem = shelfItemProtocol as? FTDocumentItemProtocol, documentItem.isDownloaded, !shelfItemProtocol.shelfCollection.isTrash {
            item.showLoader()
        }
        let notebookName = shelfItemProtocol.displayTitle
        FTCLSLog("Book: \(notebookName): Tapped")
        if shelfItemProtocol.type == RKShelfItemType.pdfDocument {
            delegate?.openNotebook(shelfItemProtocol, shelfItemDetails: getCurrentActiveShelfItem(), animate: true, isQuickCreate: getCurrentActiveShelfItem()?.isQuickCreated ?? false, pageIndex: nil)
        }
    }
    func removeRecentItemsFromRecents(_ items:[FTShelfItemProtocol]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)){
                FTNoteshelfDocumentProvider.shared.removeShelfItemFromList(items, mode: .recent)
        }
    }
}
// MARK: Group creation logic
private extension FTShelfViewModel {
    func isGroup(_ fileURL: Foundation.URL) -> Bool {
        let fileItemURL = fileURL.urlByDeleteingPrivate();
        if(fileItemURL.pathExtension == groupExtension) {
            return true;
        }
        return false;
    }
    func loadShelfItemsFromCollection(animate:Bool,
                                                  forcibly : Bool,
                                              onCompletion: @escaping (_ shelfItems:[FTShelfItemProtocol]?) -> Void) {
        if(self.collection.isTrash) {
//            self.shelfToolbarController?.toolbarStyle = .trash;
        }

        let uuid = collection.uuid;

            let currentOrder = FTUserDefaults.sortOrder()
//        if let userActivity = self.view.window?.windowScene?.userActivity{
//            currentOrder = userActivity.sortOrder
//        }
        collection.shelfItems(currentOrder, parent: groupItem, searchKey: nil) { [weak self] (shelfItems) in
            if(uuid == self?.collection.uuid) {
                onCompletion(shelfItems)
            }
            else {
                onCompletion(nil);
            }
        }
        onCompletion(nil)
    }
    func switchToNormalMode() {
        self.mode = .normal
    }
}
