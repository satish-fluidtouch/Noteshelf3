//
//  FTShelfSplitViewController_Mac_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 17/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTTemplatesStore

#if targetEnvironment(macCatalyst)
extension FTShelfSplitViewController: FTToolbarActionDelegate {
    func toolbar(_ toolbar: NSToolbar, canPerformAction item: NSToolbarItem) -> Bool {
        if let secondaryVC = self.getSecondaryRootViewController() as? FTToolbarActionDelegate {
            return secondaryVC.toolbar(toolbar, canPerformAction: item);
        }
        return false;
    }
    
    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem) {
        if item.itemIdentifier == FTShelfToogleSidebarToolbarItem.identifier {
            if(self.displayMode == .secondaryOnly) {
                self.show(.primary)
            }
            else {
                self.hide(.primary)
            }
        } else if item.itemIdentifier == FTShelfBackToolbarItem.identifier {
            self.detailNavigationController?.popViewController(animated: true)
        } else if let actionDelegate = self.getSecondaryRootViewController() as? FTToolbarActionDelegate {
            actionDelegate.toolbar(toolbar, toolbarItem: item);
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?) {
        if let actionDelegate = self.getSecondaryRootViewController() as? FTToolbarActionDelegate {
            actionDelegate.toolbar(toolbar, didTapOnMenuitem: menuItem);
        }
    }

    private func getSecondaryRootViewController() -> UIViewController? {
        guard let detailController = self.viewController(for: .secondary) else {
            return nil
        }
        if let navController = detailController as? UINavigationController {
            if let _ = navController.children.first(where: { $0 is FTShelfViewControllerNew }) {
                let filteredChildren = navController.children.filter { !$0.isKind(of: FTGlobalSearchController.self) }
                return filteredChildren.last // for second level and groups
            }
            return navController.rootViewController // for templates and first level shelf items
        } else {
            return detailController
        }
    }
}

extension FTShelfSplitViewController: FTSearchToolbarActionDelegate {
    func toolbarDidBeginSearch(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        if let actionDelegate = self.getSecondaryRootViewController() as? FTSearchToolbarActionDelegate {
           actionDelegate.toolbarDidBeginSearch(toolbarId, textField: textField);
       }
    }
    
    func didChangeText(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        if let actionDelegate = self.getSecondaryRootViewController() as? FTSearchToolbarActionDelegate {
           actionDelegate.didChangeText(toolbarId, textField: textField);
       }
    }
    
    func didTapOnSuggestion(_ toolbarId: NSToolbar.Identifier, suggestionItem: FTSuggestedItem, textField: UISearchTextField) {
        if let actionDelegate = self.getSecondaryRootViewController() as? FTSearchToolbarActionDelegate {
           actionDelegate.didTapOnSuggestion(toolbarId, suggestionItem: suggestionItem, textField: textField);
       }
    }
    
    func didTapSearchClear(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        if let actionDelegate = self.getSecondaryRootViewController() as? FTSearchToolbarActionDelegate {
           actionDelegate.didTapSearchClear(toolbarId, textField: textField);
       }
    }
    
    func didTextEndEditing(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField) {
        if let actionDelegate = self.getSecondaryRootViewController() as? FTSearchToolbarActionDelegate {
            actionDelegate.didTextEndEditing(toolbarId, textField: textField);
       }
    }
}

private extension UINavigationController {
    var rootViewController: UIViewController? {
        if let controller = viewControllers.first {
            if let navController = controller as? UINavigationController {
                return navController.rootViewController;
            }
            return controller;
        }
        return nil;
    }
}

extension FTStoreContainerViewController: FTToolbarActionDelegate {
    func toolbar(_ toolbar: NSToolbar, canPerformAction item: NSToolbarItem) -> Bool {
        return false;
    }
    
    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem) {
        if item.itemIdentifier == FTShelfBackToolbarItem.identifier {
            self.navigationController?.popViewController(animated: true);
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?) {
        
    }
}

extension FTShelfSplitViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is FTGlobalSearchController {
            self.sideMenuController?.addBlurView()
        } else {
            self.sideMenuController?.removeBlurView()
        }
        viewController.navigationItem.hidesBackButton = true
        if let toolbar = self.view.toolbar as? FTShelfToolbar {
            if let searchVc = viewController as? FTGlobalSearchController {
                toolbar.updateSearchText(searchVc.searchInputInfo.textKey)
            } else {
                toolbar.updateSearchText("")
                toolbar.resignSearchToolbar()
                // To disable other tool items during search mode
                if let addToolItem = toolbar.getToolbarItem(with: FTShelfAddToolbarItem.identifier) as? FTShelfAddToolbarItem {
                    addToolItem.validate()
                }
                if let moreItem = toolbar.getToolbarItem(with: FTShelfMoreToolbarItem.identifier) as? FTShelfMoreToolbarItem {
                    moreItem.validate()
                }
            }

            if navigationController.rootViewController is FTStoreContainerViewController {
                toolbar.switchMode(.templatePreview)
            } else if self.checkIfShelfContentViewControllerExists(from: navigationController) {
                toolbar.switchMode(.content)
            } else if let shelfController = viewController as? FTShelfViewControllerNew, let collection = shelfController.shelfItemCollection {
                if collection.isTrash {
                    toolbar.switchMode(.trash)
                } else {
                    toolbar.switchMode(.shelf)
                }
            } else if navigationController.rootViewController is FTShelfTagsViewController {
                toolbar.switchMode(.tags)
            } else {
                toolbar.switchMode(.shelf)
            }
            toolbar.showBackButton(viewController.isRootViewController ? false : true)
        }
    }

    private func checkIfShelfContentViewControllerExists(from navController: UINavigationController) -> Bool {
        let controller = navController.rootViewController
        var status = false
        if (controller is FTShelfContentPhotoViewController || controller is FTShelfContentAudioViewController || controller is FTShelfBookmarksViewController) {
            status = true
        }
        return status
    }
}
#endif
