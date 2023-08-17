//
//  FTNotebookToolbarItemType.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
enum FTNotebookToolbarItemType: Int,CaseIterable {
    case undo,redo, add, more,sidebar,share,back
    static func toolFor(itemIdentifier: NSToolbarItem.Identifier) -> FTNotebookToolbarItemType? {
        return FTNotebookToolbarItemType.allCases.first(where: {$0.toolbarIdentifier == itemIdentifier})
    }
    
    var localizedString: String {
        switch self {
        case .undo:
            return NSLocalizedString("Undo", comment: "Undo");
        case .redo:
            return NSLocalizedString("Redo", comment: "Redo");
        case .add:
            return NSLocalizedString("Add", comment: "Add");
        case .more:
            return NSLocalizedString("More", comment: "More");
        case .sidebar:
            return NSLocalizedString("SideBar", comment: "SideBar");
        case .share:
            return NSLocalizedString("Share", comment: "Share");
        case .back:
            return NSLocalizedString("Back", comment: "Back");
        }
    }
    
    var iconeName: String {
        switch self {
        case .undo:
            return "arrow.uturn.backward";
        case .redo:
            return "arrow.uturn.forward";
        case .add:
            return FTIcon.plus.name;
        case .more:
            return FTIcon.ellipsis.name;
        case .sidebar:
            return "sidebar.left";
        case .share:
            return FTIcon.share.name
        case .back:
            return "chevron.left";
        }
    }
    
    var toolbarIdentifier: NSToolbarItem.Identifier {
        return NSToolbarItem.Identifier("FTNotebookToolbarItem_\(self.rawValue)");
    }
    
    static var leftSideItems: [NSToolbarItem.Identifier] {
        return [
            FTNotebookToolbarItemType.back.toolbarIdentifier
            ,FTNotebookToolbarItemType.sidebar.toolbarIdentifier
            ,FTNotebookToolbarItemType.undo.toolbarIdentifier
            ,FTNotebookToolbarItemType.redo.toolbarIdentifier
        ]
    }
    
    static var rightSideItems: [NSToolbarItem.Identifier] {
        return [
            FTNotebookToolbarItemType.share.toolbarIdentifier
            ,FTNotebookToolbarItemType.add.toolbarIdentifier
            ,FTNotebookToolbarItemType.more.toolbarIdentifier
        ]
    }
        
    static var allItems: [NSToolbarItem.Identifier] {
        var items = [NSToolbarItem.Identifier]();
        items.append(contentsOf: FTNotebookToolbarItemType.leftSideItems);
        items.append(contentsOf: FTNotebookToolbarItemType.rightSideItems);
        return items;
    }

}
#endif
