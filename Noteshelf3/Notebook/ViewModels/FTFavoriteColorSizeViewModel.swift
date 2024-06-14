//
//  FTFavoriteColorSizeViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 16/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

enum FTFavoriteSizeMode: String {
    case sizeSelect
    case sizeEdit
}

protocol FTFavoriteSelectDelegate: AnyObject {
    func didChangeCurrentPenset(_ penset: FTPenSetProtocol, dismissSizeEditView: Bool)
}

protocol FTFavoriteColorEditDelegate: FTFavoriteSelectDelegate {
    func showEditColorScreen(using rack: FTRackData, position: FavoriteColorPosition)
    func showEditColorScreen(using rack: FTRackData, position: FavoriteColorPosition, rect: CGRect)
}

extension FTFavoriteColorEditDelegate {
    func showEditColorScreen(using rack: FTRackData, position: FavoriteColorPosition) {

    }
    func showEditColorScreen(using rack: FTRackData, position: FavoriteColorPosition, rect: CGRect) {

    }
}

extension Notification.Name {
    static let penTypeDisplayChange = NSNotification.Name("FTPenTypeDisplayChange")
}

class FTFavoriteColorViewModel: ObservableObject {
    @Published var favoriteColors: [FTPenColorModel] = []
    @Published private(set) var currentSelectedColor: String = blackColorHex

    private weak var delegate: FTFavoriteColorEditDelegate?

    private var rackData: FTRackData!
    private var currentPenset: FTPenSetProtocol!
    private(set) var colorEditPostion: FavoriteColorPosition?
    private weak var scene: UIWindowScene?
    var colorSourceOrigin = CGPoint.zero
    private var geometrySize: CGSize = .zero

    // MARK: Initialization
    init(rackData: FTRackData, delegate: FTFavoriteColorEditDelegate?, scene: UIWindowScene?) {
        self.rackData = rackData
        self.currentPenset = self.rackData.currentPenset
        self.delegate = delegate
        self.scene = scene

        NotificationCenter.default.addObserver(self, selector: #selector(handlePenTypeVariantChange(_:)), name: .penTypeDisplayChange, object: scene)
    }

    func updateGeometrySize(_ size: CGSize) {
        self.geometrySize = size
    }

    func rectForColor(at index: Int, startAngle: Angle) -> CGRect {
        let angle = Angle(degrees: startAngle.degrees + (Double(FTPenSliderConstants.spacingAngle) * Double(index)) - Double(FTPenSliderConstants.rotationAngle))
        let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometrySize.width / 2 + colorSourceOrigin.x
        let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometrySize.height / 2 + colorSourceOrigin.y
        return CGRect(x: x - 40/2, y: y - 40/2, width: 40, height: 40)
    }

    // This is to show different display size for pencil and other pen types
    @objc func handlePenTypeVariantChange(_ notification: Notification) {
        if let rackData = notification.userInfo?["FTRackData"] as? FTRackData {
            self.rackData = rackData
            self.fetchColorData()
        }
    }

    func getRackType() -> FTRackType {
        return self.rackData.type
    }

    func showEditColorScreen(at position: FavoriteColorPosition, mode: FTShortcutbarMode = .rectangle) {
        if mode == .arc {
            var startAngle = FTPenSliderConstants.startAngle
            if self.getRackType() == .shape {
                startAngle += .degrees(Double(FTPenSliderConstants.shapeTypeShortcutItems * FTPenSliderConstants.spacingAngle))
            }
            let rect = self.rectForColor(at: position.rawValue, startAngle: startAngle)
            self.delegate?.showEditColorScreen(using: self.rackData, position: position, rect: rect)
        } else {
            self.delegate?.showEditColorScreen(using: self.rackData, position: position)
        }
        self.colorEditPostion = position
    }

    func isItDefaultColor(at position: FavoriteColorPosition) -> Bool {
        var status = false
        if position == .custom {
            return status
        }
        let defaultFavs = self.rackData.defaultColors(for: self.currentPenset.type)
        let index = position.rawValue
        if index < defaultFavs.count {
            let currentColor = self.favoriteColors[index]
            if defaultFavs[index].color == currentColor.hex {
                status = true
            }
        }
        return status
    }

    func resetToDefaultColor(at position: FavoriteColorPosition) {
        if position == .custom {
            return
        }
        let defaultFavs = self.rackData.defaultColors(for: self.currentPenset.type)
        let index = position.rawValue
        if index < defaultFavs.count {
            let currentColor = self.favoriteColors[index]
            currentColor.hex = defaultFavs[index].color
            self.favoriteColors[index] = currentColor
            self.rackData.saveFavoriteColors(self.favoriteColors, type: self.currentPenset.type)
            if currentColor.isSelected {
                self.currentPenset.color = currentColor.hex
                self.delegate?.didChangeCurrentPenset(self.currentPenset, dismissSizeEditView: true)
            }
        }
    }
}

extension FTFavoriteColorViewModel {
    func fetchColorData() {
        self.favoriteColors.removeAll()
        self.currentPenset = self.rackData.currentPenset
        self.currentSelectedColor = self.currentPenset.color

        let favModels = self.rackData.getFavoriteColors(for: self.currentPenset.type)
         let newfav = favModels.map({
            return FTPenColorModel(hex: $0.color, isSelected: $0.isSelected)
        })
        self.favoriteColors.append(contentsOf: newfav)
    }

    func resetFavoriteColorSelection() {
        for colorVm in self.favoriteColors where colorVm.isSelected == true {
            colorVm.isSelected = false
        }
    }

