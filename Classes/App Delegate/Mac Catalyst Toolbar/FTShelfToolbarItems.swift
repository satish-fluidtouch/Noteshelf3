//
//  FTShelfToolbarItems.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
class FTShelfToolbarItem: NSToolbarItem {
    class var identifier: NSToolbarItem.Identifier  {
        NSToolbarItem.Identifier("FTShelfToolbarItem");
    }
    
    convenience init() {
        self.init(itemIdentifier: Self.identifier)
    }
    
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier);
        self.label = self.buttonLabel;
        self.toolTip = self.buttonToolTip;
        self.image = UIImage.toolbarImage(self.imageName);
        self.isBordered = true;
        self.target = self;
        self.action = #selector(self.didTapOnToolbarItem(_:))
    }
    
    @objc func didTapOnToolbarItem(_ item: NSToolbarItem) {
        if let shelfToolbar = self.toolbar as? FTShelfToolbar,
           let delegate  = shelfToolbar.toolbarActionDelegate {
            delegate.toolbar(shelfToolbar, toolbarItem: self);
        }
    }
    var buttonLabel: String {
        return "";
    }
    var buttonToolTip: String {
        return "";
    }
    var imageName: String {
        return "";
    }
}
class FTShelfToogleSidebarToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTShelfToolbarItemToggleSidebar");
    }
    
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier);
        self.isNavigational = true;
    }
    
    override var buttonLabel: String {
        return "Sidebar";
    }
    override var buttonToolTip: String {
        return "Sidebar";
    }
    override var imageName: String {
        return "sidebar.left";
    }
}

class FTShelfAddToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTShelfToolbarItemAdd");
    }
    
    override func validate() {
        super.validate();
        if let shelfToolbar = self.toolbar as? FTShelfToolbar,let canPerform = shelfToolbar.toolbarActionDelegate?.toolbar(shelfToolbar, canPerformAction: self) {
            self.isEnabled = canPerform;
        }
        else {
            self.isEnabled = false;
        }
    }
    
    override var buttonLabel: String {
        return "Add";
    }
    override var buttonToolTip: String {
        return "Add";
    }
    override var imageName: String {
        return FTIcon.plus.name;
    }
}

class FTShelfBackToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTShelfBackoolbarItem");
    }
    
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier);
        self.isNavigational = true;
    }

    override var buttonLabel: String {
        return "Back";
    }
    override var buttonToolTip: String {
        return "Back";
    }
    override var imageName: String {
        return FTIcon.leftArrow.name;
    }
}

class FTShelfEmptyTrashToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTShelfEmptyTrashToolbarItem");
    }
    
    convenience init() {
        let barButton = UIBarButtonItem(title: "Empty".localized, style: .done, target: nil, action: nil);
        self.init(itemIdentifier: Self.identifier, barButtonItem: barButton);
        self.toolTip = self.buttonToolTip
        self.isBordered = true;
        self.target = self;
        self.action = #selector(self.didTapOnToolbarItem(_:));
    }
    
    override var buttonLabel: String {
        return "Empty".localized;
    }

    override var buttonToolTip: String {
        return "Empty".localized;
    }
    
    override var imageName: String {
        return "";
    }
    
    override func validate() {
        super.validate();
        var canPerform = false;
        if let sheflToolbar = self.toolbar as? FTShelfToolbar {
            canPerform = sheflToolbar.toolbarActionDelegate?.toolbar(sheflToolbar, canPerformAction: self) ?? false;
        }
        self.isEnabled = canPerform;
    }
}

class FTSelectNotesToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTSelectNotesToolbarItem");
    }

    convenience init() {
        let btn = UIBarButtonItem(title: "shelf.navBar.selectAll".localized, style: .plain, target: nil, action: nil)
        self.init(itemIdentifier: Self.identifier, barButtonItem: btn)
        self.toolTip = self.buttonToolTip
        self.isBordered = true
        self.target = self
        self.action = #selector(self.didTapOnToolbarItem(_:))
    }

    override var buttonLabel: String {
        return self.title
    }

    override var buttonToolTip: String {
        return self.title
    }

    override var imageName: String {
        return ""
    }
}

class FTSelectToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTSelectToolbarItem")
    }

    convenience init() {
        let btn = UIBarButtonItem(title: "shelf.navBar.select".localized, style: .plain, target: nil, action: nil)
        self.init(itemIdentifier: Self.identifier, barButtonItem: btn)
        self.toolTip = self.buttonToolTip
        self.isBordered = true
        self.target = self
        self.action = #selector(self.didTapOnToolbarItem(_:))
    }

    override func validate() {
        super.validate()
        var canPerform = false;
        if let sheflToolbar = self.toolbar as? FTShelfToolbar {
            canPerform = sheflToolbar.toolbarActionDelegate?.toolbar(sheflToolbar, canPerformAction: self) ?? false;
        }
        self.isEnabled = canPerform;
    }

    override var buttonLabel: String {
        return self.title
    }

    override var buttonToolTip: String {
        return self.title
    }

    override var imageName: String {
        return ""
    }
}

class FTSelectDoneToolbarItem: FTShelfToolbarItem {
    override class var identifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("FTSelectDoneToolbarItem");
    }

    convenience init() {
        let barButton = UIBarButtonItem(title: "done".localized, style: .done, target: nil, action: nil)
        self.init(itemIdentifier: Self.identifier, barButtonItem: barButton)
        self.toolTip = self.buttonToolTip
        self.isBordered = true
        self.target = self
        self.action = #selector(self.didTapOnToolbarItem(_:))
    }

    override var buttonLabel: String {
        return "done".localized
    }

    override var buttonToolTip: String {
        return "done".localized
    }

    override var imageName: String {
        return ""
    }
}

class FTShelfMoreToolbarItem: NSMenuToolbarItem {
    static let identifier = NSToolbarItem.Identifier("NSToolbarItemMoreOptions");
    convenience init() {
        self.init(itemIdentifier: Self.identifier)
        self.image = UIImage.toolbarImage(FTIcon.ellipsis.name);
        self.toolTip = "More Options";
        self.label = "More Options";
        self.isBordered = true;
        self.rebuildMenu();
    }

    override func validate() {
        super.validate()
        var canPerform = false;
        if let sheflToolbar = self.toolbar as? FTShelfToolbar {
            canPerform = sheflToolbar.toolbarActionDelegate?.toolbar(sheflToolbar, canPerformAction: self) ?? false;
        }
        self.isEnabled = canPerform
    }

    func updateMenu() {
        self.rebuildMenu()
    }

    private func rebuildMenu() {
        var menuitems = [UIMenuElement]()
        if let shelfToolbar = self.toolbar as? FTShelfToolbar {

            if shelfToolbar.sheflToolbarMode != .ns2 {
                menuitems.append(UIMenu.menuFor(.selectNotes,onAction: { (homeNavitem,identifier) in
                    shelfToolbar.toolbarActionDelegate?.toolbar(shelfToolbar, didTapOnMenuitem: identifier);
                }))
            }

            menuitems.append(UIMenu.sortByOptionsMenu(mode: shelfToolbar.sheflToolbarMode, onAction: { [weak self] (sortOrder,identifier) in
                shelfToolbar.toolbarActionDelegate?.toolbar(shelfToolbar, didTapOnMenuitem: identifier);
                FTUserDefaults.setSortOrder(sortOrder)
                self?.rebuildMenu()
            }));

            menuitems.append(UIMenu.displayOptionsMenu(onAction: { [weak self] (displayStyle,identifier) in
                shelfToolbar.toolbarActionDelegate?.toolbar(shelfToolbar, didTapOnMenuitem: identifier);
                UserDefaults.standard.shelfDisplayStyle = displayStyle.rawValue
                self?.rebuildMenu()
            }))

            let menu = UIMenu(title: "",children: menuitems)
            self.itemMenu = menu
        }
    }
}

extension Notification.Name {
    static let resignSearchToolbarItem = Notification.Name("resignSearchToolbarItem")
    static let updateRecentSearchText = Notification.Name("updateRecentSearchText")
}

