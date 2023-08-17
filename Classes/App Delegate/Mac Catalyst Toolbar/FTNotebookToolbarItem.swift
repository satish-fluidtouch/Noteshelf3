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
    let toolType: FTNotebookToolbarItemType;
    required init(toolbarType: FTNotebookToolbarItemType) {
        toolType = toolbarType;
        super.init(itemIdentifier: toolbarType.toolbarIdentifier);
    }
    
    override var imageName: String { return toolType.iconeName}

    override var buttonToolTip: String { return toolType.localizedString}

    override var buttonLabel: String {return toolType.localizedString}
    
    override func validate() {
        super.validate()
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
            displayTitle = NSLocalizedString("DocumentOnly", comment: "Document Only");
        case .thumbnails:
            displayTitle = NSLocalizedString("Thumbnail", comment: "Thumbnail");
        case .bookmarks:
            displayTitle = NSLocalizedString("Bookmarks", comment: "Bookmarks");
        case .mediaContent:
            displayTitle = NSLocalizedString("MediaContent", comment: "Media Content");
        case .tableOfContents:
            displayTitle = NSLocalizedString("TableOfContents", comment: "Table Of Contents");
        case .search:
            displayTitle = NSLocalizedString("Search", comment: "Search");
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
