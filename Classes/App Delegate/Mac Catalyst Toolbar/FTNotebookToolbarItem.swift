//
//  FTNotebookToolbarItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
class FTNotebookToolbarItem: NSToolbarItem {
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier);
        self.label = self.buttonLabel;
        self.toolTip = self.buttonToolTip;
        self.target = self;
        self.action = #selector(self.didTapOnButton);
        self.isBordered = true;
        self.image = UIImage.toolbarImage(self.imageName)
    }
    
    override func validate() {
        super.validate()
    }

    @objc func didTapOnButton() {
        if let notebookToolbar = self.toolbar as? FTNotebookToolbar {
            notebookToolbar.toolbarActionDelegate?.toolbar(notebookToolbar, toolbarItem: self);
        }
    }
    
    var imageName: String { return ""}

    var buttonToolTip: String { return ""}

    var buttonLabel: String {return ""}
}

class FTNotebookDefaultToolbarItem: FTNotebookToolbarItem {
    private weak var validateTOolbarObserver: NSObjectProtocol?;
    
    let toolType: FTNotebookToolbarItemType;
    required init(toolbarType: FTNotebookToolbarItemType) {
        toolType = toolbarType;
        super.init(itemIdentifier: toolbarType.toolbarIdentifier);
    }
    
    override var imageName: String { return toolType.iconeName}

    override var buttonToolTip: String { return toolType.localizedString}

    override var buttonLabel: String {return toolType.localizedString}
    
    deinit {
        self.removeObserver();
    }
    
    private func removeObserver() {
        if let observer = self.validateTOolbarObserver {
            NotificationCenter.default.removeObserver(observer);
        }
    }
    override func validate() {
        super.validate()
        self.validateUndoRedo()
        self.removeObserver();
        self.validateTOolbarObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            strongSelf.validateUndoRedo()
        }
    }

    private func validateUndoRedo() {
        if(toolType == .undo || toolType == .redo) {
            if let undoManger = (self.toolbar as? FTNotebookToolbar)?.undoManager {
                if(toolType == .undo) {
                    isEnabled = undoManger.canUndo;
                }
                else {
                    isEnabled = undoManger.canRedo;
                }
            }
        }
    }
}

enum FTNotebookSidebarMenuType: Int {
    
    case showDocumentOnly, thumbnails, bookmarks,mediaContent,tableOfContents,search;
    
    static var groupds: [[FTNotebookSidebarMenuType]] {
        return [
            [.showDocumentOnly]
            ,[.thumbnails
              ,.bookmarks
              ,.mediaContent
              ,.tableOfContents]
            ,[.search]
        ]
    }
    
    var localizedstring: String {
        let displayTitle: String;
        switch self {
        case .showDocumentOnly:
            displayTitle = NSLocalizedString("finder.documentonly", comment: "Document Only");
        case .thumbnails:
            displayTitle = "Pages".localized
        case .bookmarks:
            displayTitle = "finder.bookmarks".localized
        case .mediaContent:
            displayTitle = "finder.tabbar.content".localized
        case .tableOfContents:
            displayTitle = "finder.outline".localized
        case .search:
            displayTitle = "Search".localized
        }
        return displayTitle;
    }
    
    var menuIdentifier: UIAction.Identifier {
        let menuID: UIAction.Identifier;
        switch self {
        case .showDocumentOnly:
            menuID = UIAction.Identifier("FTSidebarMenuShowDocumentOnly");
        case .thumbnails:
            menuID = UIAction.Identifier("FTSidebarMenuThumbnails");
        case .bookmarks:
            menuID = UIAction.Identifier("FTSidebarMenuBookmarks");
        case .mediaContent:
            menuID = UIAction.Identifier("FTSidebarMenuMediaContent");
        case .tableOfContents:
            menuID = UIAction.Identifier("FTSidebarMenuTableOfContents");
        case .search:
            menuID = UIAction.Identifier("FTSidebarMenuSearch");
        }
        return menuID;
    }
}

class FTNotebookSidebarToolbarItem: NSMenuToolbarItem {
    let toolType = FTNotebookToolbarItemType.sidebar;
    convenience init() {
        self.init(itemIdentifier: FTNotebookToolbarItemType.sidebar.toolbarIdentifier)
        self.image = UIImage.toolbarImage(toolType.iconeName)
        self.label = toolType.localizedString;
        self.toolTip = toolType.localizedString;
        
        generateMenu(.showDocumentOnly);
    }
    
    override func validate() {
        super.validate()
        //For custom tool item views, validation should be done explicitly. Since side bar item will be enabled always, setting it to true.
        self.isEnabled = true
    }
    
    private func generateMenu(_ selected: FTNotebookSidebarMenuType) {
        var menuitems = [UIMenuElement]();
        FTNotebookSidebarMenuType.groupds.forEach { eachGroup in
            var groupMenuItems = [UIMenuElement]();
            eachGroup.forEach { eachItem in
                groupMenuItems.append(UIAction(title:eachItem.localizedstring
                                               ,identifier: eachItem.menuIdentifier
                                               ,state: (eachItem == selected) ? .on : .off
                                               ,handler: { [weak self] inAction in
                    self?.generateMenu(eachItem);
                    self?.postActionFor(inAction.identifier);
                }));
            }
            if(!groupMenuItems.isEmpty) {
                menuitems.append(UIMenu(options: .displayInline,children: groupMenuItems));
            }
        }
        self.itemMenu = UIMenu(children: menuitems);
    }
    
    private func postActionFor(_ menuID: UIAction.Identifier?) {
        if let toolbar = self.toolbar as? FTNotebookToolbar {
            toolbar.toolbarActionDelegate?.toolbar(toolbar, didTapOnMenuitem: menuID);
        }
    }
}

class FTNotebookToolsToolbarItem: FTNotebookToolbarItem {
    let deskToolType: FTDeskCenterPanelTool;
    required init(toolType: FTDeskCenterPanelTool) {
        deskToolType = toolType;
        super.init(itemIdentifier: toolType.toolbarIdentifier);
    }
    
    override var buttonLabel: String {
        return deskToolType.localizedString();
    }
    
    override var buttonToolTip: String {
        return deskToolType.localizedString();
    }
    
    override var imageName: String {
        return deskToolType.iconName();
    }

    var isSelected: Bool {
        if
            let mode = deskToolType.deskMode
                ,let toolbar = self.toolbar as? FTNotebookToolbar
                , let currentMode = toolbar.toolbarActionDelegate?.toolbarCurrentDeskMode(toolbar) {
            return (currentMode == mode)
        }
        return false;
    }
    
    override func validate() {
        super.validate();
        if FTDeskCenterPanelTool.selectableTools.contains(self.itemIdentifier)
            , let selImage = self.deskToolType.selectedIconName() {
            self.image = UIImage.toolbarImage(self.isSelected ? selImage : self.deskToolType.iconName())
        }
    }
}

#endif
