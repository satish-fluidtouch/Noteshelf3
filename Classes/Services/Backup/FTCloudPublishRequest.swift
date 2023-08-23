//
//  FTCloudPublishRequest.swift
//  FTAutoBackupSwift
//
//  Created by Naidu on 26/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

@objcMembers class FTCloudPublishRequest: NSObject {
    static let backup_Folder_Name = "Noteshelf3 Backup";
    private(set) weak var delegate: FTCloudPublishRequestDelegate?
    private(set) var refObject: FTCloudBackup
    private(set) var sourceFileURL: URL
    
    func startRequest() {
        self.delegate?.willBeginPublishRequest(self)
    }
    
    init(backupEntry cloudBackupObject: FTCloudBackup, delegate: FTCloudPublishRequestDelegate?,sourceFile : URL) {
        sourceFileURL = sourceFile;
        refObject = cloudBackupObject;
        super.init()
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(didCancelOperation(fromBackup:)), name: NSNotification.Name(String(format: FTBackUpDidCancelledPublishNotificationFormat, self.refObject.uuid)), object: nil)
    }
    
    @objc private func didCancelOperation(fromBackup notification: Notification?) {
        self.canelRequestIfPossible()
    }

    func publishQueue() -> DispatchQueue? {
        return FTCloudBackUpManager.shared.activeCloudBackUpManager?.publishQueue
    }

    func cloudRootName() -> String? {
        return nil
    }
    
    func canelRequestIfPossible() {
        //subclass should override to stop operation
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
