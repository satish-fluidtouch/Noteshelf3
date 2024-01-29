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
    func didSelectFavoriteShape(_ shape: FTShapeType)
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

    func handleFavoriteShapeSelection(_ shape: FTShapeType, index: FavoriteShapePosition) {
        self.shapeEditPosition = index
        self.delegate?.didSelectFavoriteShape(shape)
    }

    private func updateContentTransfromIfNeeded() {
        let placement = FTShortcutPlacement.getSavedPlacement()
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

    func showShapeEditScreen(index: Int) {
       let position = FavoriteShapePosition.getPosition(index: index)
        self.delegate?.showShapeEditScreen(position: position)
        self.shapeEditPosition = position
    }
}

