//
//  FTSideMenuDisplayable.swift
//  Noteshelf3
//
//  Created by Akshay on 05/05/22.
//

import Foundation
import SwiftUI

protocol FTSectionDisplayable {
    var id: String { get }
    var title: String { get }
    var items: [FTSideBarItem] { get }
    var type: FTSidebarSectionType { get }
    var isCreating: Bool { get set }
    var supportsRearrangeOfItems:Bool { get set}

    init(type: FTSidebarSectionType, items: [FTSideBarItem],supportsRearrangeOfItems:Bool)
}

protocol FTSideMenuDisplayable {
    var id: String { get }
    var title: String { get }
    var icon: FTIcon { get }
    var type: FTSideBarItemType { get }
    var isEditable: Bool { get }
}

protocol FTSideMenuRenamable: FTSideMenuDisplayable {
    mutating func rename(newName: String)
}

protocol FTSideMenuDeletable {
    mutating func moveItemToTrash(_ item: FTSideBarItem)
}

protocol FTSideMenuEditable: FTSideMenuRenamable { }
