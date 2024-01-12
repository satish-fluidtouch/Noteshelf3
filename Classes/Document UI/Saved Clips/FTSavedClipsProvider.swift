//
//  FTSavedClipsHandler.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public class FTSavedClipsProvider {
    private let folderName: String = "com.ns3.snippets"

    public static let shared = FTSavedClipsProvider()
    private let fileManager = FileManager()

    private var rootURL: URL
    public init() {
        guard let folder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find storeCustomTemplates directory")
        }
        rootURL = Foundation.URL(fileURLWithPath: folder).appendingPathComponent(folderName)
    }

    public func start() {
        do {
            try createDirectoryIfNeeded()
        } catch {
        }
    }

    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
            try self.createDefaultCategory()
        }
    }

    public func locationFor(filePath: String) -> URL {
        let fileURL = URL(filePath: filePath)
        let returnUrl = rootURL.appendingPathComponent(fileURL.lastPathComponent.deletingPathExtension).appendingPathComponent(fileURL.lastPathComponent)
        return returnUrl
    }
}


public extension FTSavedClipsProvider {
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

    func deleteSavedClipFor(category: String, fileName: String) throws {
        let categoryUrl = rootURL.appendingPathComponent(category)
        let destUrl = categoryUrl.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: destUrl.path) {
            try fileManager.removeItem(at: destUrl)
        }
    }

    func deleteCategory(category: String) throws {
        let categoryUrl = rootURL.appendingPathComponent(category)
        if fileManager.fileExists(atPath: categoryUrl.path) {
            try fileManager.removeItem(at: categoryUrl)
        }
    }

}

extension FTSavedClipsProvider {
    func savedClipsCategories() throws -> [FTSavedClipsCategoryModel] {
        var savedClipsCategories = [FTSavedClipsCategoryModel]()

        var subcontents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        if subcontents.count == 0 {
            try createDefaultCategory()
            subcontents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        }
        subcontents.forEach { url in
            let categoryTitle = url.lastPathComponent
            var clipCategoryModel = FTSavedClipsCategoryModel(title: categoryTitle)
            if let savedClips = try? self.savedClipsFor(category: categoryTitle) {
                clipCategoryModel.savedClips = savedClips
            }
            savedClipsCategories.append(clipCategoryModel)
        }
        return savedClipsCategories
    }

    func savedClipsFor(category: String) throws -> [FTSavedClipModel] {
        var savedClips = [FTSavedClipModel]()

        let subcontents = try fileManager.contentsOfDirectory(at: rootURL.appendingPathComponent(category), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

        subcontents.forEach { url in
            let fileUrl = self.imageUrlForClip(url: url)
            let image = UIImage(contentsOfFile: fileUrl.path)
            let clipModel = FTSavedClipModel(title: url.lastPathComponent, categoryTitle: category, image: image)
            savedClips.append(clipModel)
        }
        return savedClips
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
