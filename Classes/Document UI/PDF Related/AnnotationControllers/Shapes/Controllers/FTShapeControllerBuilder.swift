//
//  FTShapeControllerBuilder.swift
//  Noteshelf
//
//  Created by Sameer on 17/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
class FTShapeControllerBuilder: UIViewController {
    static func editController(withAnnotation annotation: FTAnnotation, delegate: FTAnnotationEditControllerDelegate?, mode: FTAnnotationMode) -> FTAnnotationEditController? {
        var controller : FTAnnotationEditController?
        if let ann = annotation as? FTShapeAnnotation {
            if ann.shape?.isLineType?() ?? false {
                controller = FTShapeArrowAnnotationController(withAnnotation: annotation, delegate: delegate, mode: mode)
            } else {
                controller = FTShapeAnnotationController(withAnnotation: annotation, delegate: delegate, mode: mode)
                if let parentVc = controller as? FTShapeAnnotationController, parentVc.shapeAnnotation.shape?.type() == .pentagon {
                    let specialControlPointVC = FTShapeEditController()
                    specialControlPointVC.delegate = parentVc
                    parentVc.shapeEditVC = specialControlPointVC
                    parentVc.addChild(specialControlPointVC)
                    parentVc.view.addSubview(specialControlPointVC.view)
                }
            }
        }
        return controller
    }
}
