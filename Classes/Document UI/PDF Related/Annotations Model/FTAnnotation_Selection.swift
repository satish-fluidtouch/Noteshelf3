//
//  FTAnnotation_Selection.swift
//  Noteshelf
//
//  Created by Akshay on 24/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//


extension FTAnnotation {
    func allowsSingleTapSelection(atPoint:CGPoint, mode:RKDeskMode) -> Bool {
        if let annotation = self as? FTAnnotationSingleTapSelector {
            return annotation.allowsSingleTapSelection(atPoint: atPoint)
        }
        return false
    }
}

extension FTStroke {
    override func allowsSingleTapSelection(atPoint: CGPoint, mode: RKDeskMode) -> Bool {
        guard nil != self.groupId, self.intersectsPath(atPoint.pathWith1Px, withScale: 1.0, withOffset: CGPoint.zero) else {
            return false
        }
        return true
    }
}

extension FTImageAnnotation {
    override func allowsSingleTapSelection(atPoint: CGPoint, mode: RKDeskMode) -> Bool {
        if mode == .deskModeText {
            return false
        }
        return super.allowsSingleTapSelection(atPoint: atPoint, mode: mode)
    }
}

extension FTShapeAnnotation {
    override func allowsSingleTapSelection(atPoint: CGPoint, mode: RKDeskMode) -> Bool {
        if mode == .deskModeText {
            return false
        }
        return self.allowsSingleTapSelection(atPoint: atPoint)
    }
}
