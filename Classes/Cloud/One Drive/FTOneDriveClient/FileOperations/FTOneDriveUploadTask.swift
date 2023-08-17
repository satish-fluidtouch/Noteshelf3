//
//  FTOneDriveUploadTask.swift
//  OneDriveDemo
//
//  Created by Simhachalam Naidu on 16/09/19.
//  Copyright © 2019 Simhachalam Naidu. All rights reserved.
//

import UIKit
import MSAL
import MSGraphClientSDK

class FTOneDriveUploadTask: NSObject {
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
    
    @objc @discardableResult func uploadFile(atLocation fileURL: URL,
                                             toParentPath: String,
                                             onCompletion:((FTOneDriveFileItem?, Error?) -> Void)?) -> Progress
    {
        let bgTask = startBackgroundTask();
        guard let fileData: Data = NSData(contentsOf:fileURL) as Data?,
              let fileName = fileURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
              let httpClientObject = self.httpClient else {
                onCompletion?(nil, FTOneDriveError.authenticationError)
              return self.progress
        }
        //let size = fileURL.sizeInMB();
        let dataLength = fileData.count
        var chunkSize = 5 * 1024 * 1024
        if(dataLength < chunkSize) {
            chunkSize = dataLength - (dataLength % 320) // The chunk size must be in multiples of 320
        }
        let parentPath = toParentPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed);
        MSGraphOneDriveLargeFileUploadTask.createOneDriveLargeFileUploadTask(with: httpClientObject,
                                                                             fileData: fileData,
                                                                             fileName: fileName,
                                                                             filePath: parentPath,
                                                                             andChunkSize: chunkSize,
                                                                             withCompletion:
            { fileUploadTask, data, response, nserror in
                if nserror != nil {
                    #if DEBUG
                    debugPrint("UPLOAD:There was some error while creating upload session \(String(describing: nserror))")
                    #endif
                    onCompletion?(nil, nserror)
                    endBackgroundTask(bgTask);
                }
                else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                    onCompletion?(nil, FTOneDriveError.uploadError(with: statusCode))
                    endBackgroundTask(bgTask);
                }
                else {
                    if fileUploadTask == nil {
                        DispatchQueue.main.async {
                            #if DEBUG
                            debugPrint("UPLOAD:nserror \(String(describing: nserror))");
                            #endif
                            onCompletion?(nil, FTOneDriveError.urlRequestError)
                        }
                        endBackgroundTask(bgTask);
                    }
                    else {
                        fileUploadTask?.upload(completion: { (data, _, nserror) in
                            if let filesData = data as? Data {
                                let jsonDecoder = JSONDecoder()
                                let responseModel = try? jsonDecoder.decode(FTOneDriveFileItem.self, from: filesData)
                                onCompletion?(responseModel, nil)
                            }
                            else{
                                onCompletion?(nil, FTOneDriveError.ftDomainError(nserror))
                            }
                            endBackgroundTask(bgTask);
                        })
                    }
                }
        })
        
        return self.progress
    }

    func cancel(){
//        Find a way to cancel
//        self.currentTask?.cancel()
    }
}

#if !DEBUG && !ADHOC && !TARGET_OS_SIMULATOR
func verifyOneDriveSDKLargeFileUploadNilCheck()
{
    /*
     MAKE SURE IN FILE MSLargeFileUploadTask.m,
     
     in the func
     uploadNextSegmentWithCompletion:(HTTPRequestCompletionHandler)completionHandler
     make sure the data is checked  for not nil before  NSJSONSerialization
     
     as this is causing crash due to nil data in some rare scenario where response statusCode is not accepted and data is nil with error not nil. Since error condition is not handled we are forced to make changes directly to this file.
     
     how code should look like:
     
     MSURLSessionDataTask *uploadTask = [self.httpClient dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
         if([(NSHTTPURLResponse *)response statusCode] == MSExpectedResponseCodesAccepted)
         {
             [self setNextRange];
             [self uploadNextSegmentWithCompletion:completionHandler];
         } else if(nil != data) { //added condition
             NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
             if(dataDict[@"id"])
             {
                 completionHandler(data, response, error);
             }else
             {
                 [self uploadNextSegmentWithCompletion:completionHandler];
             }
         }
         else { //added condition
             completionHandler(data, response, error);
         }
     }];
     [uploadTask execute];

     */
    callingANonExistingFunctionForBreakingTheCompilation();
}
#endif
