//
//  FTStoreLibraryHandler.swift
//  TempletesStore
//
//  Created by Siva on 16/03/23.
//

import Foundation

private let storeLibraryPlist: String = "storeLibrary.plist"
private let storeLibraryFolderName: String = "com.ns3.storeLibrary"

public class FTStoreLibraryHandler {
    public static let shared = FTStoreLibraryHandler()
    private var libTemplates = [FTTemplateStyle]()

    // MARK: Private
    private let fileManager = FileManager()
    private let storeLibraryFolderURL: URL
    private init() {
        guard let templatesFolder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else {
            fatalError("Unable to find libraryTemplates directory")
        }
        storeLibraryFolderURL = Foundation.URL(fileURLWithPath: templatesFolder).appendingPathComponent(storeLibraryFolderName)
    }

    public func start() {
        Task {
            try await createStoreLibraryDirectoryIfNeeded()
            try await createStoreLibraryPlistIfNeeded()
            try await libraryTemplates()
        }
    }

    func stop() {
    }

    private func createStoreLibraryDirectoryIfNeeded() async throws {
        if !fileManager.fileExists(atPath: storeLibraryFolderURL.path) {
            try fileManager.createDirectory(at: storeLibraryFolderURL, withIntermediateDirectories: true)
        }
    }

    private func createStoreLibraryPlistIfNeeded() async throws {
        let libraryPlistURL = storeLibraryFolderURL.appendingPathComponent(storeLibraryPlist)
        if !fileManager.fileExists(atPath: libraryPlistURL.path) {
            var dic: [String: [DiscoveryItem]] = [String :[DiscoveryItem]]()
            // Swift Dictionary To Data.
            dic["templates"] = []
            let data = try PropertyListSerialization.data(fromPropertyList: dic, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
            try data.write(to: libraryPlistURL, options: .atomic)
        }
    }

}

extension FTStoreLibraryHandler {
    private func storeLibraryLocation() -> URL {
        guard NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last != nil else {
            fatalError("Unable to find libraryTemplates directory")
        }
        let libraryPlistURL = storeLibraryFolderURL.appendingPathComponent(storeLibraryPlist)
        return libraryPlistURL
    }

    func storeLibraryPlistFile() async throws -> FTStoreLibraryModel? {
        let destinationURL = storeLibraryLocation()
        if fileManager.fileExists(atPath: destinationURL.path) {
            let data = try Data(contentsOf: destinationURL)
            let decoder = PropertyListDecoder()
            let plist = try decoder.decode(FTStoreLibraryModel.self, from: data)
            return plist
        }
        return nil
    }

    @discardableResult
    func libraryTemplates() async throws -> [FTTemplateStyle] {
        let destinationURL = storeLibraryLocation()
        if fileManager.fileExists(atPath: destinationURL.path) {
            let data = try Data(contentsOf: destinationURL)
            let decoder = PropertyListDecoder()
            let libraryTemplatesPlist = try decoder.decode(FTStoreLibraryModel.self, from: data)
            let templates = libraryTemplatesPlist.templates
            self.libTemplates = templates
            return templates
        }
        return []
    }

    func saveIntoLibrary(style: FTTemplateStyle, title: String) async throws {
        var templateStyle = style
        if var plistFile = try await self.storeLibraryPlistFile() {
            let destinationURL = storeLibraryLocation()
            var templates = plistFile.templates
            templateStyle.title = title
            templates.append(templateStyle)
            plistFile.templates = templates
            self.libTemplates = templates

            let encoder = PropertyListEncoder()
            let encodedData = try encoder.encode(plistFile)
            try encodedData.write(to: destinationURL)
        }
    }

    func removeFromLibrary(template: FTTemplateStyle) async throws {
        if var plistFile = try await self.storeLibraryPlistFile() {
            let destinationURL = storeLibraryLocation()
            var templates = plistFile.templates
            templates = templates.filter { $0.templateName != template.templateName || $0.orientation != template.orientation }
            plistFile.templates = templates
            self.libTemplates = templates
            let data1 = try JSONEncoder().encode(plistFile)
            if let dictionary = try JSONSerialization.jsonObject(with: data1, options: .mutableContainers) as? NSDictionary {
                try dictionary.write(to: destinationURL)
            }
        }
    }

    func isInStoreLibrary(template: FTTemplateStyle) -> Bool {
            let islibrary = self.libTemplates.filter { $0.templateName == template.templateName && $0.orientation == template.orientation }
            if islibrary.count > 0 {
                return true
            }
        return false
    }


}
