//
//  FTWidgetIntentDataHelper.swift
//  Noteshelf3 WidgetsExtension
//
//  Created by Sameer Hussain on 27/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

final class FTWidgetIntentDataHelper {
    static var sharedCacheURL: URL {
        if let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID()) {
            let directoryURL = url.appending(path: FTSharedGroupID.notshelfDocumentCache);
            return directoryURL
        }
        fatalError("Failed to get path");
    }
    
    public static func notebooks() -> [FTPinnedNotebook] {
        var notebooks = [FTPinnedNotebook]()
        if FileManager().fileExists(atPath: sharedCacheURL.path(percentEncoded: false)) {
            if let urls = try? FileManager.default.contentsOfDirectory(at: sharedCacheURL,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles) {
                let notebookFilteredUrls = urls.filter { eachUrl in
                    return eachUrl.pathExtension == "ns3"
                }
                notebookFilteredUrls.forEach { eachNotebookUrl in
                    let metaDataPlistUrl = eachNotebookUrl.appendingPathComponent("Metadata/Properties.plist")
                    if let relativePath = _relativePath(for: metaDataPlistUrl) {
                        let time : String
                        let coverImage : String
                        let pageAttrs = pageAttrs(for: eachNotebookUrl.path(percentEncoded: false))
                        coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                        time = timeFromDate(currentDate: eachNotebookUrl.fileCreationDate)
                        let book = FTPinnedNotebook(relativePath: relativePath, createdTime: time, coverImageName: coverImage, hasCover: pageAttrs.0, isLandscape: pageAttrs.1)
                        notebooks.append(book)
                    }
                }

            }
        }
        return notebooks
    }

    public static func _relativePath(for metaDataPlistUrl: URL) -> String? {
        var relativePath: String?
        if let data = try? Data(contentsOf: metaDataPlistUrl) {
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any], let _relativePath = plist["relativePath"] as? String {
                relativePath = _relativePath
            }
        }
        return relativePath
    }

    public static func pageAttrs(for notebookPath: String) -> (Bool, Bool) {
        var hasCover = false
        var isLandscape = false
        let docPlist = notebookPath.appending("Document.plist")
        do {
            let url = URL(fileURLWithPath: docPlist)
            let dict = try NSDictionary(contentsOf: url, error: ())
            if let pagesArray = dict["pages"] as? [NSDictionary], let firstPage = pagesArray.first {
                if let pageRectPDFKit = firstPage["pdfKitPageRect"] as? String {
                    let rect = NSCoder.cgRect(for: pageRectPDFKit);
                    if rect.width > rect.height {
                        isLandscape = true
                    }
                }
                hasCover = firstPage["isCover"] as? Bool ?? false
            }
        } catch {
            return (hasCover, isLandscape)
        }
        return (hasCover, isLandscape)
    }

    public static func timeFromDate(currentDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.locale = .current // Set locale to ensure proper representation of AM/PM
        return dateFormatter.string(from: currentDate)
    }
    
    public static func defaultBookEntry() -> FTPinnedNotebook? {
        var entry: FTPinnedNotebook?
        let sharedCacheURL = self.sharedCacheURL
        if FileManager().fileExists(atPath: sharedCacheURL.path(percentEncoded: false)) {
            if let urls = try? FileManager.default.contentsOfDirectory(at: sharedCacheURL,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles) {
                let notebookFilteredUrls = urls.filter { eachUrl in
                    return eachUrl.pathExtension == "ns3"
                }
                if let eachNotebookUrl = notebookFilteredUrls.first {
                    let metaDataPlistUrl = eachNotebookUrl.appendingPathComponent("Metadata/Properties.plist")
                    if let relativePath = _relativePath(for: metaDataPlistUrl) {
                        let time : String
                        let coverImage : String
                        let pageAttrs = pageAttrs(for: eachNotebookUrl.path(percentEncoded: false))
                        coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                        time = timeFromDate(currentDate: eachNotebookUrl.fileCreationDate)
                        entry = FTPinnedNotebook(relativePath: relativePath, createdTime: time, coverImageName: coverImage, hasCover: pageAttrs.0, isLandscape: pageAttrs.1)
                    }
                }

            }
        }
        return entry
    }
}

struct FTPinnedNotebook {
    let relativePath: String
    let createdTime: String
    let coverImageName: String
    let hasCover: Bool
    let isLandscape: Bool
    
    init(relativePath: String, createdTime: String, coverImageName: String, hasCover: Bool, isLandscape: Bool) {
        self.relativePath = relativePath
        self.createdTime = createdTime
        self.coverImageName = coverImageName
        self.hasCover = hasCover
        self.isLandscape = isLandscape
    }
}
