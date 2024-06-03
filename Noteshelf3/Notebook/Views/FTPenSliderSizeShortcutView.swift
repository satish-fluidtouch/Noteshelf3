//
//  FTPenSliderSizeShortcutView.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 31/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import FTStyles

struct FTPenSliderSizeShortcutView: View {
    let startAngle: Angle //= .degrees(Double(FTPenSliderConstants.penShortcutColorItems * FTPenSliderConstants.spacingAngle))
    @EnvironmentObject var viewModel: FTFavoriteSizeViewModel

    var body: some View {
        GeometryReader {geometry in
            ZStack {
                ForEach(0..<viewModel.favoritePenSizes.count, id: \.hashValue) { index in
                    let favSize = viewModel.favoritePenSizes[index]
                    let viewSize = viewModel.currentPenset.type.getIndicatorSize(using: favSize.size)
                    let angle = Angle(degrees: startAngle.degrees + (Double(FTPenSliderConstants.spacingAngle) * Double(index)) - Double(FTPenSliderConstants.rotationAngle))
                    let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometry.size.width / 2
                    let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometry.size.height / 2
                    if self.canShowSizeView(favSize: favSize) {
                        FTPenSizeView(isSelected: favSize.isSelected, showIndicator: false, viewSize: viewSize, favoriteSizeValue: favSize.size, placement: viewModel.getCurrentPlacement())
                            .hoverEffect()
                            .position(x: x, y: y)
                            .onTapGesture {
                                self.handleTapAction(sizeModel: favSize, index: index)
                            }
                            .onLongPressGesture {
                                self.handleLongpressAction(sizeModel: favSize, index: index)
                            }
                    }
                }
            }
        }
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
        if !sizeModel.isSelected {
            self.viewModel.resetSizeSelection()
            sizeModel.isSelected = true
            self.viewModel.updateCurrentPenSize(size: sizeModel.size, sizeMode: .sizeSelect)
        }
    }

    private func handleLongpressAction(sizeModel: FTPenSizeModel, index: Int) {
        self.handleSizeSelection(sizeModel: sizeModel, index: index)
        self.viewModel.showSizeEditScreen(index: index)
    }
}
