//
//  FTPresetColorsView.swift
//  Noteshelf3
//
//  Created by Narayana on 16/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPresetColorsView: View {
    @EnvironmentObject var viewModel: FTPenShortcutViewModel
    @State var selectedPage: Int

    var body: some View {
        TabView(selection: $selectedPage) {
            ForEach(0..<3, id: \.self) { index in
                FTPresetSectionView(section: index, viewModel: viewModel)
            }
        }.tabViewStyle(.page)
            .frame(width: 300.0, height: 190.0)
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = .label
                UIPageControl.appearance().pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.2)
                self.viewModel.fetchCurrentColors()
                self.viewModel.colorSelectSegment = FTPenColorSegment.savedSegment(for: viewModel.colorsFlow)
                self.selectedPage = self.viewModel.requiredPresetPage()
            }
    }
}

struct FTPresetSectionView: View {
    let section: Int
    @State var sectionColors: [FTPenColorModel] = []
    @State var isAlreadySelected: Bool = false
    @State var currentDraggedItem: FTPenColorModel?

    @ObservedObject var viewModel: FTPenShortcutViewModel

    var body: some View {
        VStack {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(sectionColors, id:\.self) { presetColor in
                    let index = self.viewModel.presetColors.firstIndex(of: presetColor) ?? 0
                    VStack {
                        FTPenPresetColorCircleView(hexColor: colorHex(presetColor), isSelected: presetColor.isSelected)
                            .hoverEffect()
                            .onTapGesture {
                                self.viewModel.presetEditIndex = index
                                self.handleTapGesture(for: presetColor)
                            }
                    }
                    .frame(width: 54.0, height: 40.0)
                    .onDrag {
                        self.viewModel.presetEditIndex = nil
                        self.viewModel.currentDraggedItem = presetColor
                        let reqProvider = NSItemProvider(object: presetColor)
                        return reqProvider
                    } preview: {
                        FTPenPresetColorCircleView(hexColor: colorHex(presetColor), isSelected: presetColor.isSelected)
                            .clipShape(Circle())
                            .contentShape(.dragPreview, Circle())
                    }
                    .onDrop(of: [.text],
                            delegate: FTColorDropInDelegate(item: presetColor, viewModel: viewModel))
                    .onChange(of: viewModel.presetColors) { colors in
                        if nil != self.viewModel.presetEditIndex {
                            self.findSectionColors()
                        } else {
                            withAnimation {
                                self.findSectionColors()
                            }
                        }
                    }
                }
                .padding(.zero)
            }
            .padding(.horizontal, FTSpacing.large)
            .padding(.top, FTSpacing.large)
            .padding(.bottom, FTSpacing.extraLarge)
        }
        .onAppear {
            self.findSectionColors()
        }
        .background(Color.appColor(.black4))
        .background(self.getNavlinkForSelectedItem())
        .cornerRadius(10.0)
        .padding(.horizontal, FTSpacing.small)
        .padding(.bottom, FTSpacing.large)
        .onDrop(of: [.text], delegate: FTColorDropOutDelegate(viewModel: self.viewModel))
    }

    private func colorHex(_ presetColor: FTPenColorModel) -> String {
        var curColor = presetColor.hex
        if let dragItem = self.viewModel.currentDraggedItem, dragItem == presetColor
             && self.viewModel.isDragging {
            curColor = ""
        }
        return curColor
    }

    private func findSectionColors() {
        let lowerIndex = section * 15
        let upperIndex = (section + 1) * 15

        if self.viewModel.presetColors.count >= upperIndex {
            self.sectionColors = Array(self.viewModel.presetColors[lowerIndex..<upperIndex])
        }
    }

    private func handleTapGesture(for color: FTPenColorModel) {
        if color.hex.isEmpty {
            isAlreadySelected = true
            self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: true)
        } else {
            if color.isSelected {
                isAlreadySelected = true
                self.viewModel.updateColorEditViewSizeIfNeeded(isPresetEdit: true)
            } else {
                isAlreadySelected = false
                self.viewModel.resetPresetColorSelection()
                color.isSelected = true
                self.viewModel.updateCurrentSelection(colorHex: color.hex)
            }
        }
    }

    private var gridItemLayout: [GridItem] {
        return Array.init(repeating: GridItem(.fixed(50.0), spacing: 0, alignment: .center), count: 5)
    }

    @ViewBuilder
    private func getNavlinkForSelectedItem() -> some View {
        NavigationLink(destination: FTPresetEditView()
            .environmentObject(viewModel),
                       isActive: $isAlreadySelected, label: {
            EmptyView()
        })
    }
}

struct FTPresetColorsView_Previews: PreviewProvider {
    static var previews: some View {
        FTPresetColorsView(selectedPage: 0)
            .environmentObject(FTPenShortcutViewModel(rackData: FTRackData(type: .pen, userActivity: nil)))
    }
}
