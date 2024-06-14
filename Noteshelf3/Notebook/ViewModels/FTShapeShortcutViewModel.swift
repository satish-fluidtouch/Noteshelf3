//
//  FTShapeShortcutViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 05/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

protocol FTShapeShortcutEditDelegate: AnyObject {
    func showShapeEditScreen(position: FavoriteShapePosition)
    func showShapeEditScreen(position: FavoriteShapePosition, rect: CGRect)
    func didSelectFavoriteShape(_ shape: FTShapeType)
}

extension FTShapeShortcutEditDelegate {
    func showShapeEditScreen(position: FavoriteShapePosition) {
        debugLog(#function)
    }
    func showShapeEditScreen(position: FavoriteShapePosition, rect: CGRect) {
        debugLog(#function)
    }
}

class FTFavoriteShapeViewModel: ObservableObject {
    @Published private(set) var currentFavoriteShape = FTShapeType.freeForm
    @Published var favoriteShapes: [FTPenShapeModel] = []
    @Published private(set) var contentTransformation = Angle.zero

    private var rackData: FTRackData!
    private var currentPenset: FTPenSetProtocol!
    private var shapeEditPosition: FavoriteShapePosition?

    private weak var delegate: FTShapeShortcutEditDelegate?
    private var observer: NSKeyValueObservation?
    var shapeSourceOrigin = CGPoint.zero
    private var geometrySize: CGSize = .zero

    // MARK: Initialization
    init(rackData: FTRackData, delegate: FTShapeShortcutEditDelegate?) {
        self.rackData = rackData
        self.delegate = delegate
        observer = UserDefaults.standard.observe(\.shapeTypeRawValue, options: [.new]) { [weak self] (_, _) in
            self?.fetchShapesData()
        }
        self.updateContentTransfromIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(handleViewMovementEnded), name: NSNotification.Name("ViewMovementEnded"), object: nil)
    }

    func getRackType() -> FTRackType {
        return self.rackData.type
    }

    func updateCurrentFavoriteShape(_ shape: FTShapeType) {
        self.currentFavoriteShape = shape
    }

    func updateGeometrySize(_ size: CGSize) {
        self.geometrySize = size
    }

    func handleFavoriteShapeSelection(_ shape: FTShapeType, index: FavoriteShapePosition) {
        self.shapeEditPosition = index
        self.delegate?.didSelectFavoriteShape(shape)
    }

    private func updateContentTransfromIfNeeded() {
        let placement = FTShortcutPlacement.getSavedPlacement(activity: rackData.userActivity)
        self.contentTransformation = .zero
        if placement.isLeftPlacement() || placement.isRightPlacement() {
            self.contentTransformation = .degrees(-90)
        } 
    }

    @objc private func handleViewMovementEnded() {
        self.updateContentTransfromIfNeeded()
    }

    func editFavoriteShape(with shape: FTShapeType) {
        if let index = self.shapeEditPosition?.rawValue, index < self.favoriteShapes.count {
            let shapeModel = FTPenShapeModel(shape: shape, isSelected: true)
            self.favoriteShapes[index] = shapeModel
        }
    }
}

extension FTFavoriteShapeViewModel {
    func fetchShapesData() {
        let rackType = self.getRackType()
        self.currentFavoriteShape = FTShapeType.savedShapeType()

        self.favoriteShapes = rackType.favoriteShapeTypes.map({ shape in
            let isSelected = (shape == self.currentFavoriteShape)
            return FTPenShapeModel(shape: shape, isSelected: isSelected)
        })

        // TODO: (need refactor to to have better fix)
        // Temporary fix for restriction of same shape selection
        for (index, shape) in self.favoriteShapes.enumerated().reversed() {
            let selectedShapes = self.favoriteShapes.filter { model in
                model.isSelected
            }
            if selectedShapes.count > 1 {
                if let pos = self.shapeEditPosition {
                    // when we have edit position available, other position can be de-selected
                    if pos.rawValue != index {
                        shape.isSelected = false
                    }
                } else { // rare case user
                    // Existing case - when we have already duplicate shapes selected in prod, only first selected index we are respecting
                    if let reqIndex = selectedShapes.firstIndex(where: { $0.isSelected }), reqIndex != index {
                        shape.isSelected = false
                    }
                }
            } else if selectedShapes.count == 1 {
                self.shapeEditPosition = FavoriteShapePosition(rawValue: index)
                break
            }
        }
    }

    func isSelectedShape(shape: FTShapeType) -> Bool {
        return self.currentFavoriteShape == shape
    }

    func resetShapeSelection() {
        for shapeVm in self.favoriteShapes where shapeVm.isSelected == true {
            shapeVm.isSelected = false
        }
    }
    
    func saveFavoriteShapes() {
        let rackType = self.getRackType()
        let shapeTypes = self.favoriteShapes.map { model in
            model.shape
        }
        rackType.saveFavoriteShapeTypes(shapes: shapeTypes)
    }

    func rectForColor(at index: Int, startAngle: Angle) -> CGRect {
        let angle = Angle(degrees: startAngle.degrees + (Double(FTPenSliderConstants.spacingAngle) * Double(index)) - Double(FTPenSliderConstants.rotationAngle))
        let x = FTPenSliderConstants.sliderRadius * cos(angle.radians) + geometrySize.width / 2 + shapeSourceOrigin.x
        let y = FTPenSliderConstants.sliderRadius * sin(angle.radians) + geometrySize.height / 2 + shapeSourceOrigin.y
        return CGRect(x: x - 40/2, y: y - 40/2, width: 40, height: 40)
    }

    func showShapeEditScreen(index: Int, mode: FTShortcutbarMode = .rectangle) {
       let position = FavoriteShapePosition.getPosition(index: index)
        if mode == .rectangle {
            self.delegate?.showShapeEditScreen(position: position)
        } else {
            let startAngle = FTPenSliderConstants.startAngle
            let rect = self.rectForColor(at: index, startAngle: startAngle)
            self.delegate?.showShapeEditScreen(position: position, rect: rect)
        }
        self.shapeEditPosition = position
    }
}

