//
//  FTOneDriveMoveTask.swift
//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 17/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import UIKit
import MSAL
import MSGraphClientSDK
import MSGraphMSALAuthProvider

class FTOneDriveMoveTask: NSObject {
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
    
    func moveItem(withID itemID: String, toRelativePath: String, fileName:String, onCompletion: ((FTOneDriveFileItem?, Error?) -> Void)?){
        var urlRequest: NSMutableURLRequest?
        if let url = URL(string: kGraphURI + ("/me/drive/items/\(itemID)")) {
            urlRequest = NSMutableURLRequest(url: url)
        }
        urlRequest?.httpMethod = "PATCH"
        urlRequest?.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let remotePath = ("/drive/root:/" + toRelativePath)
        let dict: [String : Any] = ["id": itemID, "name": fileName, "parentReference": ["path": remotePath]]
        guard let jsonData: Data = try? JSONSerialization.data(withJSONObject:dict, options:[]) else {
            onCompletion?(nil, FTOneDriveError.urlRequestError)
            return
        }
        urlRequest?.httpBody = jsonData
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
                    if let filesData = data{
                        let jsonDecoder = JSONDecoder()
                        let responseModel = try? jsonDecoder.decode(FTOneDriveFileItem.self, from: filesData)
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

