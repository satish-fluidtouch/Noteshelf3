//
//  UIMenu_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
extension UIMenu {
    static func displayOptionsMenu(onAction:((FTShelfDisplayStyle,UIAction.Identifier?) -> ())?) -> UIMenuElement {
        var items = [UIMenuElement]();
        let styles = FTShelfDisplayStyle.supportedStyles;
        styles.forEach { eachStyle in
            let menuItem = UIAction(title: eachStyle.displayTitle
                                    , identifier: eachStyle.menuIdentifier
                                    , attributes: .standard
                                    , state: (eachStyle == FTShelfDisplayStyle.displayStyle) ? .on : .off) { action in
                onAction?(eachStyle,eachStyle.menuIdentifier);
            };
            items.append(menuItem)
        }
        
        return UIMenu(title: "View By"
                      ,identifier: FTMenuIdentifier.displayOptions.menuID
                      ,options: .displayInline
                      ,children: items);
    }
    
    
    static func sortByOptionsMenu(mode: FTShelfToolbarMode = .shelf
                                  , onAction:((FTShelfSortOrder,UIAction.Identifier?) -> ())?)  -> UIMenuElement {
        var items = [UIMenuElement]()
        
        var styles = FTShelfSortOrder.supportedSortOptions()
        if mode == .ns2 {
            styles = FTShelfSortOrder.supportedSortOptionsForNS2Books()
        }
        styles.forEach { eachStyle in
            let menuItem = UIAction(title: eachStyle.displayTitle
                                    , identifier: eachStyle.menuIdentifier
                                    , attributes: .standard
                                    , state: (eachStyle == FTUserDefaults.sortOrder()) ? .on : .off) { _ in
                onAction?(eachStyle,eachStyle.menuIdentifier);
            };
            items.append(menuItem)
        }
        return UIMenu(title: "Sort By"
                      ,identifier: FTMenuIdentifier.sortOptions.menuID
                      ,options: .displayInline
                      ,children: items);
    }
    
    static func menuFor(_ type: FTHomeNavItemFilteredItemsModel,onAction: ((FTHomeNavItemFilteredItemsModel,UIAction.Identifier?) -> (Void))?)  -> UIMenuElement {
        var items = [UIMenuElement]()
        let menuItem = UIAction(title:type.displayTitle
//                                , image: UIImage(named: type.iconName)
                                , identifier: UIAction.Identifier(type.iconName)) { _ in
            onAction?(type,type.menuIdenfier);
        };
        items.append(menuItem)
        return UIMenu(title: "",options: .displayInline,children: items);
    }
}
#endif
