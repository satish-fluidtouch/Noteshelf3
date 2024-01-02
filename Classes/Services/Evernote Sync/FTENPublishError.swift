//
//  FTENPublishError.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTENPublishError: NSObject {
    static let FTENPublishDomain = "FTENPublish";
    
    static var authError: NSError {
        let error = NSError(domain: FTENPublishDomain
                            , code: 401
                            , userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("EvernoteAuthTokenExpiredTitle",comment: "Unable to authenticate with Evernote")]);
        return error;
    }
    
    static var unexpectedError: NSError {
        return NSError(domain: FTENPublishDomain
                       , code: 10005
                       , userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("UnexpectedError",comment: "Unexpected Error.")])
    }
    
    static var pageSnapshotError: NSError {
        return NSError(domain: FTENPublishDomain
                       , code: 10006
                       , userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("PageSnapshotFailed.",comment: "Page Snapshot failed.")])
    }

    static func isAuthError(_ error:NSError) -> Bool {
        if error.domain == FTENPublishError.FTENPublishDomain, error.code == 401 {
            return true;
        }
        return false;
    }
}
