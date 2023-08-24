//
//  SceneDelegate_Mac_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import CoreFoundation


#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
}

protocol FTToolbarActionDelegate: NSObjectProtocol {
    func toolbarCurrentDeskMode(_ toolbar: NSToolbar) -> RKDeskMode;
    func toolbar(_ toolbar: NSToolbar, canPerformAction item: NSToolbarItem) -> Bool
    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem);
    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?);
}

extension FTToolbarActionDelegate {
    func toolbarCurrentDeskMode(_ toolbar: NSToolbar) -> RKDeskMode {
        return RKDeskMode.deskModeView;
    }

    func toolbar(_ toolbar: NSToolbar, canPerformAction item: NSToolbarItem) -> Bool {
        return false;
    }
    
    func toolbar(_ toolbar: NSToolbar, toolbarItem item: NSToolbarItem) {
        
    }
    
    func toolbar(_ toolbar: NSToolbar, didTapOnMenuitem menuItem: UIAction.Identifier?) {
        
    }
}
protocol FTSearchToolbarActionDelegate: NSObjectProtocol {
    func toolbarDidBeginSearch(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField)
    func didChangeText(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField)
    func didTapOnSuggestion(_ toolbarId: NSToolbar.Identifier, suggestionItem: FTSuggestedItem, textField: UISearchTextField)
    func didTapSearchClear(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField)
    func didTextEndEditing(_ toolbarId: NSToolbar.Identifier, textField: UISearchTextField)
}

public enum FTShelfToolbarMode: Int {
    case shelf,trash,selectNotes,templatePreview,content, tags;
}

class FTShelfToolbar: NSToolbar {
    weak var toolbarActionDelegate: FTToolbarActionDelegate?
    weak var searchActionDelegate: FTSearchToolbarActionDelegate?

    weak var windowScene: UIWindowScene?;
    var sheflToolbarMode = FTShelfToolbarMode.shelf;
    let toolbardel = FTShelfToolbarDelegate();
    
    required init(windwowScene scene: UIWindowScene?) {
        let uniqueID = scene?.session.persistentIdentifier ?? UUID().uuidString;
        super.init(identifier: "shelf_toolbar_\(uniqueID)");
        self.allowsUserCustomization = false;
        self.delegate = toolbardel;
        self.displayMode = .iconOnly
        self.windowScene = scene;
    }

    func getToolbarItem(with id: NSToolbarItem.Identifier) -> NSToolbarItem? {
        let reqItem: NSToolbarItem? = self.items.first(where: { $0.itemIdentifier == id })
        return reqItem
    }

    func showBackButton(_ show: Bool) {
        let item = self.items.first(where: {$0.itemIdentifier == FTShelfBackToolbarItem.identifier});
        if show {
            if nil == item {
                self.insertItem(withItemIdentifier: FTShelfBackToolbarItem.identifier, at: 1);
            }
        }
        else if let _item = item, let index = self.items.firstIndex(of: _item) {
            self.removeItem(at: index);
        }
    }

    // MARK: The reason to have following 2 functions(resignSearchToolbar, updateSearchText)
    // As we donot get FTShelfSearchToolbarItem type from toolbar items. System is always giving us default type like - NSUIViewToolbarITem instead of our custom type, if we force to use, it gives EXC BAD exception.
    func resignSearchToolbar() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTShelfSearchToolbarNotifiers.resignSearchToolbarItem.rawValue),
                                        object: self,
                                        userInfo: nil)
    }

    func updateSearchText(_ text: String) {
        let userInfo = ["searchText": text]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTShelfSearchToolbarNotifiers.updateRecentSearchText.rawValue),
                                        object: self,
                                        userInfo: userInfo)
    }

    func switchMode(_ mode: FTShelfToolbarMode) {
        if(mode != self.sheflToolbarMode) {
            self.sheflToolbarMode = mode;
            if let identifiers  = self.delegate?.toolbarDefaultItemIdentifiers?(self) {
                while(self.items.count > 0) {
                    self.removeItem(at: 0);
                }

                var index: Int = 0;
                identifiers.forEach { eachItem in
                    self.insertItem(withItemIdentifier: eachItem, at: index);
                    index += 1;
                }
            }
        }
    }
}

extension SceneDelegate {
    var toolbar: NSToolbar? {
        return self.window?.windowScene?.titlebar?.toolbar;
    }
    
    weak var toolbarActionDelegate: FTToolbarActionDelegate? {
        set {
            (self.toolbar as? FTShelfToolbar)?.toolbarActionDelegate = newValue
        }
        get {
            return (self.toolbar as? FTShelfToolbar)?.toolbarActionDelegate;
        }
    }

    weak var searchActionDelegate: FTSearchToolbarActionDelegate? {
        set {
            (self.toolbar as? FTShelfToolbar)?.searchActionDelegate = newValue
        }
        get {
            return (self.toolbar as? FTShelfToolbar)?.searchActionDelegate
        }
    }
}

