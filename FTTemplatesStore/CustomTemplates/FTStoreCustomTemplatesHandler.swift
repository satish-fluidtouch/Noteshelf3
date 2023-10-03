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
    public var folderURL: URL
    public init() {
        guard let folder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find storeCustomTemplates directory")
        }
        folderURL = Foundation.URL(fileURLWithPath: folder).appendingPathComponent(folderName)
    }

    public func start() {
        Task {
            try await createDirectoryIfNeeded()
        }
    }

    private func createDirectoryIfNeeded() async throws {
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                throw error
            }
        }
    }

    public func locationFor(filePath: String) -> URL {
        let fileURL = URL(filePath: filePath)
        let returnUrl = folderURL.appendingPathComponent(fileURL.lastPathComponent.deletingPathExtension).appendingPathComponent(fileURL.lastPathComponent)
        return returnUrl
    }
}

extension FTStoreCustomTemplatesHandler {

    func templates() throws -> [FTTemplateStyle] {
        var customTemplates = [FTTemplateStyle]()

        let subcontents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

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
        let uniqueName = fileManager.uniqueFileName(directoryURL: folderURL, fileName: fileName)
        let destUrl = folderURL.appendingPathComponent(uniqueName)
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
        let templateUrl = folderURL.appendingPathComponent(template.title)
        let thumbUrl = templateUrl.appendingPathComponent("thumbnail@2x").appendingPathExtension("png")
        return thumbUrl
    }

    func removeFile(item: FTTemplateStyle) async throws {
        let templateUrl = folderURL.appendingPathComponent(item.title)
        try fileManager.removeItem(at: templateUrl)
    }

    func removeFileFor(title: String) throws {
        let templateUrl = folderURL.appendingPathComponent(title)
        try fileManager.removeItem(at: templateUrl)
    }

    func pdfUrlForTemplate(template: FTTemplateStyle) -> URL {
        let templateUrl = folderURL.appendingPathComponent(template.title)
        let subcontents =  try? FileManager.default.contentsOfDirectory(at: templateUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        var pdfUrl: URL!
        subcontents?.forEach({ url in
            if url.pathExtension == "noteshelf" {
                 pdfUrl = templateUrl.appendingPathComponent(template.title).appendingPathExtension("noteshelf")
            } else if url.pathExtension == "pdf" {
                 pdfUrl = templateUrl.appendingPathComponent(template.title).appendingPathExtension("pdf")
            }
        })
        return pdfUrl
    }

}