class FTShelfSearchToolbarItem: NSToolbarItem {
    private  var searchDelegate: FTShelfSearcharDelegate?
    static let identifier = NSToolbarItem.Identifier("NSToolbarItemSearch");

    convenience init() {
        let searchDel = FTShelfSearcharDelegate();
        let searchBar = UISearchBar();
        searchBar.delegate = searchDel;
        searchBar.searchTextField.delegate = searchDel

        let barButton = UIBarButtonItem(customView: searchBar);
        self.init(itemIdentifier: Self.identifier, barButtonItem: barButton);
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search".localized
        self.label = "Search"
        self.toolTip = "Search"
        self.isBordered = true;
        let widthConstraint = NSLayoutConstraint(item: searchBar, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 220.0)
        searchBar.addConstraint(widthConstraint);
        searchDelegate = searchDel;
        searchDelegate?.toolbarItem = self
        searchDel.searchBar = searchBar;
    }
}

private class FTShelfSearcharDelegate: NSObject,UISearchBarDelegate, UISearchTextFieldDelegate {
    weak var toolbarItem: FTShelfSearchToolbarItem?;
    weak var searchBar: UISearchBar?

    @objc private func resignSearchToolbarItem(_ notification: Notification) {
        self.searchBar?.text = ""
        self.searchBar?.resignFirstResponder()
    }

    @objc private func updateRecentSearchText(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let searchText = userInfo["searchText"] as? String {
            self.searchBar?.text = searchText
        }
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.resignSearchToolbarItem(_:)), name: .resignSearchToolbarItem, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateRecentSearchText(_:)), name: .updateRecentSearchText, object: nil);
    }

     func textFieldDidChangeSelection(_ textField: UITextField) {
         guard let toolbar = self.toolbarItem?.toolbar as? FTShelfToolbar, let searchDelegate = toolbar.searchActionDelegate, let searchTf = textField as? UISearchTextField else {
             return
         }
         searchDelegate.didChangeText(toolbar.identifier, textField: searchTf)
    }

    func searchTextField(_ searchTextField: UISearchTextField, didSelect suggestion: UISearchSuggestion) {
        guard let toolbar = self.toolbarItem?.toolbar as? FTShelfToolbar, let searchDelegate = toolbar.searchActionDelegate else {
            return
        }

        if let suggestion = suggestion.representedObject as? FTSuggestedItem {
            searchDelegate.didTapOnSuggestion(toolbar.identifier, suggestionItem: suggestion, textField: searchTextField)
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let toolbar = self.toolbarItem?.toolbar as? FTShelfToolbar, let searchDelegate = toolbar.searchActionDelegate, let searchTf = textField as? UISearchTextField
        else {
            return
        }
        searchDelegate.toolbarDidBeginSearch(toolbar.identifier, textField: searchTf);
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let toolbar = self.toolbarItem?.toolbar as? FTShelfToolbar, let searchDelegate = toolbar.searchActionDelegate, let searchTf = textField as? UISearchTextField
        else {
            return
        }
        searchDelegate.didTextEndEditing(toolbar.identifier, textField: searchTf)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        guard let toolbar = self.toolbarItem?.toolbar as? FTShelfToolbar, let searchDelegate = toolbar.searchActionDelegate, let searchTf = textField as? UISearchTextField
        else {
            return false
        }
        searchDelegate.didTapSearchClear(toolbar.identifier, textField: searchTf)
        return true
    }
}

class FTNewNotebookBackToolbarItem: NSToolbarItem {
    static let identifier = NSToolbarItem.Identifier("NSToolbarItemNavBack")
    convenience init() {
        let barButton = UIBarButtonItem(image: UIImage(icon: FTIcon.autoBackup)
                                        , style: .plain
                                        , target: nil
                                        , action: nil);
        self.init(itemIdentifier: Self.identifier, barButtonItem: barButton)
        self.label = "Add";
        self.toolTip = "Add";
        self.isNavigational = true;
    }
}
#endif
