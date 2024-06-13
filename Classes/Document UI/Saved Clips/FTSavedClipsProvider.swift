//
//  FTSavedClipsHandler.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

 class FTSavedClipsProvider {
    private let folderName: String = "com.ns3.snippets"

    static let shared = FTSavedClipsProvider()
    private let fileManager = FileManager()

    private var rootURL: URL
    init() {
        guard let folder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find storeCustomTemplates directory")
        }
        rootURL = Foundation.URL(fileURLWithPath: folder).appendingPathComponent(folderName)
    }

    func start() {
        do {
            try createDirectoryIfNeeded()
        } catch {
        }
    }

    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
    }

    func locationFor(filePath: String) -> URL {
        let fileURL = URL(filePath: filePath)
        let returnUrl = rootURL.appendingPathComponent(fileURL.lastPathComponent.deletingPathExtension).appendingPathComponent(fileURL.lastPathComponent)
        return returnUrl
    }
}


 extension FTSavedClipsProvider {
    var snippetsFolder: URL {
        return rootURL
    }

    func createDefaultCategory() throws {
        let categoryUrl = rootURL.appendingPathComponent("My Clips")
        try fileManager.createDirectory(at: categoryUrl, withIntermediateDirectories: true)
    }

    func saveFileFrom(url : URL, to category: String, thumbnail: UIImage) throws -> URL? {
        let categoryUrl = rootURL.appendingPathComponent(category)
        let fileName = url.deletingPathExtension().lastPathComponent
        let destUrl = categoryUrl.appendingPathComponent(fileName)

        try fileManager.createDirectory(at: destUrl, withIntermediateDirectories: true)
        let templateURL = destUrl.appendingPathComponent(fileName).appendingPathExtension(url.pathExtension)
        if fileManager.fileExists(atPath: templateURL.path) {
            return templateURL
        }
        try fileManager.copyItem(at: url, to: templateURL)
        let thumbUrl = templateURL.deletingLastPathComponent().appending(path: "thumbnail@2x").appendingPathExtension("png")
        try? thumbnail.pngData()?.write(to: thumbUrl)

        return templateURL
    }

    func removeCategory(category: FTSavedClipsCategoryModel) throws {
        if let categoryUrl = category.url {
            if fileManager.fileExists(atPath: categoryUrl.path) {
                try fileManager.removeItem(at: categoryUrl)
            }
        }
    }

     func removeClip(clip: FTSavedClipModel) throws {
         let destUrl = clip.url
         if fileManager.fileExists(atPath: destUrl.path) {
             try fileManager.removeItem(at: destUrl)
         }
     }

     func renameCategory(category: FTSavedClipsCategoryModel, with fileName: String) throws -> URL? {
         if let categoryUrl = category.url {
             let desturl = categoryUrl.deletingLastPathComponent().appendingPathComponent(fileName)
             if fileManager.fileExists(atPath: categoryUrl.path) {
                 try fileManager.createDirectory(at: desturl, withIntermediateDirectories: false)
                 return try fileManager.replaceItemAt(desturl, withItemAt: categoryUrl)
             }
         }
         return nil
     }

}

extension FTSavedClipsProvider {
    func savedClipsCategories() throws -> [FTSavedClipsCategoryModel] {
        var savedClipsCategories = [FTSavedClipsCategoryModel]()

        let subcontents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        subcontents.forEach { url in
            let categoryTitle = url.lastPathComponent
            var clipCategoryModel = FTSavedClipsCategoryModel(title: categoryTitle, url: url)
            if let savedClips = try? self.savedClipsFor(category: categoryTitle) {
                clipCategoryModel.savedClips = savedClips
            }
            savedClipsCategories.append(clipCategoryModel)
        }
        return savedClipsCategories.sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
    }

    func savedClipsFor(category: String) throws -> [FTSavedClipModel] {
        var savedClips = [FTSavedClipModel]()

        var subcontents = try fileManager.contentsOfDirectory(at: rootURL.appendingPathComponent(category), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        subcontents = subcontents.sorted(by: {$0.fileModificationDate > $1.fileModificationDate})
        subcontents.forEach { url in
            let fileUrl = self.imageUrlForClip(url: url)
            let image = UIImage(contentsOfFile: fileUrl.path)
            let clipModel = FTSavedClipModel(title: url.lastPathComponent, url: url, categoryTitle: category, image: image)
            savedClips.append(clipModel)
        }
        return savedClips.sorted(by: {$0.url.fileCreationDate > $1.url.fileCreationDate})
    }


    func imageUrlForClip(url: URL) -> URL {
        let thumbUrl = url.appendingPathComponent("thumbnail@2x").appendingPathExtension("png")
        return thumbUrl
    }

    func fileUrlForClip(clip: FTSavedClipModel) -> URL? {
        let templateFolderUrl = rootURL.appendingPathComponent(clip.categoryTitle).appendingPathComponent(clip.title)
        let fileUrl = templateFolderUrl.appendingPathComponent(clip.title)
        let noteshelfFileUrl = fileUrl.appendingPathExtension(FTFileExtension.ns3)
        if FileManager.default.fileExists(atPath: noteshelfFileUrl.path) {
            return noteshelfFileUrl
        }
        return nil
    }

}

extension FileManager {
    func uniqueFileName(directoryURL: URL, fileName: String?) -> String {
        let baseName = fileName?.count ?? 0 > 0 ? fileName ?? "Untitled" : "Untitled"
           var suffix = 0

           while true {
               let uniqueName = suffix > 0 ? "\(baseName) \(suffix)" : baseName
               let fileURL = directoryURL.appendingPathComponent(uniqueName)

               if !fileExists(atPath: fileURL.path) {
                   return uniqueName
               }

               suffix += 1
           }
    }
}
