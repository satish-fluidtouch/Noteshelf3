//
//  FTNotebookToolbar.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 30/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
class FTNotebookToolbar: NSToolbar {
    private weak var validateToolbarObserver: NSObjectProtocol?;
    private weak var scrollModeObserver: NSObjectProtocol?;

    weak var toolbarActionDelegate: FTToolbarActionDelegate? {
        didSet {
            if let mode = self.toolbarActionDelegate?.toolbarCurrentDeskMode(self) {
                self.selectItem(with: mode)
            }
        }
    }
    
    weak var windowScene: UIWindowScene?;
    weak var undoManager: UndoManager?;
    
    fileprivate var toolbarDelegate = FTNotebookToolbarDelegate();
    
    required init(windowScene: UIWindowScene) {
        super.init(identifier: NSToolbar.Identifier("Notebook_toolbar"));
        self.windowScene = windowScene;
        self.delegate = toolbarDelegate;
        self.allowsUserCustomization = true;
        self.autosavesConfiguration = true;
        windowScene.titlebar?.titleVisibility = .hidden;
        self.selectedItemIdentifier = FTDeskCenterPanelTool.pen.toolbarIdentifier;
        validateToolbarObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            if let mode = strongSelf.toolbarActionDelegate?.toolbarCurrentDeskMode(strongSelf) {
                strongSelf.selectItem(with: mode)
            }
        }
        
        scrollModeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Notification.Name.pageLayoutWillChange.rawValue), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            
            if let item = self?.toolbarItem(FTDeskCenterPanelTool.scrolling.toolbarIdentifier) {
                let layout = UserDefaults.standard.pageLayoutType
                item.image = UIImage(named: layout.toolIconName)
            }
        }
    }
    
    deinit {
        if let observer = self.validateToolbarObserver {
            NotificationCenter.default.removeObserver(observer);
        }
    }
    
    func toolbarItem(_ identifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        let item = self.visibleItems?.first(where: {$0.itemIdentifier == identifier});
        return item;
    }

    func selectItem(with mode: RKDeskMode) {
        if let selTool = FTDeskCenterPanelTool.toolFor(mode: mode) {
            self.selectedItemIdentifier = selTool.toolbarIdentifier;
        }
    }
}

private class FTNotebookToolbarDelegate: NSObject, NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var toolbarItems = [NSToolbarItem.Identifier]();
        toolbarItems.append(contentsOf: FTNotebookToolbarItemType.leftSideItems);
        toolbarItems.append(NSToolbarItem.Identifier.flexibleSpace);

        toolbarItems.append(contentsOf: FTDeskCenterPanelTool.defaultTools);
        
        toolbarItems.append(NSToolbarItem.Identifier.flexibleSpace);
        toolbarItems.append(contentsOf: FTNotebookToolbarItemType.rightSideItems);

        return toolbarItems
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return FTDeskCenterPanelTool.customizableTools;
    }
    
    func toolbarImmovableItemIdentifiers(_ toolbar: NSToolbar) -> Set<NSToolbarItem.Identifier> {
        return Set(FTNotebookToolbarItemType.allItems);
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return FTDeskCenterPanelTool.selectableTools
    }
    
//    func toolbar(_ toolbar: NSToolbar, itemIdentifier: NSToolbarItem.Identifier, canBeInsertedAt index: Int) -> Bool {
//        if index == Int.max {
//            return true;
//        }
//        
//        if(index < toolbar.items.count) {
//            let item = toolbar.items[index];
//            let immovableItems = toolbarImmovableItemIdentifiers(toolbar);
//            if(immovableItems.contains(item.itemIdentifier) || item.itemIdentifier == .flexibleSpace) {
//                return false;
//            }
//            return true;
//        }
//        return false;
//    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if FTDeskCenterPanelTool.customizableTools.contains(itemIdentifier)
            ,let tool = FTDeskCenterPanelTool.toolFor(identifier: itemIdentifier) {
            return FTNotebookToolsToolbarItem(toolType: tool);
        }
        else if itemIdentifier == FTNotebookToolbarItemType.sidebar.toolbarIdentifier {
            return FTNotebookSidebarToolbarItem();
        }
        else if FTNotebookToolbarItemType.allItems.contains(itemIdentifier)
                    , let tool = FTNotebookToolbarItemType.toolFor(itemIdentifier: itemIdentifier) {
            let item = FTNotebookDefaultToolbarItem(toolbarType: tool);
            item.visibilityPriority = .user
            return item
        }
        return nil;
    }
}

extension UIImage {
    class func toolbarImage(_ name: String) -> UIImage?{
//        let config = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 15))
        let config = UIImage.SymbolConfiguration(scale: .large)
        return UIImage(systemName: name,withConfiguration: config) ?? UIImage(named: name, in: nil, with: config);
    }
}

#endif
