//
//  FTAnnotationEditInterface.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTEditAnnotationInterface
{
    func editController(delegate : FTAnnotationEditControllerDelegate?,
                        mode : FTAnnotationMode) -> FTAnnotationEditController?;
}

extension FTImageAnnotation : FTEditAnnotationInterface {
    func editController(delegate : FTAnnotationEditControllerDelegate?,
                        mode : FTAnnotationMode) -> FTAnnotationEditController? {
        return FTImageAnnotationViewController.init(withAnnotation: self,
                                                    delegate: delegate,
                                                    mode: mode)
    }
}


extension FTTextAnnotation : FTEditAnnotationInterface {
    func editController(delegate : FTAnnotationEditControllerDelegate?,
                        mode : FTAnnotationMode) -> FTAnnotationEditController? {
        return FTTextAnnotationViewController.init(withAnnotation: self,
                                                   delegate: delegate,
                                                   mode: mode)
    }
}

extension FTAudioAnnotation : FTEditAnnotationInterface {
    func editController(delegate : FTAnnotationEditControllerDelegate?,
                        mode : FTAnnotationMode) -> FTAnnotationEditController? {
        return FTAudioAnnotationViewController.init(withAnnotation: self,
                                                    delegate: delegate,
                                                    mode: mode)
    }
}

extension FTShapeAnnotation: FTEditAnnotationInterface {
    func editController(delegate : FTAnnotationEditControllerDelegate?,
                        mode : FTAnnotationMode) -> FTAnnotationEditController? {
        return FTShapeControllerBuilder.editController(withAnnotation: self, delegate: delegate, mode: mode)
    }
}
