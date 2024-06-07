//
//  FTShapeCurvedShortcutView.swift
//  Noteshelf3
//
//  Created by Sameer on 01/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
struct FTShapeCurvedShortcutView: View {
    @StateObject var shapeModel: FTFavoriteShapeViewModel
    @StateObject var colorModel: FTFavoriteColorViewModel
    @StateObject var sizeModel: FTFavoriteSizeViewModel

    weak var delegate: FTShapeShortcutEditDelegate?

    var body: some View {
        ZStack {
            FTCurvedFavoriteShapesView(startAngle: FTPenSliderConstants.startAngle)
                .environmentObject(shapeModel)
            FTPenSliderColorShortcutView(startAngle: .degrees(Double(FTPenSliderConstants.shapeTypeShortcutItems * FTPenSliderConstants.spacingAngle)) + FTPenSliderConstants.startAngle)
                .environmentObject(colorModel)
            FTPenSliderSizeShortcutView(startAngle: .degrees(Double((FTPenSliderConstants.shapeTypeShortcutItems + FTPenSliderConstants.shapeShortcutColorItems) * FTPenSliderConstants.spacingAngle)) + FTPenSliderConstants.startAngle)
                .environmentObject(sizeModel)
        }
    }
}

struct FTCurvedFavoriteShapesView: View {
    @EnvironmentObject var viewModel: FTFavoriteShapeViewModel
    let startAngle: Angle

    var body: some View {
        GeometryReader {geometry in
            ZStack {
                ForEach(0..<viewModel.favoriteShapes.count, id: \.hashValue) { index in
                    let shapeModel = viewModel.favoriteShapes[index]
                    let angle = Angle(degrees: startAngle.degrees + (Double(FTPenSliderConstants.spacingAngle) * Double(index)) - Double(FTPenSliderConstants.rotationAngle))
                    let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometry.size.width / 2
                    let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometry.size.height / 2
                    
                    if self.canShowShapeView(favShape: shapeModel) {
                        FTFavoriteShapeView(isSelected: shapeModel.isSelected, shapeType: shapeModel.shape)
                            .position(x: x, y: y)
                            .hoverEffect()
                            .onTapGesture {
                                self.handleTapAction(shapeModel: shapeModel, index: index)
                            }
                            .onLongPressGesture {
                                self.handleLongPressAction(shapeModel: shapeModel, index: index)
                            }
                    }
                }
            }
        }
        .onAppear {
             self.viewModel.fetchShapesData()
        }
    }

    private func canShowShapeView(favShape: FTPenShapeModel) -> Bool {
        var canShow = true
        if UIDevice.current.isPhone() {
            canShow = favShape.isSelected
        }
        return canShow
    }

    private func handleTapAction(shapeModel: FTPenShapeModel, index: Int) {
        if shapeModel.isSelected {
            self.handleLongPressAction(shapeModel: shapeModel, index: index)
        } else {
            self.handleShapeSelection(shapeModel: shapeModel, index: index)
        }
    }

    private func handleLongPressAction(shapeModel: FTPenShapeModel, index: Int) {
        self.handleShapeSelection(shapeModel: shapeModel, index: index)
        self.viewModel.showShapeEditScreen(index: index)
    }

    private func handleShapeSelection(shapeModel: FTPenShapeModel, index: Int) {
        self.viewModel.resetShapeSelection()
        shapeModel.isSelected = true
        let pos = FavoriteShapePosition.getPosition(index: index)
        self.viewModel.handleFavoriteShapeSelection(shapeModel.shape, index: pos)
        shapeModel.shape.saveSelection()
    }
}
