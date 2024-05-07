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
    static var allNoteBooks: [FTPinnedNotebook] {
      return getPinnedNotebooks()
    }
    
    static var sharedCacheURL: URL {
        if let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID()) {
            let directoryURL = url.appending(path: FTSharedGroupID.notshelfDocumentCache);
            return directoryURL
        }
        fatalError("Failed to get path");
    }
    
    static var localDocumentsUrl: URL? {
        if let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID()) {
            let directoryURL = url.appending(path: "Noteshelf.nsdata/User Documents");
            return directoryURL
        }
        return nil
    }
    
    public static func checkIfBookExists(for book: FTPinnedBookType) -> Bool {
        return allNoteBooks.contains { $0.docId == book.identifier }
    }
    
    public static func updateNotebookIfNeeded(for book: inout FTPinnedBookType) {
        if let matchingBook = allNoteBooks.first(where: { $0.docId == book.identifier && ($0.relativePath != book.relativePath || $0.createdTime != book.time)}) {
            book.relativePath = matchingBook.relativePath
            book.coverImage = matchingBook.coverImageName
            book.time = matchingBook.createdTime
        }
    }
    
    private static func getPinnedNotebooks() -> [FTPinnedNotebook] {
        let defaults = UserDefaults.init(suiteName: FTSharedGroupID.getAppGroupID())
        if let iCloudOn = defaults?.bool(forKey: "iCloudOn"), !iCloudOn {
            return localNotebooks()
        } else {
            return iCloudNotebooks()
        }
    }
    
    public static func iCloudNotebooks() -> [FTPinnedNotebook] {
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
                    let docAttrs = docAttrs(for: metaDataPlistUrl)
                    if let relativePath = docAttrs.0 {
                        let time : String
                        let coverImage : String
                        let pageAttrs = pageAttrs(for: eachNotebookUrl.path(percentEncoded: false))
                        coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                        time = timeFromDate(currentDate: eachNotebookUrl.fileModificationDate)
                        let book = FTPinnedNotebook(docId: docAttrs.1 ?? "", relativePath: relativePath, createdTime: time, coverImageName: coverImage, hasCover: pageAttrs.0, isLandscape: pageAttrs.1)
                        notebooks.append(book)
                    }
                }

            }
        }
        return notebooks
    }
    
    private static func localNotebooks() -> [FTPinnedNotebook] {
        var notebookUrls = [URL]()
        var notebooks = [FTPinnedNotebook]()
        if let localDocumentsUrl, let urls = try? FileManager.default.contentsOfDirectory(at: localDocumentsUrl,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)  {
            urls.forEach({ eachUrl in
                notebookUrls.append(contentsOf: self.contentsOfURL(eachUrl))
            })
            
            notebookUrls.forEach { eachNotebookUrl in
                let metaDataPlistUrl = eachNotebookUrl.appendingPathComponent("Metadata/Properties.plist")
                let docAttrs = docAttrs(for: metaDataPlistUrl)
                let relativePath = eachNotebookUrl.relativePathWRTCollection()
                let time : String
                let coverImage : String
                let pageAttrs = pageAttrs(for: eachNotebookUrl.path(percentEncoded: false))
                coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                time = timeFromDate(currentDate: eachNotebookUrl.fileModificationDate)
                let book = FTPinnedNotebook(docId: docAttrs.1 ?? "", relativePath: relativePath, createdTime: time, coverImageName: coverImage, hasCover: pageAttrs.0, isLandscape: pageAttrs.1)
                notebooks.append(book)
            }
        }
        return notebooks
    }
    
    private static func contentsOfURL(_ url: URL) -> [URL] {
        let urls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                includingPropertiesForKeys: nil,
                                                                options: .skipsHiddenFiles);
        let filteredURLS = self.filterItemsMatchingExtensions(urls);
        
        var notebookUrlList: [URL] = [URL]()
            filteredURLS.enumerated().forEach({ (_,eachURL) in
                if(eachURL.pathExtension == FTFileExtension.group) {
                    let dirContents = self.contentsOfURL(eachURL);
                    if !dirContents.isEmpty {
                        notebookUrlList.append(contentsOf: dirContents);
                    }
                }
                else {
                    notebookUrlList.append(eachURL);
                }
            });
        
        return notebookUrlList
    }
    
    private static func filterItemsMatchingExtensions(_ items : [URL]?) -> [URL] {
        let extToListen:[String] = [FTFileExtension.group, FTFileExtension.ns3]
        var filteredURLS = [URL]();
        if let items {
            if(!extToListen.isEmpty) {
                filteredURLS = items.filter({ (eachURL) -> Bool in
                    if(extToListen.contains(eachURL.pathExtension)) {
                        return true
                    }
                    return false
                });
            }
        }
        return filteredURLS
    }

    public static func docAttrs(for metaDataPlistUrl: URL) -> (String?, String?) {
        var relativePath: String?
        var docID: String?
        if let data = try? Data(contentsOf: metaDataPlistUrl) {
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                if let _relativePath = plist["relativePath"] as? String {
                    relativePath = _relativePath
                }
                if let documentId = plist["document_ID"] as? String {
                    docID = documentId
                }
            }
        }
        return (relativePath, docID)
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
                    let docAttrs = docAttrs(for: metaDataPlistUrl)
                    if let relativePath = docAttrs.0 {
                        let time : String
                        let coverImage : String
                        let pageAttrs = pageAttrs(for: eachNotebookUrl.path(percentEncoded: false))
                        coverImage = eachNotebookUrl.appending(path:"cover-shelf-image.png").path(percentEncoded: false);
                        time = timeFromDate(currentDate: eachNotebookUrl.fileModificationDate)
                        entry = FTPinnedNotebook(docId: docAttrs.1 ?? "", relativePath: relativePath, createdTime: time, coverImageName: coverImage, hasCover: pageAttrs.0, isLandscape: pageAttrs.1)
                    }
                }

            }
        }
        return entry
    }
    
    public static func displayName(from path: String) -> String {
        let components = path.components(separatedBy: "/")
        var name = path.lastPathComponent.deletingPathExtension
        if var firstComponent = components.first, firstComponent.hasSuffix(".shelf") {
            firstComponent = firstComponent.deletingPathExtension
            name = firstComponent + "/" + path.lastPathComponent.deletingPathExtension
        }
        return name
    }

}

struct FTPinnedNotebook {
    let docId: String
    let relativePath: String
    let createdTime: String
    let coverImageName: String
    let hasCover: Bool
    let isLandscape: Bool
    
    init(docId: String, relativePath: String, createdTime: String, coverImageName: String, hasCover: Bool, isLandscape: Bool) {
        self.docId = docId
        self.relativePath = relativePath
        self.createdTime = createdTime
        self.coverImageName = coverImageName
        self.hasCover = hasCover
        self.isLandscape = isLandscape
    }
}
