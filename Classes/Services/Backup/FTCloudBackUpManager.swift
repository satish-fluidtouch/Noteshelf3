//
//  FTCloudBackUpManager.swift
//  FTAutoBackupSwift
//
//  Created by Simhachalam Naidu on 27/08/20.
//  Copyright © 2020 Simhachalam Naidu. All rights reserved.
//

import UIKit

class FTCloudBackUpManager : NSObject {

    var syncEnabledBooks: [String: Any]!
    var rootDocumentsURL: URL!
    private var activeBackupManager: FTCloudBackupPublisher?
    
    // MARK:- Shared instance -
    @objc static let shared: FTCloudBackUpManager = FTCloudBackUpManager()
    
    override init() {
        super.init()
        self.setCurrentBackUpCloud(self.currentBackUpCloudType())
        NotificationCenter.default.addObserver(self, selector: #selector(self.shelfItemDidUpdatedNotification(_:)), name: .shelfItemAdded, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.shelfItemDidUpdatedNotification(_:)), name: .shelfItemUpdated, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAppWillResignActive), name: UIApplication.willResignActiveNotification, object: nil);
    }

    @objc private func shelfItemDidUpdatedNotification(_ notification: NSNotification) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startPublish), object: nil)
        if isCloudBackupEnabled() {
            perform(#selector(startPublish), with: nil, afterDelay: 1)
        }
    }

    @objc var activeCloudBackUpManager: FTCloudBackupPublisher? {
        return self.activeBackupManager
    }
    
    // MARK:- Shelf Item for update -
    func shelfItemDidGetDeleted(_ shelfItem: FTAutoBackupItem) {
        activeCloudBackUpManager?.shelfItemDidGetDeleted(shelfItem)
    }
    
    // MARK:- Public Methods -
    @objc func startPublish() {
        activeCloudBackUpManager?.startPublish()
    }

    func cancelPublish() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startPublish), object: nil)
        activeCloudBackUpManager?.cancelPublish()
    }

    func isCloudBackupOverWifiOnly() -> Bool {
        return UserDefaults.standard.bool(forKey: "Auto_Backup_Wifi_only")
    }
    
    class func currentBackupString() -> String {
        var backupString = NSLocalizedString("BackupOff", comment: "Off")

        if FTCloudBackUpManager.shared.isCloudBackupEnabled() {
            switch FTCloudBackUpManager.shared.currentBackUpCloudType() {
            case FTCloudBackUpType.dropBox:
                    backupString = "Dropbox" //FTAccount.Dropbox
            case FTCloudBackUpType.oneDrive:
                    backupString = "OneDrive" //FTAccount.OneDrive
            case FTCloudBackUpType.googleDrive:
                    backupString = "GoogleDrive" //FTAccount.GoogleDrive
            case  FTCloudBackUpType.webdav:
                    backupString = "WebDAV"
                default:
                    backupString = NSLocalizedString("BackupOff", comment: "Off")
            }
        }
        return backupString
    }
    
    func setCloudBackUpOverWifiOnly(_ onlyInWIfi: Bool) {
        UserDefaults.standard.set(onlyInWIfi, forKey: "Auto_Backup_Wifi_only")
        UserDefaults.standard.synchronize()
    }

    func currentBackUpCloudType() -> FTCloudBackUpType {
        var backupType = FTCloudBackUpType.none
        if UserDefaults.standard.bool(forKey: "DroboxBackupUsed") {
            backupType = FTCloudBackUpType.dropBox
        }
        if let value = UserDefaults.standard.object(forKey: "CloudBackupType") as? NSNumber {
            backupType = FTCloudBackUpType(rawValue: value.intValue) ?? FTCloudBackUpType.none
        }
        return backupType
    }
    
    // MARK:- Shelf Item status -
    func isBackupEnabled(_ shelfItem: FTAutoBackupItem) -> Bool {
        var isBackupEnabled = false
        if currentBackUpCloudType() != FTCloudBackUpType.none {
            let object = transientBackupItem(forDocumentUUID: shelfItem.documentUUID)
            if object != nil {
                isBackupEnabled = true
            }
        }
        return isBackupEnabled
    }

    func transientBackupItem(forDocumentUUID uuid: String?) -> FTCloudBackupStatusInfo? {
        return syncEnabledBooks[uuid ?? ""] as? FTCloudBackupStatusInfo
    }
    
    // MARK:- Active / resign -
    @objc func handleAppDidBecomeActive() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startPublish), object: nil)
        perform(#selector(startPublish), with: nil, afterDelay: 1)
    }

    @objc func handleAppWillResignActive() {
        cancelPublish()
    }
    
    // MARK:- Private -
    func createCloudManger(for type: FTCloudBackUpType) -> FTCloudBackupPublisher? {
        let cloudManager: FTCloudBackupPublisher?
        switch(type) {
            case .dropBox:
                cloudManager = FTDropboxBackupPublisher.init(withDelegate: self)
            case .oneDrive:
                cloudManager = FTOneDriveBackupPublisher.init(withDelegate: self)
            case .googleDrive:
                cloudManager = FTGoogleDriveBackupPublisher.init(withDelegate: self)
            case .webdav:
                cloudManager = FTWebdavBackupPublisher.init(withDelegate: self)
            default:
                cloudManager = FTCloudBackupPublisher.init(withDelegate: self)
        }
        return cloudManager
    }

    func isCloudBackupEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "Auto_Backup_Turn_on")
    }
    func setEnableCloudBackUp(_ enable: Bool) {
        UserDefaults.standard.set(enable, forKey: "Auto_Backup_Turn_on")
        UserDefaults.standard.synchronize()
    }
    
    func setCurrentBackUpCloud(_ cloudType: FTCloudBackUpType) {
        if (nil == activeBackupManager) || (activeBackupManager?.cloudBackUpType() != cloudType) {
            self.setUpCloudBackup(cloudType)
        }
    }
    
    func fetchCloudBackUpItemsCount() -> Int {
        if let items = self.activeBackupManager?.backupEntryDictionary {
            var reqItemsCount = items.count
            guard let rootURL = self.rootDocumentsURL else {
                return reqItemsCount
            }
            for item in items {
                if let backupItem = item.value as? FTCloudBackup {
                    let backupItemURL = rootURL.appendingPathComponent(backupItem.relativeFilePath)
                    if !(FileManager.default.fileExists(atPath: backupItemURL.path)) {
                        reqItemsCount -= 1
                    }
                }
            }
            return reqItemsCount
        }
        return 0
    }
    
    func setUpCloudBackup(_ cloudType: FTCloudBackUpType) {
        let oldPublisher = activeBackupManager
        let shouldStartPublish = (nil != activeBackupManager)
        UserDefaults.standard.set(cloudType.rawValue, forKey: "CloudBackupType")
        UserDefaults.standard.removeObject(forKey: BACKUP_ERROR)
        UserDefaults.standard.synchronize()
        
        self.setEnableCloudBackUp((cloudType == .none) ? false : true)
        activeBackupManager?.cancelPublish()
        activeBackupManager?.ignoreList.clearIgnoreList()
        
        let publisher = createCloudManger(for: cloudType)
        if publisher != nil {
            self.activeBackupManager = publisher
            var syncDict: [String : Any] = [:]
            activeBackupManager?.publishQueue.sync(execute: {
                if let items = self.activeBackupManager?.backupEntryDictionary {
                    for (key, value) in items {
                        if let obj = value as? FTCloudBackup {
                            if shouldStartPublish {
                                obj.isDirty = true
                                obj.lastBackupDate = NSNumber(value: 0)
                            }
                          let transientShelfItem = FTCloudBackupStatusInfo(withBackupEntry: obj)
                          syncDict[key] = transientShelfItem
                        }
                    }
                    self.activeBackupManager?.saveData()
                }
            })
            syncEnabledBooks = syncDict
            if shouldStartPublish {
                startPublish()
            }
        }
        
        if let oldpublisher = oldPublisher, ((oldpublisher.cloudBackUpType() == FTCloudBackUpType.none && cloudType != FTCloudBackUpType.none) || (oldpublisher.cloudBackUpType() != FTCloudBackUpType.none && cloudType == FTCloudBackUpType.none)) {
            NotificationCenter.default.post(name: NSNotification.Name("CloudBackupOptionsDidChangeNotification"), object: self)
        }
    }
}
extension FTCloudBackUpManager: FTBaseCloudManagerDelegate {
    func cloudBackUpManager(_ cloudManager: FTCloudBackupPublisher, didCompleteWithError error: NSError?) {
        
    }
    
    func didCancelCloudBackUpManager(_ cloudManager: FTCloudBackupPublisher) {
        
    }
}

enum FTCloudBackupFormat: Int,CaseIterable {
    case noteshelf
    case pdf
    case both
    
    var displayTitle: String {
        switch self {
        case .noteshelf:
            return "Noteshelf";
        case .pdf:
            return "PDF";
        case .both:
            return "Noteshelf and PDF";
        }
    }
    
    var exportFormats: [RKExportFormat] {
        switch self {
        case .noteshelf:
            return [kExportFormatNBK];
        case .pdf:
            return [kExportFormatPDF];
        case .both:
            return [kExportFormatNBK,kExportFormatPDF];
        }
    }
}

extension FTUserDefaults {
    class var backupFormat: FTCloudBackupFormat {
        set {
            FTUserDefaults.defaults().setValue(newValue.rawValue, forKey: "cloudBackupFormat");
        }
        get {
            let rawValue = FTUserDefaults.defaults().integer(forKey: "cloudBackupFormat");
            return FTCloudBackupFormat(rawValue: rawValue) ?? .noteshelf
        }
    }
}
