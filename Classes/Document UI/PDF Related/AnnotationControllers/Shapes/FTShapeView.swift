//
//  FTShapeView.swift
//  Noteshelf
//
//  Created by Sameer on 30/05/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTRenderKit
class FTShapeView: FTMetalView {
    weak var dragView: FTSpecialKnobView?
    weak var shapeEditView: UIView?
    weak var parentVc: FTShapeAnnotationController?
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if let shapeEditView = shapeEditView {
            let newPoint = self.convert(point, to: shapeEditView)
            if let dragView = dragView, dragView.frame.contains(newPoint) {
                return shapeEditView
            }
        }
        if let vc = parentVc {
            let contentOffset = (vc.delegate?.visibleRect().origin ?? .zero)
            let convertedPoint = CGPointTranslate(point, contentOffset.x, contentOffset.y)
            if  vc.isPointInside(convertedPoint, fromView: self) {
                return view
            }
        }
        return nil
    }
}
