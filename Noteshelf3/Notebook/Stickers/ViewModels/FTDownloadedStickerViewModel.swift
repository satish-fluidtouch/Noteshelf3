//
//  FTDownloadedStickerViewModel.swift
//  StickerModule
//
//  Created by Rakesh on 27/03/23.
//

import UIKit
import Combine
import FTCommon

final class FTDownloadedStickerViewModel: ObservableObject {
    @Published var downloadedStickers: [FTStickerSubCategory] = []

    lazy var fileStickerManager = FTStickersStorageManager()
    var error: Error?


    func getDownloadedStickers() {
        let filePaths = fileStickerManager.getDirectoryContent(directory: .library)
        filePaths.forEach { path in
            let stickerItems = fetchDownloadedThumbnailStickers(filePath: path)
            do{
                let title = try getDownloadedStickerTitle(folderName: path)
                let downloadedStickersPack = FTStickerSubCategory(title: title, image: "", filename: path, stickerItems: stickerItems)
                downloadedStickers.append(downloadedStickersPack)
            }catch{
                debugLog("No Downloaded Stickers Found")
            }
        }
    }

    func getDownloadedStickerTitle(folderName: String) throws -> String{
        let metadataPath = fileStickerManager.fetchDownloadedStickerPath(fromDirectory: .library, filepath: folderName).appendingPathComponent("metadata.plist")
            let infoPlistData = try Data(contentsOf: metadataPath)
            let decodedData = try PropertyListDecoder().decode([String: String].self, from: infoPlistData)
            var templatesFileName = "display_name_en"
             let currentLocalization = FTCommonUtils.currentLanguage()
            templatesFileName = "display_name_\(currentLocalization)"

            if let title = decodedData[templatesFileName] {
                return title
            }else{
                return ""
            }
    }

    func getDownloadedStickerThumbnail(_ filename: String) -> UIImage? {
        var docsURL = fileStickerManager.getDocumentPath(directory: .library)
        docsURL = docsURL.appendingPathComponent(StickerConstants.downloadedStickerPathExtention)
            .appendingPathComponent(filename)
            .appendingPathComponent("preview")
            .appendingPathExtension("jpg")
        do {
            let data = try Data(contentsOf: docsURL)
            return UIImage(data: data) ?? UIImage()
        } catch {
            debugLog("Error loading data: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchDownloadedThumbnailStickers(filePath: String) -> [FTStickerItem] {
        var downloadedStickerURL = fileStickerManager.fetchDownloadedStickerPath(fromDirectory: .library, filepath: filePath).appendingPathComponent("thumbnails")
        if !FileManager.default.fileExists(atPath: downloadedStickerURL.path) {
            downloadedStickerURL = fileStickerManager.fetchDownloadedStickerPath(fromDirectory: .library, filepath: filePath).appendingPathComponent("stickers")
        }
        var stickerItems = [FTStickerItem]()
        do {
            let subcontents = try FileManager.default.contentsOfDirectory(at:downloadedStickerURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            subcontents.forEach { url in
                let sticker = FTStickerItem(image: url.path)
                stickerItems.append(sticker)
            }
        } catch {
            debugLog("Unable to load data from \(downloadedStickerURL.absoluteString)")
        }
        return stickerItems
    }

    func getOriginalDownloadedSticker(subitem: FTStickerItem, fileName: String) -> FTStickerItem {
        let imageName = subitem.image.lastPathComponent
        var docsURL = fileStickerManager.getDocumentPath(directory: .library)
        docsURL = docsURL.appendingPathComponent(StickerConstants.downloadedStickerPathExtention)
            .appendingPathComponent(fileName)
            .appendingPathComponent("stickers")
            .appendingPathComponent(imageName)
        let newSubitem = FTStickerItem(image: docsURL.path)
        return newSubitem
    }

    func validateDownloadedStickersPath() -> Bool{
        let filePaths = fileStickerManager.getDirectoryContent(directory: .library)
        var pathAvailable: Bool = false
        filePaths.forEach { path in
            let urlPath = fileStickerManager.fetchDownloadedStickerPath(fromDirectory: .library, filepath: path)
            let stickerPathURL = urlPath.appendingPathComponent("stickers")
            let metadataPathUrl = urlPath.appendingPathComponent("metadata.plist")
            let thubnailImagePath = urlPath.appendingPathComponent("preview.jpg")

            if  FileManager.default.fileExists(atPath: stickerPathURL.path) && FileManager.default.fileExists(atPath: metadataPathUrl.path) && FileManager.default.fileExists(atPath: thubnailImagePath.path) {
                pathAvailable = true
            }
        }
        return pathAvailable
    }

    func removeDownloadedStickers(item: FTStickerSubCategory) throws {
        try fileStickerManager.removeStickersFor(fileName: item.filename)
    }

}

