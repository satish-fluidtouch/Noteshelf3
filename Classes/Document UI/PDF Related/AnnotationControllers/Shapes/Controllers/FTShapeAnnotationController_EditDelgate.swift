//
//  FTShapeAnnotationController_EditDelgate.swift
//  Noteshelf
//
//  Created by Sameer on 17/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension FTShapeAnnotationController: FTShapeControllerEditDelegate {
    func didUpdateShape(with sides: CGFloat) {
        self.displayLink?.isPaused = false
        shapeAnnotation.updateShapeSides(sides: sides)
        shapeAnnotation.setShapeControlPoints(drawingPoints())
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(generateStrokeSegments),
                                               object: nil)
        self.perform(#selector(generateStrokeSegments), with: nil, afterDelay: 0.1);
    }
    
    func referenceView() -> UIView {
        return self.resizableView ?? self.view
    }
    
    func contentScale() -> CGFloat {
        return self.scale
    }
    
    func snappedAngle() -> CGFloat {
        let sides = shapeAnnotation.shapeData.numberOfSides
        return CGFloat((sides - 3) * 40)
    }
}
