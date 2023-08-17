//
//  FTPenSizeShortcutView.swift
//  Noteshelf3
//
//  Created by Narayana on 21/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenSizeShortcutView: View {
    @EnvironmentObject var viewModel: FTFavoriteSizeViewModel

    var body: some View {
        VStack(spacing: 6.0) {
            ForEach(0..<viewModel.favoritePenSizes.count, id: \.hashValue) { index in
                let favSize = viewModel.favoritePenSizes[index]
                let viewSize = viewModel.getViewSize(using: favSize.size)

                if self.canShowSizeView(favSize: favSize) {
                    FTPenSizeView(isSelected: favSize.isSelected, showIndicator: false, viewSize: viewSize, favoriteSizeValue: favSize.size)
                        .hoverEffect()
                        .onTapGesture {
                            self.handleTapAction(sizeModel: favSize, index: index)
                        }
                        .onLongPressGesture {
                            self.handleLongpressAction(sizeModel: favSize, index: index)
                        }
                }
            }
        }
        .frame(width: shortcutWidth)
        .onAppear {
             self.viewModel.fetchSizesData()
        }
    }

    private func canShowSizeView(favSize: FTPenSizeModel) -> Bool {
        var canShow = true
        if UIDevice.current.isPhone() {
            canShow = favSize.isSelected
        }
        return canShow
    }

    private func handleTapAction(sizeModel: FTPenSizeModel, index: Int) {
        if sizeModel.isSelected {
            self.handleLongpressAction(sizeModel: sizeModel, index: index)
        } else {
            self.handleSizeSelection(sizeModel: sizeModel, index: index)
        }
    }

    private func handleSizeSelection(sizeModel: FTPenSizeModel, index: Int) {
        self.viewModel.resetSizeSelection()
        sizeModel.isSelected = true
        self.viewModel.updateCurrentPenSize(size: sizeModel.size, sizeMode: .sizeSelect)
    }

    private func handleLongpressAction(sizeModel: FTPenSizeModel, index: Int) {
        self.handleSizeSelection(sizeModel: sizeModel, index: index)
        self.viewModel.showSizeEditScreen(index: index)
    }
}

struct FTToolbarSizeShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        FTPenSizeShortcutView()
    }
}
