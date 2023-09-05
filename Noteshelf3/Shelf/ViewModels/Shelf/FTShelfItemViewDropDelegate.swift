//
//  DragAnfDropService.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 25/05/22.
//
import Combine
import Foundation
import FTCommon
import SwiftUI
import UniformTypeIdentifiers

class FTShelfScrollViewDropDelegate: DropDelegate {
    weak var viewModel: FTShelfViewModel!

    init(viewModel: FTShelfViewModel) {
        self.viewModel = viewModel
    }
    var dropProposal: DropProposal = DropProposal(operation: .move)
    func validateDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: FTDragAndDropHelper.supportedTypesForDrop()) && (viewModel.supportsDrop) {
            viewModel.showDropOverlayView = true
        }
        return true
    }
    func performDrop(info: DropInfo) -> Bool {
        print("inside performDrop of ScrollViewDropViewDelegate")
        let supportedUTTypes = FTDragAndDropHelper.supportedTypesForDrop()
        if viewModel?.showDropOverlayView ?? false {
            viewModel.showDropOverlayView = false
        }
        if !(viewModel?.supportsDrop ?? false) {
            viewModel.fadeDraggedShelfItem = nil
            return false
        }
        if info.hasItemsConforming(to: supportedUTTypes){
            viewModel?.processCreationOfNotebooksUsingItemProviders(info.itemProviders(for: supportedUTTypes))
        } else {
            if let collection = viewModel?.collection , collection.isAllNotesShelfItemCollection {
                viewModel.endDragAndDropOperation()
                return false
            }

            if let draggedItem = FTShelfDraggedItemProvider.shared.draggedNotebook {
                performDragOperationForDraggedItem(draggedItem)
            }else {
                let items = info.itemProviders(for: [.data])
                for item in items {
                    item.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { [weak self ]data, error in
                        if let data = data {
                            if let shelfItemData = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                               let shelfItemPath = shelfItemData[shelfItemURLKey] as? String,
                               let collectionName = shelfItemData[collectionNameKey] as? String,
                               let shelfItem =  self?.viewModel.getShelfItemWithPath(shelfItemPath, collectionName: collectionName){
                                self?.performDragOperationForDraggedItem(shelfItem)
                            }
                        }
                    }
                }
            }

        }
        viewModel?.currentDraggedItem = nil
        viewModel?.highlightItem = nil
        FTShelfDraggedItemProvider.shared.draggedNotebook = nil
        return true
    }

    func performDragOperationForDraggedItem(_ draggedItem: FTShelfItemProtocol){
        if draggedItem.shelfCollection.URL == self.viewModel?.collection.URL { //If from & to shelfs are same
            if let toShelfGroup = self.viewModel.groupItem,!(viewModel.isGroupItemToBeForbiddenInItsChildTree(draggedItem, toGroup: toShelfGroup)), draggedItem.parent?.URL != toShelfGroup.URL {
                self.viewModel.moveShelfItemToCollection(item: draggedItem)
            }
            else if self.viewModel.groupItem == nil && draggedItem.parent != nil {
                self.viewModel.moveShelfItemToCollection(item: draggedItem)
            }
            resetDraggedItem()
        }
        else {//If from & to shelfs are different
            self.viewModel.moveShelfItemToCollection(item: draggedItem)
        }
    }
    func resetDraggedItem(){
        runInMainThread {
            self.viewModel.fadeDraggedShelfItem = nil
            FTShelfDraggedItemProvider.shared.updateDragOperationItems()
        }
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        let supportedUTTypes = FTDragAndDropHelper.supportedTypesForDrop()

        if info.hasItemsConforming(to: supportedUTTypes) && viewModel.supportsDrop {
            if !viewModel.showDropOverlayView {
                viewModel.showDropOverlayView = true
            }
            return DropProposal(operation: .copy)
        }
        else if let _ = FTShelfDraggedItemProvider.shared.draggedNotebook {
            if viewModel.collection.isAllNotesShelfItemCollection {
                FTShelfDraggedItemProvider.shared.draggedNotebook = nil
                viewModel.endDragAndDropOperation()
                return DropProposal(operation: .forbidden)
            } else {
                viewModel.fadeDraggedShelfItem = viewModel.currentDraggedItem
                return DropProposal(operation: .move)
            }
        }
        return DropProposal(operation: .forbidden)
    }
    
    func dropEntered(info: DropInfo) {
        viewModel.highlightItem = nil
        print("Drop entered in shelf scroll")
    }
    
    func dropExited(info: DropInfo) {
        if viewModel.showDropOverlayView {
            viewModel.showDropOverlayView = false
        }
        viewModel.fadeDraggedShelfItem = nil
        print("Drop exited in shelf scroll")
    }
}

