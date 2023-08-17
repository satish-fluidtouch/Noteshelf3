//
//  FTDropboxError.swift
//  Noteshelf
//
//  Created by Amar on 5/5/17.
//
//

import Foundation
import SwiftyDropbox

extension NSError
{
    @objc class func dropboxFileNotFoundError() -> NSError
    {
        return NSError.init(domain: "dropbox.com",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey:"File not found"]);
    }

    @objc class func dropboxInsufficientSpaceError() -> NSError
    {
        return NSError.init(domain: "dropbox.com",
                            code: 507,
                            userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("DropbBoxBackupStorageFullErrorMsg", comment: "Your dropbox storage is full.")]);
    }
    
    @objc class func dropboxDisallowedNameError() -> NSError
    {
        return NSError.init(domain: "dropbox.com",
                            code: 100,
                            userInfo: [NSLocalizedDescriptionKey:"Special characters are not allowed for name."]);
    }
    
    @objc class func dropboxMalformedPathError() -> NSError
    {
        return NSError.init(domain: "dropbox.com",
                            code: 102,
                            userInfo: [NSLocalizedDescriptionKey:"Special characters are not allowed for name."]);
    }
    
    @objc class func dropboxNoWritePermissionError() -> NSError
    {
        return NSError.init(domain: "dropbox.com",
                            code: 101,
                            userInfo: [NSLocalizedDescriptionKey:"Do not have permission to write"]);
    }
    
    @objc class func dropboxConflictPathError() -> NSError
    {
        return NSError.init(domain: "dropbox.com",
                            code: 103,
                            userInfo: [NSLocalizedDescriptionKey:"File with same name already exists"]);
    }

    @objc func isDropboxError() -> Bool
    {
        return (self.domain == "dropbox.com") ? true : false;
    }
}

extension Files.WriteError
{
    func nserrorMapped() -> NSError
    {

        let error: NSError;

        switch self {
        case .malformedPath(_):
            error = NSError.dropboxMalformedPathError();

        case .conflict(_):
            error = NSError.dropboxConflictPathError();

        case .noWritePermission:
            error = NSError.dropboxNoWritePermissionError();

        case .insufficientSpace:
            error = NSError.dropboxInsufficientSpaceError();

        case .disallowedName:
            error = NSError.dropboxDisallowedNameError();

        case .teamFolder, .operationSuppressed, .tooManyWriteOperations, .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 104,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }
        return error
    }
}

extension Files.LookupError
{
    func nserrorMapped() -> NSError
    {
        let error: NSError
        switch self {
        case .malformedPath(_):
            error = NSError.dropboxMalformedPathError();

        case .notFound:
            error = NSError.dropboxFileNotFoundError()

        case .notFile, .notFolder, .restrictedContent, .unsupportedContentType, .locked, .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }
        return error
    }
}

extension Files.UploadError
{
    func nserrorMapped() -> NSError
    {
        let error: NSError
        switch self {
        case .path(let writeError):
            error = writeError.reason.nserrorMapped();

        case .propertiesError, .payloadTooLarge, .contentHashMismatch, .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }

        return error
    }
}

extension Files.GetMetadataError
{
    func nserrorMapped() -> NSError
    {
        let error: NSError
        switch self {
        case .path(let lookupError):
            error = lookupError.nserrorMapped();
        }

        return error
    }
}

extension Files.DownloadError
{
    func nserrorMapped() -> NSError
    {
        let error: NSError
        switch self {
        case .path(let lookupError):
            error = lookupError.nserrorMapped();

        case .unsupportedFile, .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }
        return error
    }
}

extension Files.ListFolderContinueError
{
    func nserrorMapped() -> NSError
    {
        var error: NSError
        switch self {
        case .path(let lookupError):
            error = lookupError.nserrorMapped();

        case .reset, .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }
        return error
    }
}

extension Files.ListFolderError
{
    func nserrorMapped() -> NSError
    {
        var error: NSError
        switch self {
        case .path(let lookupError):
            error = lookupError.nserrorMapped();

        case .templateError, .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }
        return error
    }
}

extension Files.CreateFolderError
{
    func nserrorMapped() -> NSError
    {
        var error: NSError
        switch self {
        case .path(let lookupError):
            error = lookupError.nserrorMapped();
        }
        return error
    }
}

extension Files.RelocationError
{
    func nserrorMapped() -> NSError
    {
        var error: NSError
        switch self {
        case .fromLookup(let lookupError):
            error = lookupError.nserrorMapped();

        case .fromWrite(let writeError):
            error = writeError.nserrorMapped();

        case .to(let writeError):
            error = writeError.nserrorMapped();

        case .cantCopySharedFolder,
                .cantNestSharedFolder,
                .cantMoveFolderIntoItself,
                .tooManyFiles,
                .duplicatedOrNestedPaths,
                .cantTransferOwnership,
                .insufficientQuota,
                .internalError,
                .cantMoveSharedFolder,
                .cantMoveIntoVault,
                .cantMoveIntoFamily,
                .other:
            error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        }

        return error
    }
}

extension Async.PollError {
    func nserrorMapped() -> NSError {
        let error = NSError.init(domain: "dropbox.com",
                                 code: 105,
                                 userInfo: [NSLocalizedDescriptionKey:self.description]);

        return error
    }
}

// In the latest Swift SDK, this is not being posted.
//extension DBRequestError
//{
//    @objc func nserrorMapped() -> NSError?
//    {
//        var error : NSError?;
//        if(self.nsError != nil) {
//            error = self.nsError as NSError?;
//        }
//        else {
//            var code = 200;
//            if(self.statusCode != nil) {
//                code = self.statusCode!.intValue;
//            }
//            if(nil != self.errorContent) {
//                error = NSError.init(domain:"dropbox.com",
//                                     code:code,
//                                     userInfo: [NSLocalizedDescriptionKey:self.errorContent!]);
//            }
//            else {
//                error = NSError.init(domain:"dropbox.com",
//                                     code:code,
//                                     userInfo: nil);
//            }
//        }
//        return error;
//    }
//}
