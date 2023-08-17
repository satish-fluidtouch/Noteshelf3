//
//  FTColorDropDelegate.swift
//  Noteshelf3
//
//  Created by Narayana on 30/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import MobileCoreServices
import UniformTypeIdentifiers

class FTColorDropInDelegate: DropDelegate {
    let item: FTPenColorModel
    let viewModel: FTPenShortcutViewModel

    init(item: FTPenColorModel, viewModel: FTPenShortcutViewModel) {
        self.item = item
        self.viewModel = viewModel
    }

    func dropEntered(info: DropInfo) {
        self.viewModel.isDragging = true

        guard let dragItem = self.viewModel.currentDraggedItem, dragItem != item,
              let fromIndex = self.viewModel.presetColors.firstIndex(of: dragItem),
              let toIndex = self.viewModel.presetColors.firstIndex(of: item) else {
            return
        }

        if fromIndex != toIndex {
            let removedItem = self.viewModel.presetColors.remove(at: fromIndex)
            self.viewModel.presetColors.insert(removedItem, at: toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        self.viewModel.resetDragging()
        self.viewModel.updateCurrentColors()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

class FTColorDropOutDelegate: DropDelegate {
    let viewModel: FTPenShortcutViewModel

    init(viewModel: FTPenShortcutViewModel) {
        self.viewModel = viewModel
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.viewModel.resetDragging()
        return false
    }

    func dropExited(info: DropInfo) {
        self.viewModel.isDragging = false
    }
}

extension FTPenShortcutViewModel {
    func resetDragging() {
        self.isDragging = false
        self.currentDraggedItem = nil
    }
}