class FTShelfToolbarDelegate: NSObject, NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var items = [NSToolbarItem.Identifier]();
        if let shelfToolbar = toolbar as? FTShelfToolbar {
            let mode = shelfToolbar.sheflToolbarMode;
            switch mode {
            case .shelf:
                items = [
                    FTShelfToogleSidebarToolbarItem.identifier
                    , NSToolbarItem.Identifier.flexibleSpace
                    , FTShelfAddToolbarItem.identifier
                    , FTShelfMoreToolbarItem.identifier
                    , FTShelfSearchToolbarItem.identifier
                ]
            case .trash:
                items = [
                    FTShelfToogleSidebarToolbarItem.identifier
                    , NSToolbarItem.Identifier.flexibleSpace
                    , FTShelfEmptyTrashToolbarItem.identifier
                    , FTSelectToolbarItem.identifier
                ]
            case .selectNotes:
                items = [
                            NSToolbarItem.Identifier.flexibleSpace
                         , FTSelectNotesToolbarItem.identifier
                         , FTSelectDoneToolbarItem.identifier
                ]
            case .templatePreview:
                items = [
                    FTShelfToogleSidebarToolbarItem.identifier
                    , FTShelfBackToolbarItem.identifier
                ]
            case .content:
                items = [
                    FTShelfToogleSidebarToolbarItem.identifier
                    ]
            case .tags:
                items = [
                    FTShelfToogleSidebarToolbarItem.identifier
                    , NSToolbarItem.Identifier.flexibleSpace
                    , FTSelectToolbarItem.identifier
                ]
            }
        }
        return items
    }
        
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if(itemIdentifier == FTShelfToogleSidebarToolbarItem.identifier) {
            return FTShelfToogleSidebarToolbarItem();
        }
        if(itemIdentifier == FTShelfBackToolbarItem.identifier) {
            return FTShelfBackToolbarItem();
        }
        if(itemIdentifier == FTShelfAddToolbarItem.identifier) {
            return FTShelfAddToolbarItem()
        }
        else if(itemIdentifier == FTShelfMoreToolbarItem.identifier) {
            return FTShelfMoreToolbarItem();
        }
        else if(itemIdentifier == FTShelfSearchToolbarItem.identifier) {
            return FTShelfSearchToolbarItem()
        }
        else if(itemIdentifier == FTNewNotebookBackToolbarItem.identifier) {
            return FTNewNotebookBackToolbarItem()
        }
        else if(itemIdentifier == FTShelfEmptyTrashToolbarItem.identifier) {
            return FTShelfEmptyTrashToolbarItem()
        } else if(itemIdentifier == FTSelectNotesToolbarItem.identifier) {
            return FTSelectNotesToolbarItem()
        } else if(itemIdentifier == FTSelectDoneToolbarItem.identifier) {
            return FTSelectDoneToolbarItem()
        } else if(itemIdentifier == FTSelectToolbarItem.identifier) {
            return FTSelectToolbarItem()
        }
        return nil
    }
}

extension SceneDelegate: UISearchBarDelegate, UISearchTextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let toolbar = self.window?.toolbar, let searchField = textField as? UISearchTextField else {
            return
        }
        self.searchActionDelegate?.didChangeText(toolbar.identifier, textField: searchField)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let toolbar = self.window?.toolbar, let searchField = textField as? UISearchTextField else {
            return
        }
        self.searchActionDelegate?.toolbarDidBeginSearch(toolbar.identifier, textField: searchField)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        guard let toolbar = self.window?.toolbar, let searchField = textField as? UISearchTextField else {
            return false
        }
        self.searchActionDelegate?.didTapSearchClear(toolbar.identifier, textField: searchField)
        return true
    }
}

enum FTMenuIdentifier: Int {
    case displayOptions,sortOptions;
    var menuID: UIMenu.Identifier {
        switch self {
        case .displayOptions:
            return UIMenu.Identifier("displayOptions");
        case .sortOptions:
            return UIMenu.Identifier("sortOptions");
        }
    }
}

extension UIViewController {
    var nsToolbar: NSToolbar? {
        return self.view.toolbar
    }
    
    var titlebar: UITitlebar? {
        return self.view.titlebar
    }
    
    var windowTitle: String? {
        get {
            return self.view.uiWindowScene?.title;
        }
        set {
            self.view.uiWindowScene?.title = newValue;
        }
    }
}

extension UIView {
    var toolbar: NSToolbar? {
        return self.titlebar?.toolbar;
    }
    
    var titlebar: UITitlebar? {
        return self.uiWindowScene?.titlebar;
    }
    
    var uiWindowScene: UIWindowScene? {
        if let _window = self as? UIWindow {
            return _window.windowScene;
        }
        return self.window?.windowScene;
    }
}
#endif
