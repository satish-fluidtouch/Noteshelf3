//
//  FTShapeShortcutView.swift
//  Noteshelf3
//
//  Created by Narayana on 02/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTShapeShortcutView: View {
    @StateObject var shapeModel: FTFavoriteShapeViewModel
    @StateObject var colorModel: FTFavoriteColorViewModel
    @StateObject var sizeModel: FTFavoriteSizeViewModel

    weak var delegate: FTShapeShortcutEditDelegate?

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(100.0)
            HStack(spacing: 0.0) {
                FTFavoriteShapesView()
                    .environmentObject(shapeModel)
                    .padding(.horizontal, 4.0)
                FTToolSeperator()
                    .padding(.horizontal, 2.0)
                FTPenColorShortcutView()
                    .environmentObject(colorModel)
                    .padding(.horizontal, 8.0)
                FTToolSeperator()
                    .padding(.horizontal, 2.0)
                FTPenSizeShortcutView()
                    .environmentObject(sizeModel)
                    .padding(.horizontal, 4.0)
            }
        }
        .toolbarOverlay()
    }
}

struct FTFavoriteShapesView: View {
    @EnvironmentObject var viewModel: FTFavoriteShapeViewModel

    var body: some View {
        HStack(spacing: 6.0) {
            ForEach(0..<viewModel.favoriteShapes.count, id: \.hashValue) { index in
                let shapeModel = viewModel.favoriteShapes[index]

                if self.canShowShapeView(favShape: shapeModel) {
                    FTFavoriteShapeView(isSelected: shapeModel.isSelected, shapeType: shapeModel.shape)
                        .hoverEffect()
                        .rotationEffect(viewModel.contentTransformation)
                        .onTapGesture {
                            self.handleTapAction(shapeModel: shapeModel, index: index)
                        }
                        .onLongPressGesture {
                            self.handleLongPressAction(shapeModel: shapeModel, index: index)
                        }
                }
            }
        }
        .frame(height: shortcutHeight)
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
        shapeModel.shape.saveSelection()
        self.viewModel.handleFavoriteShapeSelection(shapeModel.shape)
    }
}

struct FTShapeShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // test preview here
        }
    }
}
