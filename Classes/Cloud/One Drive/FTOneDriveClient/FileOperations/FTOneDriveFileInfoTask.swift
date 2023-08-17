//
//  FTOneDriveFileInfoTask.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 22/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MSAL
import MSGraphClientSDK
import MSGraphMSALAuthProvider

class FTOneDriveFileInfoTask: NSObject {
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
    func getFileInfo(for fileID: String, onCompletion: ((FTOneDriveFileItem?, Error?) -> Void)?){
        var urlRequest: NSMutableURLRequest?
        if let url = URL(string: kGraphURI + ("/me/drive/items/\(fileID)?select=name,id,parentReference")) {
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
                        let jsonDecoder = JSONDecoder()
                        let responseModel = try? jsonDecoder.decode(FTOneDriveFileItem.self, from: filesData)
                        onCompletion?(responseModel, nil)
                    }
                    else {
                        onCompletion?(nil, nserror)
                    }
                }
                endBackgroundTask(bgTask);
            })
        }
        self.currentTask?.execute()
    }
    
}
