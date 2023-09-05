//
//  FTShelfViewModel+BackUpErrorHandler.swift
//  Noteshelf3
//
//  Created by Narayana on 02/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import Combine

enum FTCloudPublishErrorType: Int {
    case enPublish,cloudBackup;
    
    fileprivate var userDefaultsErrorKey: String {
        switch self {
        case .enPublish:
            return EVERNOTE_PUBLISH_ERROR
        case .cloudBackup:
            return BACKUP_ERROR;
        }
    }
    
    fileprivate var notificationName: Notification.Name {
        switch self {
        case .enPublish:
            return FTENIgnoreListManager.changeList;
        case .cloudBackup:
            return FTCloudBackupIgnoreList.changeList;
        }
    }
}

class FTCloudBackupENPublishError: NSObject,ObservableObject {
    @Published var hasError: Bool = false;
    private var ignoreListObserver: NSObjectProtocol?;
    private var errorTrackType: FTCloudPublishErrorType;
    
    required init(type: FTCloudPublishErrorType) {
        errorTrackType = type
        super.init();
        ignoreListObserver = NotificationCenter.default.addObserver(forName: type.notificationName, object: nil, queue: OperationQueue.main) {[weak self] _ in
            self?.updateHasError();
        };
        UserDefaults.standard.addObserver(self, forKeyPath: type.userDefaultsErrorKey, options: [.new], context: nil);
        self.updateHasError();
    }
    
    private func updateHasError() {
        var hasError = false        
        if self.errorTrackType == .cloudBackup {
            if(
                UserDefaults.standard.object(forKey: self.errorTrackType.userDefaultsErrorKey) != nil
               || !(FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList.ignoredItemsForUIDisplay().isEmpty ?? true)
               ) {
                hasError = true
            }
        }
        else if self.errorTrackType == .enPublish {
            if(
                UserDefaults.standard.object(forKey: self.errorTrackType.userDefaultsErrorKey) != nil
               || !(FTENIgnoreListManager.shared.ignoredNotebooks().filter({$0.shouldDisplay}).isEmpty)
               ) {
                hasError = true
            }
        }
        self.hasError = hasError;
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: self.errorTrackType.userDefaultsErrorKey);
        if let observer = self.ignoreListObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        self.updateHasError();
    }
}
