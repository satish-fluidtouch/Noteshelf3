//
//  FTCloudBackupErrors.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 29/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let FTCloudBackupErrorDomain = "NSCloudBackup";

enum FTCloudBackupErrorCode: Int {
    case storageFull = 1001
    case fileNotAvailable = 1002
    case packageNeedsUpgrade = 1003
    case passwordEnabled = 1004
    case invalidInput = 2001
    case contentPrepareFailedPresviously = 2002
}

extension FTCloudBackupErrorCode {
    var error: NSError {
        switch self {
        case .storageFull:
            return NSError(domain: FTCloudBackupErrorDomain
                           , code: self.rawValue
                           , userInfo: [NSLocalizedDescriptionKey : "cloud.backup.error.failedToCreateBackup".localized]
            );
        case .fileNotAvailable:
            return NSError(domain: FTCloudBackupErrorDomain
                           , code: self.rawValue
                           , userInfo: [NSLocalizedDescriptionKey :"cloud.backup.error.fileNotFound".localized]
            );
        case .packageNeedsUpgrade:
            return NSError(domain: FTCloudBackupErrorDomain
                           , code: self.rawValue
                           , userInfo: [NSLocalizedDescriptionKey : "cloud.backup.error.packageNeedsUpgrade".localized]
            );
        case .passwordEnabled:
            return NSError(domain: FTCloudBackupErrorDomain
                           , code: self.rawValue
                           , userInfo: [NSLocalizedDescriptionKey :"cloud.backup.error.filePasswordProtected".localized]
            );
        case .invalidInput:
            return NSError(domain: FTCloudBackupErrorDomain
                           , code: self.rawValue
                           , userInfo: nil)
        case .contentPrepareFailedPresviously:
            return NSError(domain: FTCloudBackupErrorDomain
                           , code: self.rawValue
                           , userInfo: [NSLocalizedDescriptionKey:"cloud.backup.error.contentPreviouslyCrashed".localized]
            );
        }
    }
}

extension NSError {
    func isError(_ errorCode: FTCloudBackupErrorCode) -> Bool {
        if self.domain == FTCloudBackupErrorDomain, self.code == errorCode.rawValue {
            return true;
        }
        return false;
    }
}
