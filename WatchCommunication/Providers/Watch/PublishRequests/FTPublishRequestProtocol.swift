//
//  FTPublishRequestProtocol.swift
//  Noteshelf
//
//  Created by Simhachalam on 20/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTPublishRequestDelegate: NSObjectProtocol{
    func didFinishProcessingPublishRequest(_ request:FTPublishRequestProtocol, withError error:Error?)
}

protocol FTPublishRequestProtocol: FTRequestProtocol {
    var delegate:FTPublishRequestDelegate?{ get set }
    
    var audioUUID : String!{ get set }
    var recording: FTWatchRecording?{ get set }
    
    init(withAudioUUID audioUUID : String, andRecording recording:FTWatchRecording?)
    
    func startProcessingRequest()
}