class FTShelfItemViewDropDelegate: NSObject, DropDelegate {
    weak var item: FTShelfItemViewModel!
    weak var viewModel: FTShelfViewModel!
    weak var clearTimer: Timer?
    var shelfItemCoverSize: CGSize = .zero
    var dropMoveRect: CGRect = .zero
    var leftMoveRect : CGRect {
        CGRect(x: shelfItemCoverSize.width/2, y: 0, width: 40, height: shelfItemCoverSize.height)
    }
    var rightMoveRect : CGRect {
        CGRect(x: shelfItemCoverSize.width/2, y: 0, width: 40, height: shelfItemCoverSize.height)
    }

    init(item: FTShelfItemViewModel, viewModel: FTShelfViewModel, shelfItemSize:CGSize,dropRect:CGRect) {
        self.item = item
        self.viewModel = viewModel
        self.shelfItemCoverSize = shelfItemSize
        self.dropMoveRect = dropRect
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: FTDragAndDropHelper.supportedTypesForDrop()) && (viewModel.supportsDragAndDrop || viewModel.supportsDrop) {
            viewModel.showDropOverlayView = true
        }
        return true
    }
    
    func performDrop(info: DropInfo) -> Bool {

        if viewModel.showDropOverlayView {
            viewModel.showDropOverlayView = false
        }

        if let draggedItem = viewModel.currentDraggedItem, draggedItem.id == item.id || !viewModel.supportsDragAndDrop || !viewModel.supportsDrop {
            viewModel.fadeDraggedShelfItem = nil // Also show a toast.
            return false
        }

        if let draggedItem = FTShelfDraggedItemProvider.shared.draggedNotebook {
            if let destinationGroupItem = viewModel.highlightItem?.model as? FTGroupItemProtocol{
                 if !(viewModel.isGroupItemToBeForbiddenInItsChildTree(draggedItem, toGroup: destinationGroupItem))
                {
                    performDragOperationOnDraggedItem(draggedItem)
                 } else if let sourceGroup = (draggedItem as? FTGroupItemProtocol), sourceGroup.childrens.first(where: {$0.uuid == destinationGroupItem.uuid}) == nil { // checking if dragged item is parent to drop item
                    performDragOperationOnDraggedItem(draggedItem)
                 }else {
                     self.viewModel.currentDraggedItem = nil
                     self.viewModel.highlightItem = nil
                     resetDraggedItem()
                 }
            } else if let destinationItem = self.viewModel.highlightItem?.model, !viewModel.isDragToBeForbiddenFor(draggedItem, toShelfItem: destinationItem) {
                performDragOperationOnDraggedItem(draggedItem)
            }else {
                self.viewModel.currentDraggedItem = nil
                self.viewModel.highlightItem = nil
                resetDraggedItem()
            }
        }else {
            let items = info.itemProviders(for: [.data])
            for item in items {
                item.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) {[weak self] data, error in
                    if let data = data {
                        if let shelfItemData = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                           let shelfItemPath = shelfItemData[shelfItemURLKey] as? String,
                           let collectionName = shelfItemData[collectionNameKey] as? String,
                           let shelfItem =  self?.viewModel.getShelfItemWithPath(shelfItemPath, collectionName: collectionName){
                            performDragOperationOnDraggedItem(shelfItem)
                        }
                    }
                }
            }
        }

        func performDragOperationOnDraggedItem(_ item: FTShelfItemProtocol){
            runInMainThread { [weak self] in
                guard let strongself = self else {
                    return;
                }
                
                if let draggedItem = FTShelfDraggedItemProvider.shared.draggedNotebook, let destinationItem = strongself.viewModel.highlightItem?.model{
                    strongself.viewModel.moveShelfItem(draggedItem, intoShelfItem: destinationItem)
                }else if let destinationItem = strongself.viewModel.highlightItem,
                         let sourceItem = strongself.viewModel.currentDraggedItem {
                    strongself.viewModel.moveShelfItem(sourceItem.model, intoShelfItem: destinationItem.model)
                }
                strongself.viewModel.currentDraggedItem = nil
                strongself.viewModel.highlightItem = nil
                strongself.resetDraggedItem()
                FTShelfDraggedItemProvider.shared.draggedNotebook = nil
            }
        }
        return true
    }
    
    func resetDraggedItem(){
        runInMainThread { [weak self] in
            self?.viewModel.fadeDraggedShelfItem = nil
            FTShelfDraggedItemProvider.shared.updateDragOperationItems()
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        let supportedUTTypes = FTDragAndDropHelper.supportedTypesForDrop()
        viewModel.highlightItem = nil
        var currentDraggedShelfItem: FTShelfItemProtocol?
        if viewModel.currentDraggedItem != nil {
            currentDraggedShelfItem = viewModel.currentDraggedItem?.model
        }else if let notebook = FTShelfDraggedItemProvider.shared.draggedNotebook {
            currentDraggedShelfItem = notebook
        }

        // Incase if current collection is all notes or favorites and also same item, avoiding highlighting of dropped item
        if dropMoveRect.contains(info.location) ,
           let draggedItem = currentDraggedShelfItem {
            if draggedItem.uuid != item.id , viewModel.supportsDragAndDrop { // avoiding highlight of drop item when dragged and drop item are same. Also as making  forbidden results in no control over dragged item, avoiding forbidden state
                viewModel.highlightItem = item
            }
           // return DropProposal(operation: .move)
        } else if info.hasItemsConforming(to: supportedUTTypes) && (viewModel.supportsDragAndDrop || viewModel.supportsDrop){
            return DropProposal(operation: .copy)
        }
        //return DropProposal(operation: .move)
        // For supporting reorder

        if FTUserDefaults.sortOrder() == .manual { //, ((rightMoveRect.minX < info.location.x && info.location.x < rightMoveRect.maxX) ||
         //(leftMoveRect.maxX > info.location.x && info.location.x > 0)) { {
             performDropOperation(info: info)
         }
        return DropProposal(operation: .move)
    }
    
    func dropEntered(info: DropInfo) {
        if FTUserDefaults.sortOrder() == .manual {
            //performDropOperation(info: info)
        }
    }
    
    func dropExited(info: DropInfo) {
    }
    
    //MARK: For reorder
    private func performDropOperation(info: DropInfo) {
        guard let dragItemId = viewModel.currentDraggedItem?.id else {
            return
        }
        guard let fromIndex = viewModel.shelfItems.firstIndex(where: { $0.id == dragItemId }),
              let toIndex = viewModel.shelfItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        if  info.location.x > rightMoveRect.minX && fromIndex < toIndex {
            withAnimation { [weak self] in
                self?.viewModel.moveShelfItem(fromIndex: fromIndex, toIndex: toIndex)
            }
        } else if info.location.x < leftMoveRect.maxX && fromIndex > toIndex {
            withAnimation { [weak self] in
                self?.viewModel.moveShelfItem(fromIndex: fromIndex, toIndex: toIndex)
            }
        } else {
        }
    }
}
extension FTShelfViewModel {
    //To check for forbidden using group item(if it is one of the drag items)
    func isGroupItemToBeForbiddenInItsChildTree(_ shelfItem: FTShelfItemProtocol, toGroup: FTGroupItemProtocol) -> Bool {
        let groupItems: [FTGroupItemProtocol] = self.getGroupItemsFromDraggingItems(shelfItem)
        for groupItem in groupItems {
            if groupItem.URL == toGroup.URL {
                return true
            } else if let toGroupParent = toGroup.parent {
                return self.checkIfDragItemIsParentForAnytoGroupChild(toGroupParent: toGroupParent, draggingGroupItem: groupItem)
            }
        }
        return false
    }

