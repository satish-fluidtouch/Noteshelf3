//
//  FTStoreService.swift
//  FTTemplates
//
//  Created by Siva on 15/02/23.
//

import Foundation
import Combine
import FTCommon
import ZipArchive
import Network

private let storeTemplatesFolderName: String = "com.ns3.storeTemplates"
private let storeStickersFolderName: String = "com.ns3.storeStickers"

enum FTTemplatesServiceError: String, Error {
    case fileNotFound = "Unable to find the requested File."
    case parsingError = "Unable to parse."
    case notImplemented = "Not implemented service fetch for Templates"
    case templateNotFound = "Template Not Found"
    case savingError = "Error while saving Template"
    case unableToDownloadStickers = "Error while downloading stickers"

}

protocol FTStoreServiceApi {
    func fetchTemplates() -> AnyPublisher<FTStoreModel, FTTemplatesServiceError>
    func downloadTemplateFor(url: URL) async throws -> URL
    func downloadStickersFor(url: URL, fileName: String) async throws -> URL
}

protocol FTLocalServiceApi {
   func fetchTemplates() -> AnyPublisher<FTStoreModel, FTTemplatesServiceError>
}

class FTLocalService: FTLocalServiceApi {
    #if DEBUG
    func fetchTemplates1() -> AnyPublisher<FTStoreModel, FTTemplatesServiceError> {
        let fileManager = FileManager.default

        // Search for the file in the user's document directory
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Handle error
            return Fail(error: FTTemplatesServiceError.parsingError).eraseToAnyPublisher()
        }

        let fileURL = documentDirectory.appendingPathComponent("templates.plist")

        do {
            let data = try Data.init(contentsOf: fileURL)
            let templatesStore = try PropertyListDecoder().decode(FTStoreModel.self, from: data)
            return Just<FTStoreModel>(templatesStore)
                .setFailureType(to: FTTemplatesServiceError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: FTTemplatesServiceError.parsingError).eraseToAnyPublisher()
        }
    }
    #endif

    func fetchTemplates() -> AnyPublisher<FTStoreModel, FTTemplatesServiceError> {
        let templatesFileName = "templates_\(FTCommonUtils.currentLanguage())"
        guard let bundlePath = storeBundle.path(forResource: templatesFileName, ofType: "plist") else { return Fail(error: FTTemplatesServiceError.fileNotFound).eraseToAnyPublisher()}
        do {
            let url = URL(fileURLWithPath: bundlePath)
            let data = try Data.init(contentsOf: url)
            let templatesStore = try PropertyListDecoder().decode(FTStoreModel.self, from: data)
            return Just<FTStoreModel>(templatesStore)
                .setFailureType(to: FTTemplatesServiceError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: FTTemplatesServiceError.parsingError).eraseToAnyPublisher()
        }
    }
}

class FTStoreService: FTStoreServiceApi {

    func downloadTemplateFor(url: URL) async throws -> URL {
        let session = URLSession.shared
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.downloadTask(with: url) { responseUrl, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                if let tempUrl = responseUrl {
                    let dest = FTTemplatesCache().templatesFolder.appendingPathComponent(url.lastPathComponent)
                    do {
                        if !FileManager.default.fileExists(atPath: dest.path) {
                            try FileManager.default.moveItem(at: tempUrl, to: dest)
                        }
                        continuation.resume(returning: dest)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            task.resume()
        }
    }

    func downloadStickersFor(url: URL, fileName: String) async throws -> URL {
        let dest = FTTemplatesCache().stickersFolder.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: dest.path) {
            return dest
        }
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: url)
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.downloadTask(with: request) { responseUrl, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                if let tempUrl = responseUrl {
                    do {
                        try FTTemplatesCache().createDirectoryForstickerFileIfNeeded(url: dest)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    let success = SSZipArchive.unzipFile(atPath: tempUrl.path, toDestination: dest.path)
                    if success == false {
                        continuation.resume(throwing: FTTemplatesServiceError.unableToDownloadStickers)
                    }
                    continuation.resume(returning: dest)
                }
            }
            task.resume()
        }
    }

    func fetchTemplates() -> AnyPublisher<FTStoreModel, FTTemplatesServiceError> {
        return Fail(error: FTTemplatesServiceError.notImplemented).eraseToAnyPublisher()
    }

}


protocol FTTemplatesCacheService {
    var templatesFolder: URL { get }
}

public class FTTemplatesCache: FTTemplatesCacheService {
    
    public init(){}

    var templatesFolder: URL {
        var path = ""
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)
        if let url = urls.last {
            path = "\(url.path.appending("/\(storeTemplatesFolderName)"))"
        }
        if !fileManager.fileExists(atPath: path) && path != "" {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch _ {
            }
        }
        return URL(fileURLWithPath: path)
    }

    var stickersFolder: URL {
        var path = ""
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)
        if let url = urls.last {
            path = "\(url.path.appending("/\(storeStickersFolderName)"))"
        }
        if !fileManager.fileExists(atPath: path) && path != "" {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch _ {
            }
        }
        return URL(fileURLWithPath: path)
    }

    func createDirectoryForstickerFileIfNeeded(url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) && url.path != "" {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: false, attributes: nil)
        }
    }

    func stickerpackisExists(fileName: String) -> Bool {
        let dest = FTTemplatesCache().stickersFolder.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: dest.path) {
            return true
        }
        return false

    }
    
    var temporaryFolder: URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory());
        return url
    }
    
    public func locationFor(filePath: String) -> URL {
        let fileURL = URL(filePath: filePath)
        let returnUrl = templatesFolder.appendingPathComponent(fileURL.lastPathComponent)
        return returnUrl
    }
}
