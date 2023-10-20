//
//  FTPenShortcutView.swift
//  Noteshelf3
//
//  Created by Narayana on 15/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenColorShortcutView: View {
    @EnvironmentObject var viewModel: FTFavoriteColorViewModel
    @State private var showMoreColorsView: Bool = false
    @State private var isContextMenuVisible = false

    var body: some View {
        VStack(spacing: FTSpacing.small) {
            ForEach(0..<viewModel.favoriteColors.count, id: \.self) { index in
                let favColor = viewModel.favoriteColors[index]
                self.buildContentView(for: favColor, at: index)
                    .macOnlyPlainButtonStyle()
            }
        }
        .frame(width: shortcutWidth)
        .onAppear {
            self.viewModel.fetchColorData()
        }
    }

    @ViewBuilder
    private func buildContentView(for favColor: FTPenColorModel, at index: Int) -> some View {
        let colorPosition = FavoriteColorPosition.getPosition(index: index)
        if colorPosition == .custom {
            self.customColorView(for: favColor)
                .onTapGesture {
                    self.handleColorSelection(colorModel: favColor)
                    self.viewModel.showEditColorScreen(at: colorPosition)
                }
        } else {
            Button {
                if !favColor.isSelected {
                    self.handleTapAction(favColor: favColor, position: colorPosition)
                }
            } label: {
                FTPenColorCircleView(hexColor: favColor.hex, isSelected: favColor.isSelected)
                    .hoverEffect()
                    .contextMenu {
                        Button(action: {
                            self.handleColorSelection(colorModel: favColor)
                            self.viewModel.showEditColorScreen(at: colorPosition)
                        }) {
                            Label("color.editColor".localized, systemImage: "pencil")
                        }
                        Button(action: {
                            self.viewModel.resetToDefaultColor(at: colorPosition)
                        }) {
                            Label("color.resetToDefault".localized, systemImage: "arrow.counterclockwise")
                        }
                        .disabled(viewModel.isItDefaultColor(at: colorPosition))
                    } preview: {
                        FTPenColorCircleView(hexColor: favColor.hex, isSelected: favColor.isSelected)
                    }
                    .onAppear {
                        // Context menu issue for first time is fixed with empty oin appear(hack)
                        // Better solution would be appericiated
                    }
            }
        }
    }

    @ViewBuilder
    private func customColorView(for favColor: FTPenColorModel) -> some View {
        let circleSize: CGFloat = 24.0
        let overlaySize: CGFloat = 16.0

        if !favColor.isSelected {
            Image("rainbow").renderingMode(.original)
                .frame(width: circleSize, height: circleSize)
        } else {
            Image("rainbowSelected").renderingMode(.original)
                .frame(width: circleSize + 2.0, height: circleSize + 2.0)
                .overlay(
                    Image("rainbowSelected").renderingMode(.template)
                        .resizable()
                        .frame(width: overlaySize, height: overlaySize)
                        .cornerRadius(overlaySize/2.0)
                        .foregroundColor(Color(hex: favColor.hex))
                )
        }
    }

    private func handleTapAction(favColor: FTPenColorModel, position: FavoriteColorPosition) {
        if !favColor.isSelected {
            self.handleColorSelection(colorModel: favColor)
        }
    }

    private func handleColorSelection(colorModel: FTPenColorModel) {
        self.viewModel.resetFavoriteColorSelection()
        colorModel.isSelected = true
        self.viewModel.updateCurrentSelection(colorHex: colorModel.hex)
    }
}

struct FTPenColorShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        FTPenColorShortcutView()
            .environmentObject(FTFavoriteColorViewModel(rackData: FTRackData(type: .pen, userActivity: nil), delegate: nil, scene: nil))
    }
}
