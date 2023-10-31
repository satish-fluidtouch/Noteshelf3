//
//  FTStoreTemplatesVersionHandler.swift
//  FTTemplatesStore
//
//  Created by Siva on 17/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTTemplateVerionItem: Codable {
    let id = UUID()
    let version: Int
    let templateName: String
    enum CodingKeys: String, CodingKey {
        case version
        case templateName
    }
}

struct FTTemplateVerionModel: Codable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    var templates: [FTTemplateVerionItem]
    enum CodingKeys: String, CodingKey {
        case templates
    }
}


class FTStoreTemplatesVersionHandler {

    public static let shared = FTStoreTemplatesVersionHandler()
    private let templatesVersionPlist = "templatesVersion.plist"
    // MARK: Private
    private let fileManager = FileManager()
    private let templatesVersionPlistUrl: URL
    private var versionInfo: FTTemplateVerionModel? = nil

    private init() {
        guard let libratyDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find library Directory")
        }
        templatesVersionPlistUrl = Foundation.URL(fileURLWithPath: libratyDirectory).appendingPathComponent(templatesVersionPlist)
    }

    func startVersionUpdateIfNeeded() throws {
        try createVersionPlistIfNeeded()
    }

    private func createVersionPlistIfNeeded() throws {
        if !fileManager.fileExists(atPath: templatesVersionPlistUrl.path) {
            try createVersionPlist()
            try addVersionForDownloadedTemplates()
            try removeThumbnailsFromTemplatesLocation()
        } else {
            let tagsInfo = try readVersionInfo()
            if tagsInfo == nil {
                try createVersionPlist()
            }
        }
    }

    private func createVersionPlist() throws {
        var dic: [String: [FTTemplateVerionItem]] = [String :[FTTemplateVerionItem]]()
        dic["templates"] = []
        let data = try PropertyListSerialization.data(fromPropertyList: dic, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
        try data.write(to: templatesVersionPlistUrl, options: .atomic)
    }

    private func addVersionForDownloadedTemplates() throws {
        let templatesUrl = FTTemplatesCache().templatesFolder
        let subcontents = try fileManager.contentsOfDirectory(at: templatesUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let pdfFiles = subcontents.filter { $0.pathExtension == "pdf" }
        var versionInfo = try readVersionInfo()

        pdfFiles.forEach { fileUrl in
            let fileName = fileUrl.deletingPathExtension().lastPathComponent
            let item = FTTemplateVerionItem(version: 1, templateName: fileName)
            versionInfo?.templates.append(item)
        }
        if let versionInfo {
            try saveVersionInfo(info: versionInfo)
        }
    }

    private func removeThumbnailsFromTemplatesLocation() throws {
        let templatesUrl = FTTemplatesCache().templatesFolder
        let subcontents = try fileManager.contentsOfDirectory(at: templatesUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let thumbnails = subcontents.filter { $0.pathExtension == "png" }
        for thumbnail in thumbnails {
            try fileManager.removeItem(at: thumbnail)
        }
    }

    private func readVersionInfo() throws -> FTTemplateVerionModel? {
        if fileManager.fileExists(atPath: templatesVersionPlistUrl.path) {
            let data = try Data(contentsOf: templatesVersionPlistUrl)
            let decoder = PropertyListDecoder()
            let plist = try decoder.decode(FTTemplateVerionModel.self, from: data)
            return plist
        } else {
            try createVersionPlistIfNeeded()
        }
        return nil
    }

    private func saveVersionInfo(info: FTTemplateVerionModel) throws {
        let data = try JSONEncoder().encode(info)
        if let dictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
            dictionary.write(toFile: templatesVersionPlistUrl.path, atomically: false)
        }
    }

    func allowToReDownload(item: FTTemplateVerionItem) throws -> Bool {
        if versionInfo == nil {
            versionInfo = try readVersionInfo()
        }
        if let filteredItem = versionInfo?.templates.first(where: {$0.templateName == item.templateName}) {
            return item.version > filteredItem.version
        }
        return false
    }

    func updateVersionPlistWith(item: FTTemplateVerionItem) throws  {
        if versionInfo == nil {
            versionInfo = try readVersionInfo()
        }
        if let firstIndex = versionInfo?.templates.firstIndex(where: {$0.templateName == item.templateName}) {
            versionInfo?.templates[firstIndex] = item
        } else {
            versionInfo?.templates.append(item)
        }
        if let versionInfo {
            try saveVersionInfo(info: versionInfo)
        }
    }

}
