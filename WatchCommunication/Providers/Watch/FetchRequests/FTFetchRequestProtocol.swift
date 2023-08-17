//
//  FTFetchRequestProtocol.swift
//  Noteshelf
//
//  Created by Simhachalam on 20/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTRequestStatus : Int
{
    case executing
    case waiting
    case completed
}

protocol FTRequestProtocol : NSObjectProtocol {
    var requestUUID : String { get set }
    var callBack : (([String : Any]?,FTWatchRecording?,NSError?) -> ())? {get set};
    var status : FTRequestStatus {get set};
    var platformIdentifier : String { get }
    var publishQueue : DispatchQueue { get};

    func writeLogString(_ newlog : String);
    var requestType : String { get }
}

extension FTRequestProtocol {
    
    var publishQueue : DispatchQueue {
        return FTWatchCommunicationManager.shared.watchDispatchQueue;
    }
    
    var platformIdentifier : String {
        return FTWatchCommunicationManager.shared.platformIdentifier;
    }
    
    func writeLogString(_ newlog : String)
    {
        FTWatchCommunicationManager.shared.writeLogString(newlog);
    }
}

protocol FTFetchRequestDelegate: NSObjectProtocol{
    func didFinishProcessingFetchRequest(_ request:FTFetchRequestProtocol, withError error:Error?)
}

protocol FTFetchRequestProtocol: FTRequestProtocol {
    var delegate: FTFetchRequestDelegate?{ get set }
    var audioUUID : String!{ get set }
    var recording: FTWatchRecording?{ get set }
    
    init(withAudioUUID audioUUID:String, andRecording recording:FTWatchRecording?)

    func startProcessingRequest()
}
