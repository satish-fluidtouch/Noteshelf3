//
//  FTOneDriveInfoTask.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 18/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MSAL
import MSGraphClientSDK

class FTOneDriveInfoTask: NSObject {
    private weak var httpClient: MSHTTPClient?
    private var currentTask: MSURLSessionTask?
    
    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
    }
    
    required init(withHttpClient httpClient: MSHTTPClient){
        super.init()
        self.httpClient = httpClient
    }
    
    func getDriveInfo(_ onCompletion: ((FTOneDriveInfo?, Error?) -> Void)?){
        var urlRequest: NSMutableURLRequest?
        if let url = URL(string: kGraphURI + ("/me/drive")) {
            urlRequest = NSMutableURLRequest(url: url)
        }
        urlRequest?.httpMethod = "GET"
        
        if let urlRequest = urlRequest {
            let bgTask = startBackgroundTask();
            self.currentTask = self.httpClient?.dataTask(with: urlRequest, completionHandler: { data, response, nserror in
                if nserror != nil {
                    onCompletion?(nil, nserror)
                }
                else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                    onCompletion?(nil, FTOneDriveError.uploadError(with: statusCode))
                }
                else {
                    if let filesData = data {
                        #if DEBUG
                            let jsonDict = try? JSONSerialization.jsonObject(with: filesData, options: [])
                            debugPrint(jsonDict)
                        #endif
                        let jsonDecoder = JSONDecoder()
                        let responseModel = try? jsonDecoder.decode(FTOneDriveInfo.self, from: filesData)
                        onCompletion?(responseModel, nil)
                    }
                    else{
                        onCompletion?(nil, FTOneDriveError.defaultError)
                    }
                }
                endBackgroundTask(bgTask);
            })
        }
        self.currentTask?.execute()
    }
}
