//
//  FTShelfBottomToolbarViewModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/05/22.
//

import Foundation

protocol FTShelfBottomToolbarDelegate: AnyObject {
    func createGroup()
    func changeCover()
    func duplicateShelfItems()
    func renameShelfItems()
    func moveShelfItems()
    func shareShelfItems()
    func trashShelfItems()
    func deleteShelfItems()
    func restoreShelfItems()
    func tagsShelfItems()
}

class FTShelfBottomToolbarViewModel: ObservableObject {
    weak var delegate: FTShelfBottomToolbarDelegate?
}
