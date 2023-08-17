//
//  FTShapeCollectionViewCell.swift
//  Noteshelf
//
//  Created by srinivas on 06/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShapeCollectionViewCell: UICollectionViewCell {
    var penRack: FTRackData?
    
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var shapeImageView: UIImageView!
    
    func configure(with shape: FTShapeType) {
        if let image = UIImage(named: shape.getShapeName()) {
            shapeImageView.image = image
            shapeImageView.tintColor = .label
        }
        let selectedShape = FTShapeType.savedShapeType()
        if shape == selectedShape {
            select()
        } else {
            deSelect()
        }
    }
    
    func select() {
        self.bgView.backgroundColor = UIColor.appColor(.white100)
        self.bgView.addShadow(cornerRadius: self.bgView.frame.height/2.0, color: UIColor.label.withAlphaComponent(0.12), offset: CGSize(width: 0.0, height: 4.0), opacity: 1.0, shadowRadius: 8.0)
    }
    
    func deSelect() {
        self.bgView.backgroundColor = .clear
        self.bgView.removeShadow()
    }
}