    func isDragToBeForbiddenFor(_ shelfDragItem: FTShelfItemProtocol, toShelfItem: FTShelfItemProtocol) -> Bool {
        if shelfDragItem.URL == toShelfItem.URL {
            return true
        }
        if toShelfItem is FTGroupItemProtocol, let groupItem = toShelfItem as? FTGroupItemProtocol {
            if groupItem.childrens.contains(where: { (child) -> Bool in
                child.URL == shelfDragItem.URL
            }) {
                return true
            }
        }
        return false
    }

    func checkIfDragItemIsParentForAnytoGroupChild(toGroupParent: FTShelfItemProtocol, draggingGroupItem: FTGroupItemProtocol) -> Bool {
        if toGroupParent.URL == draggingGroupItem.parent?.URL {
            return false
        } else {
            if toGroupParent.URL == draggingGroupItem.URL {
                return true
            } else if let toGroupParent = toGroupParent.parent {
                return self.checkIfDragItemIsParentForAnytoGroupChild(toGroupParent: toGroupParent, draggingGroupItem: draggingGroupItem)
            }
        }
        return false
    }

    func getGroupItemsFromDraggingItems(_ shelfDragItem: FTShelfItemProtocol) -> [FTGroupItemProtocol] {
        var groupItems = [FTGroupItemProtocol]()
        if shelfDragItem is FTGroupItemProtocol, let groupItem = shelfDragItem as? FTGroupItemProtocol {
            groupItems.append(groupItem)
        }
        return groupItems
    }
}
class FTDragAndDropHelper {
    static func supportedTypesForDrop() -> [UTType]{
        var supportedUTITypesVar = [String]()
#if targetEnvironment(macCatalyst)
        supportedUTITypesVar = ["com.adobe.pdf"]
#else
        supportedUTITypesVar = ["com.microsoft.excel.xls",
                                "com.microsoft.excel.xls",
                                "org.openxmlformats.spreadsheetml.sheet",
                                "com.microsoft.word.doc",
                                "org.openxmlformats.wordprocessingml.document",
                                "com.microsoft.powerpoint.ppt",
                                "org.openxmlformats.presentationml.presentation",
                                "com.adobe.pdf"]
#endif
        var supportedUTTypes : [UTType] = []
        if let notebookType = UTType(UTI_TYPE_NOTESHELF_BOOK) {
            supportedUTTypes.append(notebookType)
        }
        if let notebookType = UTType(UTI_TYPE_NOTESHELF_NOTES) {
            supportedUTTypes.append(notebookType)
        }
        for type in supportedUTITypesVar {
            if let uTTypeNew = UTType(type) {
                supportedUTTypes.append(uTTypeNew)
            }
        }
        supportedUTTypes.append(contentsOf: [.image])
        return supportedUTTypes
    }
}
class FTShelfDraggedItemProvider {
    static let shared = FTShelfDraggedItemProvider()
    var draggedNotebook: FTShelfItemProtocol? {
        didSet {
            if draggedNotebook == nil {
                updateDragOperationItems()
            }
        }
    }
    func updateDragOperationItems(){
        NotificationCenter.default.post(Notification(name: Notification.Name("ShelfItemDropOperationFinished")))
    }
}
