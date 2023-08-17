//
//  FTCloudDownloadFactory.swift
//  Noteshelf
//
//  Created by Amar on 8/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import ObjectiveDropboxOfficial

class FTCloudDownloadFactory: NSObject {
    //as of now downloadAsPDF will be considered only for Google Drive files as by default google drive
    //allows to donwload the selected google drive file as pdf if available. For all other this parameter is ignored.
    // Note if you want to download the item as it in google drive pass false to downloadAsPDF.
    class func cloudDownloaderForItem(_ item: AnyObject, downloadAsPDF: Bool) -> FTCloudDownloadProtocol? {
        let downloader: FTCloudDownloadProtocol?;

        switch item {
        case is DBFILESMetadata:
            downloader = FTDropboxItemDownloader();
        #if !targetEnvironment(macCatalyst)
        case is GTLRDrive_File:

            guard let file = item as? GTLRDrive_File else { return nil }

            if(!downloadAsPDF || (file.mimeType == FTGoogleDrivePDFMimeType) || file.mimeType?.contains("audio") ?? false) {
                downloader = FTGoogleDriveFileDownloader();
            } else {
                downloader = FTGoogleDriveFilePDFDownloader();
            }
        #endif
        case is FTWeLinkFile:
            downloader = FTWeLinkFileDownloader();
        default:
            downloader = nil
        }
        return downloader;
    }
}
