//
//  FTShelfItemsViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

protocol FTShelfItemsViewModelDelegate: AnyObject {
    func shelfItemsViewController(_ viewController: FTShelfItemsViewControllerNew, didFinishPickingShelfItemsForBottomToolBar collectionShelfItem: FTShelfItemCollection!, toGroup: FTGroupItemProtocol?, selectedShelfItems: [FTShelfItemProtocol])
    func createNewCategporyForMoving(selectedShelfItems: [FTShelfItemProtocol], viewController: FTShelfItemsViewControllerNew)
    func createNewGroupForMoving(selectedShelfItems: [FTShelfItemProtocol],atShelfItemCollection shelfItemCollection: FTShelfItemCollection,inGroup: FTGroupItemProtocol?,  viewController: FTShelfItemsViewControllerNew)
}
protocol FTShelfItemsMovePageDelegate: AnyObject {
    func shelfItemsViewController(_ viewController: FTShelfItemsViewControllerNew, didFinishPickingShelfItem shelfItem: FTShelfItemProtocol, isNewlyCreated: Bool);
    func shelfItemsView(_ viewController: FTShelfItemsViewControllerNew,
                    didFinishWithNewNotebookTitle title: String,
                    collection: FTShelfItemCollection,
                    group: FTGroupItemProtocol?);
    func createNewNoteBookForMoving(atShelfItemCollection shelfItemCollection: FTShelfItemCollection,inGroup: FTGroupItemProtocol?,  viewController: FTShelfItemsViewControllerNew)

}

class FTShelfItemsViewModel: ObservableObject {

    @Published var shelfItems: [FTShelfItems] = []

    var groupItem: FTGroupItemProtocol?
    var collection: FTShelfItemCollection?
    var selectedShelfItemsForMove: [FTShelfItemProtocol]
    var presentedViewController: FTShelfItemsViewControllerNew?
    @Published var selectedShelfItemToMove: FTShelfItemProtocol?
    weak var delegate: FTShelfItemsViewModelDelegate?
    weak var movePageDelegate: FTShelfItemsMovePageDelegate?


    private var purpose: FTShelfItemsPurpose = .shelf

    init(selectedShelfItems: [FTShelfItemProtocol]){
        self.selectedShelfItemsForMove = selectedShelfItems
    }
    convenience init(selectedShelfItems: [FTShelfItemProtocol] = [],
         collection: FTShelfItemCollection? = nil,
         groupItem: FTGroupItemProtocol? = nil,
                     purpose: FTShelfItemsPurpose = .shelf){
        self.init(selectedShelfItems: selectedShelfItems)
        self.collection = collection
        self.groupItem = groupItem
        self.purpose = purpose
    }
    //MARK: Computed properties
    var navigationItemTitle: String {
        let title: String
        if groupItem != nil {
            title =  groupItem?.displayTitle ?? ""
        } else if collection != nil {
            title =  collection?.displayTitle ?? ""
        } else {
            title = NSLocalizedString("move", comment: "Move")
        }
        return title
    }

    var showMoveButton: Bool {
        return collection != nil
    }

    var disableMoveButton: Bool {
        if purpose == .shelf {
            if groupItem?.shelfCollection.uuid == collection?.uuid &&  groupItem?.uuid == selectedShelfItemsForMove.first?.parent?.uuid {
                return true
            }
            else if selectedShelfItemsForMove.first?.shelfCollection.uuid == collection?.uuid && nil == groupItem?.uuid && nil == self.selectedShelfItemsForMove.first?.parent?.uuid {
                return true
            } else {
                return false
            }
        }else {
            if selectedShelfItemToMove != nil{
                return false
            }
            return true
        }
    }
    func isGroupItemEligibleForMoving(_ shelfItem: FTShelfItems) -> Bool{
        if shelfItem.group?.uuid == self.groupItem?.uuid {
            return false
        } else {
            for item in self.selectedShelfItemsForMove {
                if let shelfItem = item as? FTGroupItemProtocol, shelfItem.uuid == groupItem?.uuid {
                    return false
                }else if let groupItem = item as? FTGroupItemProtocol,groupItem.uuid == shelfItem.group?.uuid {
                    return false
                }
            }
        }
        return true
    }
    func fetchUserCreatedCategories() async {
        if collection == nil {
            let collections = await FTNoteshelfDocumentProvider.shared.fetchAllCollections(includingUnCategorized: true)
            let items: [FTShelfItems] = collections.map { collection -> FTShelfItems in
                let item = FTShelfItems(collection: collection)
                return item
            }
            runInMainThread {
                self.shelfItems = items
            }
        } else {
            let fetchShelfItemsOptions = FTFetchShelfItemOptions()
            fetchShelfItemsOptions.includesGroupItems = true
            if let collection = collection {
                let shelfItemsData = await FTNoteshelfDocumentProvider.shared.fetchShelfItems(forCollections: [collection], option: fetchShelfItemsOptions, parent: groupItem, fetchedShelfItems: nil)
                runInMainThread {
                    self.shelfItems = self.createShelfItemsFromData(shelfItemsData)
                }
            }
        }
    }
    func performMoveOperation(){
        if purpose == .shelf {
            if let destinationCollection = collection, let presentedViewController = presentedViewController {
                self.delegate?.shelfItemsViewController(presentedViewController, didFinishPickingShelfItemsForBottomToolBar: destinationCollection, toGroup: groupItem, selectedShelfItems: selectedShelfItemsForMove)
            }
        }else {
            if let selectedShelfItem = self.selectedShelfItemToMove, let presentedViewController = presentedViewController {
                self.movePageDelegate?.shelfItemsViewController(presentedViewController, didFinishPickingShelfItem: selectedShelfItem, isNewlyCreated: false)
            }

        }
    }
    func showNewCategoryCreationAlert(){
        if let presentedViewController = presentedViewController {
            self.delegate?.createNewCategporyForMoving(selectedShelfItems: selectedShelfItemsForMove, viewController: presentedViewController)
        }
    }
    func showNewGroupCreationAlert(){
        if let presentedViewController = presentedViewController, let parentCollection = collection {
            self.delegate?.createNewGroupForMoving(selectedShelfItems: selectedShelfItemsForMove, atShelfItemCollection: parentCollection, inGroup: groupItem, viewController: presentedViewController)
        }
    }
    
    func showNewNoteBookCreationAlert() {
        if let presentedViewController = presentedViewController, let parentCollection = collection {
            if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
                FTIAPurchaseHelper.shared.showIAPAlert(on: presentedViewController);
                return;
            }
            self.movePageDelegate?.createNewNoteBookForMoving(atShelfItemCollection: parentCollection, inGroup: groupItem, viewController: presentedViewController)
        }
    }
}
private extension FTShelfItemsViewModel {
    func createShelfItemsFromData(_ shelfItemsData: [FTShelfItemProtocol]) -> [FTShelfItems]{
        let items: [FTShelfItems] = shelfItemsData.map { item -> FTShelfItems in
            if let groupItem = item as? FTGroupItemProtocol {
                return FTShelfGroupItem(group: groupItem)
            } else {
                return FTShelfNotebookItem(notebook: item)
            }
        }
        return items
    }
    var containsGroupItemForMove : Bool {
        let selectedGroupItems = self.selectedShelfItemsForMove.filter({ (shelfItem) -> Bool in
            return shelfItem is FTGroupItemProtocol
        })
        return !selectedGroupItems.isEmpty
    }
}
