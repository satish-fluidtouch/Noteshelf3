//
//  FTCloudMultiFormatPublishrequest.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 22/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTCloudMultiFormatPublishRequest: FTCloudPublishRequest {
    var backupFormats: [RKExportFormat];
    private var currentFileRequest: FTCloudFilePublishRequest?;
        
    private var totalProgress: CGFloat = 1;
    private var currentProgress: CGFloat = 0;
    
    override init(backupEntry cloudBackupObject: FTCloudBackup, delegate: FTCloudPublishRequestDelegate?, sourceFile: URL) {
        backupFormats = FTUserDefaults.backupFormat.exportFormats;
        super.init(backupEntry: cloudBackupObject, delegate: delegate,sourceFile: sourceFile);
        self.totalProgress = backupFormats.count.toCGFloat();
    }
    
    override func startRequest() {
        guard !backupFormats.isEmpty else {
            self.delegate?.didComplete(publishRequest: self, error: nil);
            return;
        }
        let backupType = backupFormats.removeFirst();
        let request = self.filePublishRequest(format: backupType);
        request.startRequest();
    }
    
    func filePublishRequest(format: RKExportFormat) -> FTCloudFilePublishRequest {
        fatalError("\(self.className) should override filePublishRequest(format:) ")
    }
    
    override func canelRequestIfPossible() {
        self.backupFormats.removeAll();
        self.currentFileRequest?.canelRequestIfPossible();
    }
}

extension FTCloudMultiFormatPublishRequest: FTCloudPublishRequestDelegate {
    @objc func willBeginPublishRequest(_ request: FTCloudPublishRequest) {
        
    }
    
    @objc func didComplete(publishRequest request: FTCloudPublishRequest,
                           error: Error?) {
        if let cloudError = error {
            self.delegate?.didComplete(publishRequest: self, error: cloudError);
        }
        else {
            self.startRequest();
        }
    }
    
    @objc func didComplete(publishRequest request: FTCloudPublishRequest,
                           ignoreEntry: FTBackupIgnoreEntry) {
        self.delegate?.didComplete(publishRequest: request, ignoreEntry: ignoreEntry);
    }
    
    @objc func publishRequest(_ request: FTCloudPublishRequest,
                              uploadProgress progress: CGFloat,
                              backUpProgressType type: FTBackUpProgressType) {
        currentProgress += (progress/totalProgress)
        debugLog("Progress: backup: \(currentProgress)");
        self.delegate?.publishRequest(self, uploadProgress: currentProgress, backUpProgressType: type);
    }
}
