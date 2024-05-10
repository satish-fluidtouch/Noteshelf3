//
//  FTColorGridView.swift
//  Noteshelf3
//
//  Created by Narayana on 20/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles
import Combine

struct FTColorGridView: View {
    @StateObject var gridVm = FTColorGridModel()
    @StateObject var hexInputVm = FTColorHexInputViewModel()

    @State private var colorSelectModeImage = FTPenColorSelectModeImage.add
    @State private var touchLocation: CGPoint?

    @EnvironmentObject var viewModel: FTPenShortcutViewModel

    var colorMode: FTPenColorMode

    var body: some View {
        ZStack {
            VStack(spacing: FTSpacing.small) {
                self.colorsGridView
                FTHexFieldFooterView(colorSelectModeImage: $colorSelectModeImage, colorMode: colorMode)
                    .environmentObject(self.hexInputVm)
                    .environmentObject(self.viewModel)
            }
        }
        .frame(width: 288.0)
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
                }.frame(width: 24.0,height: 24.0)
                    .zIndex(self.isSelectedColor(colorModel: gridColor) ? 1 : 0)
                    .background(
                        GeometryReader { geometry in
                            Color(hex: color)
                                .onFirstAppear(perform: {
                                    gridColor.location = geometry.frame(in: CoordinateSpace.named("screen"))
                                })
                        })
                    .overlay(self.isSelectedColor(colorModel: gridColor) ? Image("selectedGrid").resizable().frame(width: 25.0, height: 25.0).shadow(color: Color.appColor(.black20), radius: 2.0, x: 0.0, y: 0.0) : nil)
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
        return [GridItem(.adaptive(minimum: 24.0, maximum: 24.0), spacing: FTSpacing.zero)]
    }
}

struct FTColorGridView_Previews: PreviewProvider {
    static var previews: some View {
        FTColorGridView(colorMode: .presetEdit)
            .environmentObject(FTPenShortcutViewModel(rackData: FTRackData(type: .pen, userActivity: nil)))
    }
}
