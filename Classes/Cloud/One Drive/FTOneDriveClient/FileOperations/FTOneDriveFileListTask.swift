//
//  FTOneDriveFileListTask.swift
//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 16/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import UIKit
import MSAL
import MSGraphClientSDK

class FTOneDriveFileListTask: NSObject {
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
    
    func getFileList(atPath: String?, onCompletion: (([FTOneDriveFileItem], Error?) -> Void)?){
        var urlRequest: NSMutableURLRequest?
        if let url = URL(string: kGraphURI + ("/me/drive/root/children")) {
            urlRequest = NSMutableURLRequest(url: url)
        }
        urlRequest?.httpMethod = "GET"

        if let urlRequest = urlRequest {
            let bgTask = startBackgroundTask();
            self.currentTask = self.httpClient?.dataTask(with: urlRequest, completionHandler: { data, response, nserror in
                if let filesData = data, nserror == nil {
                    let jsonDecoder = JSONDecoder()
                    let responseModel = try? jsonDecoder.decode(FTOneDriveFiles_Base.self, from: filesData)
                    if let fileList = responseModel?.value {
                        DispatchQueue.main.async {
                            onCompletion?(fileList, nil)
                        }
                    }
                }
                endBackgroundTask(bgTask);
            })
        }
        self.currentTask?.execute()
    }
}
