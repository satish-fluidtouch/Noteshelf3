//
//  FTRecognitionTask.swift
//  Noteshelf
//
//  Created by Naidu on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTVisionRecognitionTask: NSObject, FTBackgroundTask {
    weak var currentDocument: FTNoteshelfDocument?
    var languageCode: String!
    var pageUUID: String = ""
    var imageToProcess: UIImage!

    var viewSize:CGSize!
    var onCompletion: ((FTVisionRecognitionResult?,NSError?) -> (Void))?
    var onStatusChange: ((FTBackgroundTaskStatus) -> (Void))?
}
