//
//  FTLocalClipartProvider.swift
//  ClipartKit
//
//  Created by Akshay on 28/11/18.
//  Copyright © 2018 FluidTouch. All rights reserved.
//

import UIKit


enum FTMediaLibraryError: Error {
    case serverError
    case networkError
    case dataCorrupt
    case requestError
}

protocol FTLocalMediaLibraryProviderProtocol: class {
    func addMediaLibraryModelToLocal(mediaLibraryModel: FTMediaLibraryModel)
    func reorderMediaInLocal(with localMediaLibraryArray: [FTMediaLibraryModel])
    func removeMediaLibraryModelFromLocal(localMediaLibraryModel: FTMediaLibraryModel)
    func mediaLibraryImageFromLocal(with id: String) -> UIImage?
}

class FTLocalMediaLibraryProvider: FTLocalMediaLibraryProviderProtocol {
    
    fileprivate struct FTLocalMediaLibraryWrapper: Decodable, Encodable {
        var mediaLibraryArray: [FTMediaLibraryModel]
    }

    fileprivate let maxRecentMediaLibrary = 30

    var mediaType: MediaSource?
    
    func fetchLocalMediaLibrary( mediaType : MediaSource, completion:@escaping (([FTMediaLibraryModel]) -> Void), errorReceived:@escaping ((FTMediaLibraryError) -> Void)) {
        self.mediaType = mediaType
        let localMediaLibraryArray = fetchLocalMediaLibraryList()
            DispatchQueue.main.async {
                completion(localMediaLibraryArray)
            return
        }
    }

    func fetchNextPage(completion: @escaping (([FTMediaLibraryModel]) -> Void)) {
        completion([FTMediaLibraryModel]())
    }

    func addMediaLibraryModelToLocal(mediaLibraryModel: FTMediaLibraryModel) {

        var localMediaLibraryArray = fetchLocalMediaLibraryList()

        guard localMediaLibraryArray.filter({ $0.id == mediaLibraryModel.id }).isEmpty else { return }

        localMediaLibraryArray.insert(mediaLibraryModel, at: 0)

        try? removeLastUsedFromLocal(localMediaLibraryArray: &localMediaLibraryArray)
        try? updateLocalMediaLibraryPlistFile(with: localMediaLibraryArray)
    }

    func mediaLibraryImageFromLocal(with id: String) -> UIImage? {
        return UIImage(contentsOfFile: localMediaLibraryImageURL(for: id).path)
    }

    func removeMediaLibraryModelFromLocal(localMediaLibraryModel: FTMediaLibraryModel) {
        var recentMediaLibraryArray = fetchLocalMediaLibraryList()
        recentMediaLibraryArray.removeAll(where: { $0.id == localMediaLibraryModel.id })
        try? updateLocalMediaLibraryPlistFile(with: recentMediaLibraryArray)
        try? removeLocalMediaLibraryAssets(with: localMediaLibraryModel.id)
    }

    func reorderMediaInLocal(with localMediaLibraryArray: [FTMediaLibraryModel]) {
        try? updateLocalMediaLibraryPlistFile(with: localMediaLibraryArray)
    }
    
    func localMediaLibraryImageURL(for id: String) -> URL {
        return FTUtils.mediaLibraryDirectoryURL.appendingPathComponent("\(id)").appendingPathExtension("png")
    }
}

// MARK: - File Operations
fileprivate extension FTLocalMediaLibraryProvider {

    func fetchLocalMediaLibraryList() -> [FTMediaLibraryModel] {
        do {
            let data = try Data(contentsOf: localContentsPlistURL)
            let plistDecoder = PropertyListDecoder()
            let localMediaLibraryWrapper = try plistDecoder.decode(FTLocalMediaLibraryWrapper.self, from: data)
            let filteredArray = localMediaLibraryWrapper.mediaLibraryArray.map({ (item) -> FTMediaLibraryModel in
                item.isLocal = true
                return item
            })

            return filteredArray
        } catch {
            return [FTMediaLibraryModel]()
        }
    }

    func removeLastUsedFromLocal(localMediaLibraryArray:inout [FTMediaLibraryModel]) throws {
        if localMediaLibraryArray.count > maxRecentMediaLibrary {
            let removedMediaLibrary = localMediaLibraryArray.removeLast()
            try removeLocalMediaLibraryAssets(with: removedMediaLibrary.id)
        } else {
            debugPrint("No Last used clipart found to remove")
        }
    }

    func removeLocalMediaLibraryAssets(with id: String) throws {
        do {
            try FileManager.default.removeItem(at: localMediaLibraryImageURL(for: id))
        } catch {
            throw error
        }
    }

    func updateLocalMediaLibraryPlistFile(with recentMediaLibrary: [FTMediaLibraryModel]) throws {
        let localWrapper = FTLocalMediaLibraryWrapper(mediaLibraryArray: recentMediaLibrary)
        let encoder = PropertyListEncoder()
        let finalPlistData = try encoder.encode(localWrapper)
        do {
            try finalPlistData.write(to: localContentsPlistURL)
        } catch {
            throw error
        }
    }

    var localContentsPlistURL: URL {
        var plistURL = FTUtils.mediaLibraryDirectoryURL.appendingPathComponent("Contents").appendingPathExtension("plist")
        switch mediaType {
        case .pixabay:
            plistURL = FTUtils.mediaLibraryDirectoryURL.appendingPathComponent("Contents").appendingPathExtension("plist")
        case .unSplash:
            plistURL = FTUtils.mediaLibraryDirectoryURL.appendingPathComponent("unsplash").appendingPathExtension("plist")
        default:
            break
        }
        if !FileManager.default.fileExists(atPath: plistURL.path) {
            let recentsWrapper = FTLocalMediaLibraryWrapper(mediaLibraryArray: [FTMediaLibraryModel]())
            let encoder = PropertyListEncoder()
            do {
                let initialPlistData = try encoder.encode(recentsWrapper)
                try initialPlistData.write(to: plistURL)
                _ = FileManager.default.createFile(atPath: plistURL.path, contents: initialPlistData, attributes: nil)
            } catch {
                debugPrint("Error Occured in Creating initial Clipart Plist")
            }
        }
        return plistURL
    }
}
