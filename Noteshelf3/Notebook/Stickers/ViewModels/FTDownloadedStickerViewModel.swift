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

    func validateAndGetDownloadedStickers(){
        let filePaths = fileStickerManager.getDirectoryContent()
        filePaths.forEach { path in
            if let urlPath = fileStickerManager.fetchDownloadedStickerPath(filepath: path){
                let stickerPathURL = urlPath.appendingPathComponent("stickers")
                let metadataPathUrl = urlPath.appendingPathComponent("metadata.plist")
                let thubnailImagePath = urlPath.appendingPathComponent("preview.jpg")

                if  FileManager.default.fileExists(atPath: stickerPathURL.path) && FileManager.default.fileExists(atPath: metadataPathUrl.path) && FileManager.default.fileExists(atPath: thubnailImagePath.path) {
                    let stickerItems = fetchDownloadedThumbnailStickers(filePath: path)
                    do{
                        let title = try getDownloadedStickerTitle(folderName: path)
                        let downloadedStickersPack = FTStickerSubCategory(title: title, image: "", filename: path, stickerItems: stickerItems,type: .downloadedSticker)
                        downloadedStickers.append(downloadedStickersPack)
                    }catch{
                        debugLog("No Downloaded Stickers Found")
                    }
                }
            }
        }
    }

    func getDownloadedStickerTitle(folderName: String) throws -> String{
        if let metadataPath = fileStickerManager.fetchDownloadedStickerPath(filepath: folderName)?.appendingPathComponent("metadata.plist"){
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
        return ""
    }

    func getDownloadedStickerThumbnail(_ filename: String) -> UIImage? {
        if let docsURL = fileStickerManager.downloadedStickersPath()?
            .appendingPathComponent(filename)
            .appendingPathComponent("preview")
            .appendingPathExtension("jpg"){
           do {
               let data = try Data(contentsOf: docsURL)
               return UIImage(data: data) ?? UIImage()
           } catch {
               debugLog("Error loading data: \(error.localizedDescription)")
               return nil
           }
       }
        return nil
    }

    func fetchDownloadedThumbnailStickers(filePath: String) -> [FTStickerItem] {
        if let downloadPath = fileStickerManager.fetchDownloadedStickerPath(filepath: filePath){
             var downloadedStickerURL = downloadPath.appendingPathComponent("thumbnails")
                if !FileManager.default.fileExists(atPath: downloadedStickerURL.path) {
                    downloadedStickerURL = downloadPath.appendingPathComponent("stickers")
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
        return []
    }

    func getStickerSubitem(subitem: FTStickerItem, fileName: String,type: StickerType) -> FTStickerItem {
        if type == .downloadedSticker{
            let imageName = subitem.image.lastPathComponent
            let docsURL = fileStickerManager.downloadedStickersPath()?
                .appendingPathComponent(fileName)
                .appendingPathComponent("stickers")
                .appendingPathComponent(imageName)
            let newSubitem = FTStickerItem(image: docsURL?.path ?? "")
            return newSubitem
        }else{
            return subitem
        }
    }

    func removeDownloadedStickers(item: FTStickerSubCategory) throws {
        try fileStickerManager.removeStickersFor(fileName: item.filename)
    }

}

