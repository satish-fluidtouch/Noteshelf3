//
//  FTRecognitionTask.swift
//  Noteshelf
//
//  Created by Naidu on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTRecognitionContext {
    case regular
    case convertToText
}

class FTRecognitionTask: NSObject, FTBackgroundTask {
    weak var currentDocument: FTNoteshelfDocument?
    var pageUUID: String = ""

    private(set) var languageCode: String
    private(set) var pageAnnotations:[FTAnnotation]
    private(set) var viewSize:CGSize
    
    var onCompletion: ((FTRecognitionResult?,NSError?) -> (Void))?
    var onStatusChange: ((FTBackgroundTaskStatus) -> (Void))?
    
    required init(language: String,annotations: [FTAnnotation], canvasSize: CGSize) {
        languageCode = language;
        pageAnnotations = annotations;
        viewSize = canvasSize;
    }
}
