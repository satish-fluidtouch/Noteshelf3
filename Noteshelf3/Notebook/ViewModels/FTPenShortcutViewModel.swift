//
//  FTPenShortcutViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 14/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

let bgMaterial: Material = Material.regularMaterial

protocol FTColorSizeSelectDelegate: AnyObject {
    func didSelectColor(_ color: String)
    func didSelectSize(_ size: CGFloat)
}

class FTPenShortcutViewModel: ObservableObject {
    private var rackData: FTRackData!

    // MARK: publishers
    @Published var isDragging = false
    @Published var currentDraggedItem: FTPenColorModel?
    @Published var presetColors: [FTPenColorModel] = []
    @Published var colorSelectSegment: FTPenColorSegment = .presets
    @Published private(set) var currentSelectedColor: String = blackColorHex

    private weak var editDelegate: FTPenColorEditDelegate?
    private weak var colorSizeSelectDelegate: FTColorSizeSelectDelegate?
    private(set) var currentPenset: FTPenSetProtocol!
    var presetEditIndex: Int?
    var colorsFlow: FTColorsFlowType = .penType(.pen)

    // MARK: Initialization
    init(rackData: FTRackData) {
        self.rackData = rackData
        self.currentPenset = rackData.currentPenset
        self.currentSelectedColor = self.currentPenset.color
    }

    func createEditDelegate(editDelegate: FTPenColorEditDelegate) {
        self.editDelegate = editDelegate
    }
}

// MARK: Handling preset colors
extension FTPenShortcutViewModel {
    func fetchCurrentColors() {
        self.currentSelectedColor = self.currentPenset.color
        self.presetColors = self.rackData.currentPresetColors.map({ color in
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

    func updatePresetColor(hex: String, index: Int) {
        if index < self.presetColors.count {
            let colorModel = FTPenColorModel(hex: hex, isSelected: true)
            self.presetColors[index] = colorModel
        }
    }

    func resetPresetColorSelection() {
        for colorVm in self.presetColors where colorVm.isSelected == true {
            colorVm.isSelected = false
        }
    }

    func updateCurrentSelection(colorHex: String) {
        if let currentPresetIndex = self.presetEditIndex
            , currentPresetIndex < self.presetColors.count
            , self.presetColors[currentPresetIndex].hex != colorHex {
            self.updatePresetColor(hex: colorHex, index: currentPresetIndex);
            self.updateCurrentColors();
        }
        if self.currentSelectedColor != colorHex {
            self.currentSelectedColor = colorHex
            self.currentPenset.color = colorHex
            self.rackData.currentPenset = self.currentPenset
            self.editDelegate?.didChangeCurrentPenset(self.currentPenset)
        }
    }
}

// MARK: Handling Edit actions(long press)
extension FTPenShortcutViewModel {
    func restoreAction() {
        self.presetColors = self.rackData.defaultPresetColors.map({ colorHex in
            let isSelected = (colorHex == self.currentSelectedColor)
            return FTPenColorModel(hex: colorHex, isSelected: isSelected)
        })
        self.updateCurrentColors()
    }

    func deleteColorAction() {
        if let index = self.presetColors.firstIndex(where: { model in
            model.hex == self.currentSelectedColor && model.isSelected
        }), index < self.presetColors.count {
            self.presetColors.remove(at: index)
            self.presetColors.append(FTPenColorModel(hex: "", isSelected: false))
            self.editDelegate?.didDeletePresetColor()
        }
    }

    func updateColorEditViewSizeIfNeeded(isPresetEdit: Bool) {
        self.editDelegate?.updateViewSizeIfNeeded(isPresetEdit: isPresetEdit)
    }

    func addSelectedColorToPresets() {
        let curretSelectedColor = self.currentSelectedColor
        if let index = self.fetchFirstAvailableEmptySlot(), index < self.presetColors.count {
            self.updatePresetColor(hex: curretSelectedColor, index: index)
            self.editDelegate?.didAddPresetColor()
        } else {
            // All slots are filled
        }
    }
    
    func didTapOnColorEyeDropper() {
        self.editDelegate?.didTapOnColorEyeDropper();
    }
}

// MARK: Helper functions
extension FTPenShortcutViewModel {
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
