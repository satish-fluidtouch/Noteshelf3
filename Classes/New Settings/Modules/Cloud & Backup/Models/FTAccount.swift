//
//  FTAccount.swift
//  Noteshelf
//
//  Created by Paramasivan on 7/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

let FTUpdateBackupStatusNotification = "FTUpdateBackupStatusNotification"

@objc enum FTCloudBackUpType: Int {
    case none
    case dropBox
    case oneDrive
    case googleDrive
    case webdav
    
    func cloudBackUpAccount() -> FTAccount? {
        switch self {
        case .dropBox:
            return FTAccount.dropBox
        case .oneDrive:
            return FTAccount.oneDrive
        case .googleDrive:
            return FTAccount.googleDrive
        case .webdav:
            return FTAccount.webdav
        default:
            return nil
        }
    }
};

enum FTAccount: String {
    case dropBox = "Dropbox"
    case evernote = "Evernote"
    case oneDrive = "OneDrive"
    case googleDrive = "Google Drive"
    case webdav = "WebDAV"

    var image: UIImage {
        switch self {
        case .dropBox:
            return UIImage(named: "dropbox")!
        case .evernote:
            return UIImage(named: "evernote")!
        case .oneDrive:
            return UIImage(named: "Onedrive")!
        case .googleDrive:
            return UIImage(named: "googleDrive")!
        case .webdav:
            return UIImage(named: "Webdav")!
        }
    }

    var bigIcon: UIImage {
        switch self {
        case .dropBox:
            return UIImage(named: "dropBox")!
        case .evernote:
            return UIImage(named: "evernote")!
        case .oneDrive:
            return UIImage(named: "Onedrive")!
        case .googleDrive:
            return UIImage(named: "googleDrive")!
        case .webdav:
            return UIImage(named: "Webdav")!
        }
    }
    
    var cloudType: FTCloudBackUpType {
        switch self {
            case .dropBox:
                return FTCloudBackUpType.dropBox
            case .oneDrive:
                return FTCloudBackUpType.oneDrive
            case .googleDrive:
                return FTCloudBackUpType.googleDrive
            case .webdav:
                return FTCloudBackUpType.webdav
            default:
                return FTCloudBackUpType.none
        }
    }
}
enum FTBackupFormat: String {
    case noteshelf = ".noteshelf"
    case pdf = ".pdf"
}
