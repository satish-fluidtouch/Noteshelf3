//
//  FTStickerDropDelegate.swift
//  Noteshelf3
//
//  Created by Sameer on 04/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

class FTStickerDropDelegate: DropDelegate {
    let viewModel: FTStickerCategoriesViewModel
    init(viewModel: FTStickerCategoriesViewModel) {
        self.viewModel = viewModel
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    func performDrop(info: DropInfo) -> Bool {
        print("Perform drop DONE")
        return false
    }

    func dropExited(info: DropInfo) {
        self.viewModel.stickerDelegate?.dismiss()
        print("EXIT DONE")
    }
}
