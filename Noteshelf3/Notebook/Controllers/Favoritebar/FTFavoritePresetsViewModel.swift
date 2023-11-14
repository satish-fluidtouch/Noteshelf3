//
//  FTFavoritePresetsViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 09/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

enum FTFavoriteRackSegment: String {
    case pen
    case highlighter

    var rackType: FTRackType {
        if self == .highlighter {
            return .highlighter
        }
        return .pen
    }
}

protocol FTFavoritePresetEditDelegate: NSObjectProtocol {
    func didTapEyeDropper()
}

class FTFavoritePresetsViewModel: ObservableObject {
    private let segment: FTFavoriteRackSegment
    @Published var presetColors: [FTPenColorModel] = []
    @Published var currentSelectedColor: String
    private var userActivity: NSUserActivity?
    var presetEditIndex: Int?

    @Published var isDragging = false
    @Published var currentDraggedItem: FTPenColorModel?
    private var rackData = FTRackData(type: .pen, userActivity: nil)

    private weak var presetEditDelegate: FTFavoritePresetEditDelegate?

    init(segment: FTFavoriteRackSegment, currentSelectedColor: String, userActivity: NSUserActivity?) {
        self.segment = segment
        self.currentSelectedColor = currentSelectedColor
        self.userActivity = userActivity
        if self.segment == .pen {
            self.rackData = FTRackData(type: .pen, userActivity: userActivity)
        } else {
            self.rackData = FTRackData(type: .highlighter, userActivity: userActivity)
        }
    }

    func createEditDelegate(_ del: FTFavoritePresetEditDelegate) {
        self.presetEditDelegate = del
    }

    func fetchCurrentColors() {
        self.presetColors = rackData.currentPresetColors.map({ color in
            let isSelected = (color == self.currentSelectedColor)
            return FTPenColorModel(hex: color, isSelected: isSelected)
        })

        let selectedColors = self.presetColors.filter { model in
            model.isSelected
        }

        if selectedColors.count > 1 {
            for (index, color) in selectedColors.enumerated().reversed()  {
                if index != 0 {
                    color.isSelected = false
                }
            }
        }
    }

    func updateCurrentColors() {
        self.rackData.currentPresetColors = self.presetColors.map({ model in
            model.hex
        })
        self.rackData.saveCurrentColors()
    }

    func addSelectedColorToPresets() {
        let curretSelectedColor = self.currentSelectedColor
        if let index = self.fetchFirstAvailableEmptySlot(), index < self.presetColors.count {
            self.updatePresetColor(hex: curretSelectedColor, index: index)
        } else {
            // All slots are filled
        }
    }

    func updatePresetColor(hex: String, index: Int) {
        if index < self.presetColors.count {
            let colorModel = FTPenColorModel(hex: hex, isSelected: true)
            self.presetColors[index] = colorModel
        }
    }

    func updateCurrentSelection(colorHex: String) {
        self.currentSelectedColor = colorHex
    }

    func resetPresetColorSelection() {
        for colorVm in self.presetColors where colorVm.isSelected == true {
            colorVm.isSelected = false
        }
    }

    func deleteColorAction() {
        if let index = self.presetColors.firstIndex(where: { model in
            model.hex == self.currentSelectedColor && model.isSelected
        }), index < self.presetColors.count {
            self.presetColors.remove(at: index)
            self.presetColors.append(FTPenColorModel(hex: "", isSelected: false))
        }
    }

    func didTapOnColorEyeDropper() {
        self.presetEditDelegate?.didTapEyeDropper()
    }
}

extension FTFavoritePresetsViewModel {
    func isEmptySlotAvailable() -> Bool {
        var status = false
        if self.presetColors.contains(where: { model in
            model.hex.isEmpty
        }) {
            status = true
        }
        return status
    }

    private func fetchFirstAvailableEmptySlot() -> Int? {
        var emptySlotIndex: Int?
        if isEmptySlotAvailable() {
            emptySlotIndex = self.presetColors.firstIndex(where: { model in
                model.hex.isEmpty
            })
        }
        return emptySlotIndex
    }

    func requiredPresetPage() -> Int {
        var reqPage = 0
        if let index = self.presetColors.firstIndex(where: { model in
            model.hex == self.currentSelectedColor
        }) {
            if index < 15 {
                reqPage = 0
            } else if index >= 15 && index < 30 {
                reqPage = 1
            } else if index >= 30 && index < 45 {
                reqPage = 2
            }
        }
        return reqPage
    }
}

class FTFavoriteColorDropInDelegate: DropDelegate {
    let item: FTPenColorModel
    let viewModel: FTFavoritePresetsViewModel

    init(item: FTPenColorModel, viewModel: FTFavoritePresetsViewModel) {
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

class FTFavoriteColorDropOutDelegate: DropDelegate {
    let viewModel: FTFavoritePresetsViewModel

    init(viewModel: FTFavoritePresetsViewModel) {
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

extension FTFavoritePresetsViewModel {
    func resetDragging() {
        self.isDragging = false
        self.currentDraggedItem = nil
    }
}
