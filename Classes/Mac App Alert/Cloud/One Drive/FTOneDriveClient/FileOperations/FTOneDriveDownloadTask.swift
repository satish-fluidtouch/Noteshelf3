//
//  FTOneDriveDownloadTask.swift
//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 16/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import UIKit
import MSAL
import MSGraphClientSDK

class FTOneDriveDownloadTask: NSObject {
    private weak var httpClient: MSHTTPClient?
    private var currentTask: MSURLSessionTask?
    private var progress: Progress = Progress()
    
    required init(withHttpClient httpClient: MSHTTPClient){
        super.init()
        self.httpClient = httpClient
    }
    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
    }

    @discardableResult func downloadFile(_ fileItem: FTOneDriveFileItem, onCompletion:((URL?, Error?) -> Void)?) -> Progress {
        var urlRequest: NSMutableURLRequest?
        if let url = URL(string: kGraphURI + ("/me/drive/items/\(fileItem.id!)/content")) {
            urlRequest = NSMutableURLRequest(url: url)
        }
        urlRequest?.httpMethod = "GET"
        if let urlRequest = urlRequest {
            let bgTask = startBackgroundTask();
            self.currentTask = MSURLSessionDownloadTask.init(request: urlRequest, client: self.httpClient) { (location, response, nserror) in
                if nserror == nil {
                    if let downloadUrl = location, let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = documentsPathURL.appendingPathComponent(fileItem.name!)
                        guard let fileData: Data = NSData(contentsOf:downloadUrl) as Data? else {
                            onCompletion?(nil, NSError.init(domain: "FTOneDriveDownloadError", code: 102, userInfo: nil))
                            return
                        }
                        try? fileData.write(to: fileURL)
                        onCompletion?(fileURL, nil)
                    }
                }
                endBackgroundTask(bgTask);
            }
            self.currentTask?.execute()
        }
        return self.progress
    }
}

