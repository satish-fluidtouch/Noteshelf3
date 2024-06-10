//
//  FTFavoriteColorGridView.swift
//  Noteshelf3
//
//  Created by Narayana on 09/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTFavoriteColorGridView: View {
    @StateObject var gridVm = FTColorGridModel()
    @StateObject var hexInputVm = FTColorHexInputViewModel()

    @State private var colorSelectModeImage = FTPenColorSelectModeImage.add
    @State private var touchLocation: CGPoint?

    @EnvironmentObject var viewModel: FTFavoritePresetsViewModel

    var body: some View {
        ZStack {
            VStack(spacing: FTSpacing.small) {
                self.colorsGridView
                FTFavHexFieldFooterView(colorSelectModeImage: $colorSelectModeImage)
                    .environmentObject(self.hexInputVm)
                    .environmentObject(self.viewModel)
            }
        }
        .coordinateSpace(name: "screen")
        .onAppear {
            self.hexInputVm.text = self.viewModel.currentSelectedColor
        }
    }

    private var colorsGridView: some View {
        LazyVGrid(columns: gridItemLayout, spacing: FTSpacing.zero) {
            ForEach(0..<self.gridVm.gridColors.count, id: \.self) { index in
                let gridColor = self.gridVm.gridColors[index]
                let color = gridColor.color
                HStack {
                }.frame(width: 25.6,height: 25.6)
                    .zIndex(self.isSelectedColor(colorModel: gridColor) ? 1 : 0)
                    .background(
                        GeometryReader { geometry in
                            Color(hex: color)
                                .onFirstAppear(perform: {
                                    gridColor.location = geometry.frame(in: CoordinateSpace.named("screen"))
                                })
                        })
                    .overlay(self.isSelectedColor(colorModel: gridColor) ? Image("selectedGrid").resizable().frame(width: 27.0, height: 27.0).shadow(color: Color.appColor(.black20), radius: 2.0, x: 0.0, y: 0.0) : nil)
                    .onTapGesture {
                        colorSelectModeImage = .add
                        self.hexInputVm.text = color
                        self.viewModel.updateCurrentSelection(colorHex: color)
                    }

                    .gesture(DragGesture(coordinateSpace: .named("screen"))
                        .onChanged { value in
                            self.touchLocation = value.location
                        })
            }
            .onChange(of: self.touchLocation) { newValue in
                if let loc = self.touchLocation, let gridColor =  self.gridVm.getGridColor(at: loc) {
                    self.hexInputVm.text = gridColor.color
                }
            }
        }
    }

    private func isSelectedColor(colorModel: FTGridColor) -> Bool {
        return self.viewModel.currentSelectedColor == colorModel.color
    }

    private var gridItemLayout: [GridItem] {
        return [GridItem(.adaptive(minimum: 25.6, maximum: 25.6), spacing: FTSpacing.zero)]
    }
}

struct FTFavoriteColorGridView_Previews: PreviewProvider {
    static var previews: some View {
        FTFavoriteColorGridView()
            .environmentObject(FTFavoritePresetsViewModel(segment: .pen, currentSelectedColor: "000000", userActivity: nil))
    }
}
