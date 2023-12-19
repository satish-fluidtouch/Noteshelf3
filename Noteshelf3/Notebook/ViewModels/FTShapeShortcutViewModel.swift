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

    func handleFavoriteShapeSelection(_ shape: FTShapeType) {
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

        let selectedShapes = self.favoriteShapes.filter { model in
            model.isSelected
        }

        if selectedShapes.count > 1 {
            for (index, shape) in selectedShapes.enumerated().reversed()  {
                if index != 0 {
                    shape.isSelected = false
                }
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

