//
//  FTRecognitionProtocols.swift
//  Noteshelf
//
//  Created by Naidu on 03/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

enum FTBackgroundTaskStatus: Int{
    case none
    case waiting
    case inProgress
    case finished
}

protocol FTBackgroundTask {
    var onStatusChange: ((FTBackgroundTaskStatus)->(Void))? {get set}
}
protocol FTBackgroundTaskProcessor {
    var canAcceptNewTask: Bool {get set}
    func startTask(_ task: FTBackgroundTask, onCompletion: (()->(Void))?)
}

