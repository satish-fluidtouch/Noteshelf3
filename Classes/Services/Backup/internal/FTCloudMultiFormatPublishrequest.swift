//
//  FTCloudMultiFormatPublishrequest.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 22/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTCloudMultiFormatPublishRequest: FTCloudPublishRequest {
    var backupFormats: [RKExportFormat] = [kExportFormatNBK,kExportFormatPDF];
    private var currentFileRequest: FTCloudFilePublishRequest?;
        
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
        self.delegate?.publishRequest(self, uploadProgress: progress, backUpProgressType: type);
    }
}