    func updateCurrentSelection(colorHex: String) {
        self.currentSelectedColor = colorHex
        if self.currentPenset.color != colorHex {
            self.currentPenset.color = colorHex
            self.rackData.currentPenset = self.currentPenset
            self.rackData.saveFavoriteColors(self.favoriteColors, type: self.currentPenset.type)
            self.delegate?.didChangeCurrentPenset(self.currentPenset, dismissSizeEditView: true)
        }
    }

    func updateCurrentFavoriteColors() {
        self.rackData.saveFavoriteColors(self.favoriteColors, type: self.currentPenset.type)
    }

    func updateFavoriteColor(with color: String) {
        if let index = self.colorEditPostion?.rawValue {
            let colorModel = FTPenColorModel(hex: color, isSelected: true)
            self.favoriteColors[index] = colorModel
        }
    }
}

protocol FTFavoriteSizeEditDelegate: FTFavoriteSelectDelegate {
    func showSizeEditScreen(position: FavoriteSizePosition, viewModel: FTFavoriteSizeViewModel)
}

class FTFavoriteSizeViewModel: ObservableObject {
    @Published var favoritePenSizes: [FTPenSizeModel] = []
    @Published private var currentSelectedSize: CGFloat = 3.0

    private var rackData: FTRackData!
    private(set) var currentPenset: FTPenSetProtocol!
    var sizeEditPostion: FavoriteSizePosition?

    private weak var delegate: FTFavoriteSizeEditDelegate?
    private weak var scene: UIWindowScene?
    // MARK: Initialization
    init(rackData: FTRackData, delegate: FTFavoriteSizeEditDelegate?, scene: UIWindowScene?) {
        self.rackData = rackData
        self.currentPenset = self.rackData.currentPenset
        self.delegate = delegate
        self.scene = scene

        NotificationCenter.default.addObserver(self, selector: #selector(handlePenTypeVariantChange(_:)), name: .penTypeDisplayChange, object: scene)
    }

    // This is to show different display size for pencil and other pen types
    @objc func handlePenTypeVariantChange(_ notification: Notification) {
        if let rackData = notification.userInfo?["FTRackData"] as? FTRackData {
            self.rackData = rackData
            self.fetchSizesData()
        }
    }

    func getRackType() -> FTRackType {
        return self.rackData.type
    }

    func getCurrentPlacement() -> FTShortcutPlacement {
        return FTShortcutPlacement.getSavedPlacement(activity: rackData.userActivity)
    }
}

extension FTFavoriteSizeViewModel {
    func fetchSizesData() {
        self.currentPenset = self.rackData.currentPenset
        self.currentSelectedSize = self.currentPenset.preciseSize
        let favModels = self.rackData.getFavoriteSizes(for: self.currentPenset.type)
        self.favoritePenSizes = favModels.map({
            return FTPenSizeModel(size: $0.size, isSelected: $0.isSelected)
        })
    }

    func saveFavoriteSizes() {
        self.rackData.saveFavoriteSizes(self.favoritePenSizes, type: self.currentPenset.type)
    }

    func updateCurrentPenSize(size: CGFloat, sizeMode: FTFavoriteSizeMode) {
        let formattedSize = size.roundToDecimal(1)
        self.currentSelectedSize = formattedSize
        if formattedSize != self.currentPenset.preciseSize {
            if let penSize = FTPenSize(rawValue: formattedSize.rounded().toInt) {
                self.currentPenset.size = penSize
            }
            self.currentPenset.preciseSize = formattedSize
            self.rackData.currentPenset = self.currentPenset
            self.delegate?.didChangeCurrentPenset(self.currentPenset, dismissSizeEditView: sizeMode == .sizeSelect)
        }
    }

    func updateFavoriteSize(with size: CGFloat, at index: Int) {
        let formattedSize = size.roundToDecimal(1)
        if let index = self.sizeEditPostion?.rawValue, index < self.favoritePenSizes.count  {
            let sizeModel = FTPenSizeModel(size: formattedSize, isSelected: true)
            self.favoritePenSizes[index] = sizeModel
            self.rackData.saveFavoriteSizes(self.favoritePenSizes, type: self.currentPenset.type)
        }
    }

    func resetSizeSelection() {
        for sizeVm in self.favoritePenSizes where sizeVm.isSelected == true {
            sizeVm.isSelected = false
        }
    }

    func showSizeEditScreen(index: Int) {
        self.sizeEditPostion = FavoriteSizePosition.getPosition(index: index)
        if let pos = self.sizeEditPostion {
            self.delegate?.showSizeEditScreen(position: pos, viewModel: self)
        }
    }

    var sizeRange: ClosedRange<CGFloat> {
        let rackType = self.getRackType()
        return rackType.sizeRange
    }
}

extension FTPenType {
    func getIndicatorSize(using sizeValue: CGFloat) -> CGSize {
        var reqSize: CGSize = .zero
        if let penSize = FTPenSize(rawValue: Int(sizeValue)) {
            if self.isHighlighterPenType() {
                let width = penSize.maxDisplaySize(penType: self)
                var scale = penSize.scaleToApply(penType: self, preciseSize: sizeValue)
                scale = scale*0.8
                reqSize = CGSize(width: width*scale, height: width*scale)
            } else {
                var width = penSize.displayPixel(self)
                let fractionalPart = sizeValue.truncatingRemainder(dividingBy: 1)
                width += fractionalPart * 2.0
                reqSize = CGSize(width: width, height: width)
            }
        }
        return reqSize
    }
}

private extension Float {
    var roundedValue: Int {
        return Int(roundf(self))
    }
}
