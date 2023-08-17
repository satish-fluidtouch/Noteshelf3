//
//  FTShelfItemPickerDelegate.swift
//  Noteshelf
//
//  Created by Siva on 02/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit;

protocol FTCurrentShelfItemDelegate: AnyObject {
    func currentShelfItemInShelfItemsViewController() -> FTShelfItemProtocol?;
    func currentGroupShelfItemInShelfItemsViewController() -> FTGroupItemProtocol?;
    func currentShelfItemCollectionInShelfItemsViewController() -> FTShelfItemCollection?;
}

extension FTCurrentShelfItemDelegate {
    func currentShelfItemInShelfItemsViewController() -> FTShelfItemProtocol? {
        return nil;
    }
    
    func currentGroupShelfItemInShelfItemsViewController() -> FTGroupItemProtocol? {
        return nil;
    }
    
    func currentShelfItemCollectionInShelfItemsViewController() -> FTShelfItemCollection? {
        return nil;
    }
}

protocol FTShelfItemMovePagePickerDelegate:  FTShelfItemPickerDelegate {
        func shelfItemsView(_ viewController: FTShelfItemsViewController,
                        didFinishWithNewNotebookTitle title: String,
                        collection: FTShelfItemCollection,
                        group: FTGroupItemProtocol?);
}

protocol FTShelfItemPickerDelegate: FTCurrentShelfItemDelegate {
    func shelfItemsViewControllerDidCancel(_ viewController: FTShelfItemsViewController);
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingShelfItem shelfItem: FTShelfItemProtocol, isNewlyCreated: Bool);
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingGroupShelfItem groupShelfItem: FTGroupItemProtocol?, atShelfItemCollection shelfItemCollection: FTShelfItemCollection!, isNewlyCreated: Bool);
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingCollectionShelfItem collectionShelfItem: FTShelfItemCollection!, groupToMove groupShelfItem :FTGroupItemProtocol, toGroup: FTGroupItemProtocol?)
    func shelfItemsViewController(_ viewController: FTShelfItemsViewController, didFinishPickingShelfItemsForBottomToolBar collectionShelfItem: FTShelfItemCollection!, toGroup: FTGroupItemProtocol?)
}
