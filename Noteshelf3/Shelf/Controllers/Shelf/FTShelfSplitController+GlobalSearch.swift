//
//  FTShelfSplitController+GlobalSearch.swift
//  Noteshelf3
//
//  Created by Narayana on 28/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfSplitViewController {
    func navigateToGlobalSearch() {
        guard let globalSearchController = UIStoryboard.init(name: "FTGlobalSearch", bundle: nil).instantiateViewController(identifier: "FTGlobalSearchController") as? FTGlobalSearchController else {
            fatalError("Programmer error, Could not find Global searc controller")
        }
        self.sideMenuController?.addBlurView()
        globalSearchController.delegate = self
        globalSearchController.shelfItemCollection = self.shelfItemCollection
        globalSearchController.navTitle = (currentShelfViewModel?.isInHomeMode ?? false) ? NSLocalizedString("sidebar.topSection.home", comment: "Home") : shelfItemCollection?.displayTitle
        self.globalSearchController = globalSearchController
        self.detailNavigationController?.pushViewController(globalSearchController, animated: false)
    }

    func exitFromGlobalSearch() {
        self.sideMenuController?.removeBlurView()
        if let searchVc = self.globalSearchController, let navVc = searchVc.navigationController {
            navVc.popViewController(animated: false)
            self.globalSearchController = nil
        }
#if targetEnvironment(macCatalyst)
        (self.view.toolbar as? FTShelfToolbar)?.resignSearchToolbar()
#endif
    }

    func checkIfGlobalSearchControllerExists() -> Bool {
        var status = false
        if let globalSearchVc = self.globalSearchController, let children = self.detailNavigationController?.children, children.contains(globalSearchVc) {
            status = true
        }
        return status
    }
}

extension FTShelfSplitViewController: FTGlobalSearchDelegate {
    func selectSidebarWithCollection(_ collection: FTShelfItemCollection) {
        self.shelfItemCollection = currentShelfViewModel?.collection
        self.sideMenuController?.selectSidebarItemWithCollection(collection)
    }
    func willExitFromSearch(_ controller: FTGlobalSearchController) {
        self.exitFromGlobalSearch()
    }

    func didExitFromSearch(_ controller: FTGlobalSearchController) {
//        self.loadShelfItems(onCompletion: nil);
//        // Any update like pinning and unpinning status etc to get updated in UI after global search
//        self.reloadSnapShot(with: false)
    }

    func openNotebook(info: FTDocumentOpenInfo) {
        if let rootVc = self.parent as? FTRootViewController {
            rootVc.switchToPDFViewer(info, animate: true, onCompletion: nil)
        }
    }

    func didSelectCategory(category: FTShelfItemCollection) {
        self.saveLastSelectedCollection(category)
        self.shelfItemCollection = category
        self.sideMenuController?.selectSidebarItemWithCollection(category)
        let categoryVc = getSecondaryViewControllerWith(collection: category, groupItem: nil)
        self.globalSearchController?.navigationController?.pushViewController(categoryVc, animated: true)
    }

    func didSelectGroup(groupItem: FTGroupItemProtocol) {
        self.showGroup(with: groupItem, animate: true)
    }

    func performContextMenuOperation(for shelfItem: FTDiskItemProtocol,
                                     pageIndex: Int?,
                                     type: FTShelfItemContexualOption) {
        if type == .openInNewWindow {
            self.openItemInNewWindow(shelfItem,pageIndex: pageIndex)
        }
        else if type == .share, let item = shelfItem as? FTShelfItemProtocol {
            self.shareNotebooksOrGroups([item], onCompletion: {
            })
        } else if type == .showEnclosingFolder, let item = shelfItem as? FTShelfItemProtocol {
            self.showInEnclosingFolder(forItem: item)
        }
    }

    func performContextMenuPageShare(for page: FTPageProtocol, shelfItem: FTShelfItemProtocol) {
        let coordinator = FTShareCoordinator(shelfItems: [shelfItem], pages: [page], presentingController: self)
        FTShareFormatHostingController.presentAsFormsheet(over: self, using: coordinator, option: .currentPage, pages: [page])
    }

    // This is for context menu pin operation for note book during global search
    func performContextualMenuPin(for shelfItem: FTShelfItemProtocol, isToPin: Bool) {
        self.favoriteShelfItem(shelfItem, toPin: isToPin)
    }
}

extension FTShelfSplitViewController {
    func shareNotebooksOrGroups(_ items: [FTShelfItemProtocol], onCompletion: @escaping (() -> Void)) {
        if !items.isEmpty {
            self.shareItems = items
            let coordinator = FTShareCoordinator(shelfItems: items, presentingController: self)
            FTShareFormatHostingController.presentAsFormsheet(over: self, using: coordinator, option: .notebook, shelfItems: items)
        }
    }
}
