//
//  FTCloudBackupStatusInfo.swift
//  FTAutoBackupSwift
//
//  Created by Simhachalam Naidu on 13/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit

@objc enum FTBackupStatusType: Int {
    case none
    case pending
    case inProgress
    case complete
    case error
}

class FTCloudBackupStatusInfo: NSObject {
    var uuid: String = UUID().uuidString
    @objc var progress: CGFloat = 0.0 {
        willSet {
            if newValue != progress {
                self.willChangeValue(forKey: "progress")
            }
        }
        didSet {
            self.didChangeValue(forKey: "progress")
        }
    }
    private var isDirty: Bool = false
    @objc var backUpStatus: FTBackupStatusType = FTBackupStatusType.none {
        willSet {
            if newValue != backUpStatus {
                self.willChangeValue(forKey: #keyPath(FTCloudBackupStatusInfo.backUpStatus))
            }
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(FTCloudBackupStatusInfo.backUpStatus))
        }
    }
    var lastBackedUpDate: TimeInterval = 0.0
    var documentLastUpdatedDate: TimeInterval = 0.0
    private var error: NSError?

    convenience init(withBackupEntry backupEntry: FTCloudBackup) {
        self.init()
        
        self.uuid = backupEntry.uuid;
        self.isDirty = backupEntry.isDirty
        self.lastBackedUpDate = backupEntry.lastBackupDate?.doubleValue ?? 0.0
        self.documentLastUpdatedDate = backupEntry.lastUpdated?.doubleValue ?? 0.0
        self.backUpStatus = self.isDirty ? .pending : .complete
        
        self.addObservers()
    }
    
    convenience init(initWithShelfItem shelfItem: FTAutoBackupItem) {
        self.init()
        self.uuid = shelfItem.documentUUID
        if let timestamp = shelfItem.lastUpdated?.doubleValue {
            self.documentLastUpdatedDate = timestamp
        }
        self.isDirty = true
        self.addObservers()
        self.backUpStatus = .pending
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willBeginPublish(_:)),
            name: NSNotification.Name(String(format: FTBackUpWillBeginPublishNotificationFormat, uuid)),
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didCompletePublish(_:)),
            name: NSNotification.Name(String(format: FTBackUpDidCompletePublishNotificationFormat, uuid)),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didCompletePublishWithError(_:)),
            name: NSNotification.Name(String(format: FTBackUpDidCompletePublishWithErrorNotificationFormat, uuid)),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdatePublish(_:)),
            name: NSNotification.Name(String(format: FTBackUpPublishProgressNotificationFormat, uuid)),
            object: nil)

    }
    
    func updateWithShelfItem(_ shelfItem: FTAutoBackupItem) {
        self.isDirty = true
        self.error = nil;
        self.backUpStatus = .pending
    }
    
    @objc func willBeginPublish(_ notification: Notification?) {
        error = nil
        isDirty = false
        backUpStatus = .inProgress
    }

    @objc func didCompletePublish(_ notification: Notification?) {
        if !isDirty {
            if let lastbackedDate = notification?.userInfo?[FTBackUpLastBackedUpDateKey] as? NSNumber, lastbackedDate.doubleValue > lastBackedUpDate {
                self.lastBackedUpDate = lastbackedDate.doubleValue
            }
            backUpStatus = .complete
        }
    }

    @objc func didCompletePublishWithError(_ notification: Notification?) {
        if !isDirty {
            isDirty = true
            error = notification?.userInfo?["NSError"] as? NSError
            self.backUpStatus = .error
        }
    }

    @objc func didUpdatePublish(_ notification: Notification?) {
        if !isDirty {
            backUpStatus = .inProgress
            if let progressNumber = notification?.userInfo?["progress"] as? NSNumber {
                self.progress = CGFloat(progressNumber.floatValue)
            }
            //CLOUD_BACKUP_LOG("didUpdatePublish : %f", progress)
        }
    }

    func backUpStatusString() -> String {
        var statusString = ""
        switch backUpStatus {
        case .error:
                statusString = error?.dropboxFriendlyMessageErrorDescription() ?? ""
        case .inProgress:
                statusString = NSLocalizedString("BackUpInProgress", comment: "Backup In Progress...")
        case .complete:
            if let ignoreList = FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList, ignoreList.isBackupIgnored(forShelfItemWithUUID: uuid) {
                statusString = NSLocalizedString("BackUpFailed", comment: "Backup Failed")
            } else if lastBackedUpDate >= documentLastUpdatedDate {
                statusString = NSLocalizedString("BackupUpToDate", comment: "Backup up-to-date")
            }
            else {
                statusString = NSLocalizedString("LastBackupDateTime", comment: "Last Backup at %@")
            }
        case .pending:
            if lastBackedUpDate > 0 {
                statusString = String.localizedStringWithFormat(NSLocalizedString("LastBackupDateTime", comment: "Last Backup at %@"), formattedLastSyncDate())
            } else {
                statusString = NSLocalizedString("BackUpPending", comment: "Backup Pending")
            }
        case .none:
            statusString = ""
        }
        return statusString
    }
    func formattedLastSyncDate() -> String {
        let date = Date(timeIntervalSinceReferenceDate: lastBackedUpDate)
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

}
