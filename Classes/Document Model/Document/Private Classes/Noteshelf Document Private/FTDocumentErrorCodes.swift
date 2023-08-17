//
//  FTDocumentErrorCodes.swift
//  Noteshelf
//
//  Created by Amar on 4/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let FTDocumentCreateErrorDomain = "FTDocumentCreateErrorDomain";
let FTDocumentTemplateImportErrorDomain = "FTDocumentTemplateImportErrorDomain";

extension Error //open document
{
    fileprivate var nsError : NSError {
        return self as NSError;
    }
    var isConflictError : Bool {
        if(nsError.domain == "FTDocumentOpenErrorDomain"
            && nsError.code == FTDocumentOpenErrorCode.inConflict.rawValue) {
            return true;
        }
        return false;
    };

    var isInvalidPinError : Bool {
        if(nsError.domain == "FTDocumentOpenErrorDomain"
            && nsError.code == FTDocumentOpenErrorCode.invalidPin.rawValue) {
            return true;
        }
        return false;
    };

    var isNotDownloadedError : Bool {
        if(nsError.domain == "FTDocumentOpenErrorDomain"
            && nsError.code == FTDocumentOpenErrorCode.notDownload.rawValue) {
            return true;
        }
        return false;
    };
    var isNotExistError : Bool {
        if(nsError.domain == FTDocumentTemplateImportErrorDomain
            && nsError.code == FTDocumentTemplateImportErrorCode.requiresAppUpdate.rawValue) {
            return true;
        }
        return false;
    };

}

enum FTDocumentOpenErrorCode : Int
{
    case notDownload = 500
    case inConflict
    case invalidPin
    
    static func error(_ errorCode : FTDocumentOpenErrorCode) -> NSError {
        return NSError.init(domain: "FTDocumentOpenErrorDomain", code: errorCode.rawValue, userInfo: nil);
    }
}

enum FTDocumentCreateErrorCode : Int
{
    case openFailed = 100
    case saveFailed
    case cancelled
    case pageIndexMismatch
    case failedToImport
    case failedToUpdateTemplate
    case unexpectedError

    fileprivate func localizedDescription() -> String
    {
        switch self {
        case .openFailed:
            return NSLocalizedString("OpenFailed", comment: "Open failed")
        case .saveFailed:
            return NSLocalizedString("SaveFailed", comment: "Save failed")
        case .cancelled:
            return NSLocalizedString("CreationCancelled", comment: "Creation Cancelled")
        case .pageIndexMismatch:
            return NSLocalizedString("PageIndexMismatch", comment: "Page Index Mismatch")
        case .failedToImport:
            return NSLocalizedString("FailedToImport", comment: "Failed To Import")
        case .failedToUpdateTemplate:
            return NSLocalizedString("FailedToUpdateTemplate", comment: "FailedToUpdateTemplate")
        case .unexpectedError:
            return NSLocalizedString("UnexpectedError", comment: "Unexpected error")
        }
    }
    
    static func error(_ errorCode : FTDocumentCreateErrorCode) -> NSError {
        return NSError.init(domain: FTDocumentCreateErrorDomain, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey:errorCode.localizedDescription()]);
    }
}

enum FTDocumentTemplateImportErrorCode : Int
{
    case openFailed = 100
    case prepareForImportFailed
    case docConsistancyFailed
    case requiresAppUpdate

    fileprivate func localizedDescription() -> String
    {
        switch self {
        case .openFailed:
            return NSLocalizedString("OpenFailed", comment: "Open failed")
        case .prepareForImportFailed:
            return NSLocalizedString("PrepareForImportFailed", comment: "Prepare For Import Failed")
        case .docConsistancyFailed:
            return NSLocalizedString("DocConsistancyFailed", comment: "Doc Consistancy Failed")
        case .requiresAppUpdate:
            return NSLocalizedString("RequiresAppUpdate", comment: "Please update your app...");
        }
    }
    
    
    static func error(_ errorCode : FTDocumentTemplateImportErrorCode) -> NSError {
        return NSError.init(domain: FTDocumentTemplateImportErrorDomain, code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey:errorCode.localizedDescription()]);
    }
}
