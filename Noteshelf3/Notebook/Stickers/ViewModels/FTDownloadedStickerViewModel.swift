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
            let stickerItems = fetchDonwloadedStickerSubItems(filePath: path)
            let title = getDownloadedStickerTitle(folderName: path)
            let downloadedStickersPack = FTStickerSubCategory(title: title, image: "", filename: path, stickerItems: stickerItems)
            downloadedStickers.append(downloadedStickersPack)
        }
    }

    func getDownloadedStickerTitle(folderName: String) -> String{
        let metadataPath = fileStickerManager.fetchDownloadedStickerPath(fromDirectory: .library, filepath: folderName).appendingPathComponent("metadata.plist")
        do {
            let infoPlistData = try Data(contentsOf: metadataPath)
            let decodedData = try PropertyListDecoder().decode([String: String].self, from: infoPlistData)
            var templatesFileName = "display_name_en"
             let currentLocalization = FTCommonUtils.currentLanguage()
            templatesFileName = "display_name_\(currentLocalization)"

            guard let title = decodedData[templatesFileName] else {
                fatalError("Key not found in metadata.")
            }
            return title
        } catch {
            fatalError("Error in data parsing \(error)")
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
            print("Error loading data: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchDonwloadedStickerSubItems(filePath: String) -> [FTStickerItem] {
        let downloadedStickerURL = fileStickerManager.fetchDownloadedStickerPath(fromDirectory: .library, filepath: filePath).appendingPathComponent("stickers")

        var stickerItems = [FTStickerItem]()
        do {
            let subcontents = try FileManager.default.contentsOfDirectory(at:downloadedStickerURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            subcontents.forEach { url in
                let sticker = FTStickerItem(image: url.path)
                stickerItems.append(sticker)
            }
        } catch {
            print("Unable to load data from \(downloadedStickerURL.absoluteString)")
        }
        return stickerItems
    }

    func removeDownloadedStickers(item: FTStickerSubCategory) throws {
        try fileStickerManager.removeStickersFor(fileName: item.filename)
    }

}

