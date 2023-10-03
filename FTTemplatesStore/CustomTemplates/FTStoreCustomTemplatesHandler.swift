//
//  FTStoreCustomTemplatesHandler.swift
//  TempletesStore
//
//  Created by Siva on 26/04/23.
//

import Foundation
import UIKit
import PDFKit
import FTCommon

public class FTStoreCustomTemplatesHandler {
    private let folderName: String = "com.ns3.storeCustomTemplates"

    public static let shared = FTStoreCustomTemplatesHandler()
    private let fileManager = FileManager()
    private var rootURL: URL
    public init() {
        guard let folder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find storeCustomTemplates directory")
        }
        rootURL = Foundation.URL(fileURLWithPath: folder).appendingPathComponent(folderName)
    }

    public func start() {
        Task {
            try await createDirectoryIfNeeded()
        }
    }

    private func createDirectoryIfNeeded() async throws {
        if !fileManager.fileExists(atPath: rootURL.path) {
            do {
                try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
            } catch {
                throw error
            }
        }
    }

    public func locationFor(filePath: String) -> URL {
        let fileURL = URL(filePath: filePath)
        let returnUrl = rootURL.appendingPathComponent(fileURL.lastPathComponent.deletingPathExtension).appendingPathComponent(fileURL.lastPathComponent)
        return returnUrl
    }
}

extension FTStoreCustomTemplatesHandler {

    func templates() throws -> [FTTemplateStyle] {
        var customTemplates = [FTTemplateStyle]()

        let subcontents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

        subcontents.forEach { url in
            var template = FTTemplateStyle(title: url.lastPathComponent, type: "Custom Template", templateName: url.lastPathComponent, version: 1)
            let fileUrl = FTStoreCustomTemplatesHandler.shared.imageUrlForTemplate(template: template)
            let image = UIImage(contentsOfFile: fileUrl.path)
            if let image {
                if  image.size.width > image.size.height  { // landscape
                    template.orientation = .landscape
                }
            }
            customTemplates.append(template)
        }
        return customTemplates
    }

    public func saveFileFrom(url : URL, to fileName: String) throws -> URL? {
        let uniqueName = fileManager.uniqueFileName(directoryURL: rootURL, fileName: fileName)
        let destUrl = rootURL.appendingPathComponent(uniqueName)
        try fileManager.createDirectory(at: destUrl, withIntermediateDirectories: true)
        let templateURL = destUrl.appendingPathComponent(uniqueName).appendingPathExtension(url.pathExtension)
        if fileManager.fileExists(atPath: templateURL.path) {
            return templateURL
        }
        try fileManager.copyItem(at: url, to: templateURL)
        try templateURL.generateThumbnailForFile(fileName: "thumbnail@2x")
        return templateURL
    }

    func tempLocationForFile(url: URL) throws -> URL? {
        let name = url.lastPathComponent
        let tempUrl = FTTemplatesCache().temporaryFolder.appendingPathComponent(name)
        if fileManager.fileExists(atPath: tempUrl.path) {
            return tempUrl
        }
        try fileManager.copyItem(at: url, to: tempUrl)
        return tempUrl
    }


    func imageUrlForTemplate(template: FTTemplateStyle) -> URL {
        let templateUrl = rootURL.appendingPathComponent(template.title)
        let thumbUrl = templateUrl.appendingPathComponent("thumbnail@2x").appendingPathExtension("png")
        return thumbUrl
    }

    func removeFile(item: FTTemplateStyle) async throws {
        let templateUrl = rootURL.appendingPathComponent(item.title)
        try fileManager.removeItem(at: templateUrl)
    }

    func removeFileFor(title: String) throws {
        let templateUrl = rootURL.appendingPathComponent(title)
        try fileManager.removeItem(at: templateUrl)
    }

    func filUrlForTemplate(template: FTTemplateStyle) -> URL? {
        let templateFolderUrl = rootURL.appendingPathComponent(template.title)
        let fileUrl = templateFolderUrl.appendingPathComponent(template.title)
        let noteshelfFileUrl = fileUrl.appendingPathExtension(nsBookExtension)
        let pdfFileUrl = fileUrl.appendingPathExtension("pdf")
        let thumbnailUrl = templateFolderUrl.appendingPathComponent("thumbnail@2x").appendingPathExtension("png")

        if !FileManager.default.fileExists(atPath: thumbnailUrl.path) {
             try? templateFolderUrl.generateThumbnailForFile(fileName: "thumbnail@2x")
        }
        if FileManager.default.fileExists(atPath: noteshelfFileUrl.path) {
            return noteshelfFileUrl
        } else if FileManager.default.fileExists(atPath: pdfFileUrl.path) {
            return pdfFileUrl
        }
        return nil
    }

}
