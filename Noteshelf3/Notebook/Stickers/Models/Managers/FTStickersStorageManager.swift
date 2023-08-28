
import UIKit
import Combine

enum FTStickerError: String, Error {
    case fileNotFound = "File not found"
}

class FTStickersStorageManager {
    let fileManager: FileManager

    enum DirectoryType {
        case document
    }
    
    var recentStickersPlistUrl: URL? {
        let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last
        return url?.appendingPathComponent("\(StickerConstants.recentStickers).plist")
    }
    
    var documentPath: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    func downloadedStickersPath() -> URL? {
        if let libraryPath = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).last {
            let downloadedStickersPath = libraryPath.appendingPathComponent(StickerConstants.downloadedStickerPathExtention)
            return downloadedStickersPath
        }
        return nil
    }
    
    func saveRecentItem(directory: DirectoryType = .document, data: Data) {
        if let url = recentStickersPlistUrl {
            do {
                try data.write(to: url)
            } catch {
                print("Error saving data: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchRecentStickers(directory: DirectoryType = .document) -> AnyPublisher<Any,Error> {
        if let url = recentStickersPlistUrl {
            do {
                let data = try Data(contentsOf: url)
                let decoder = PropertyListDecoder()
                var object = try decoder.decode( [FTStickerItem].self, from: data)
                for selectedRecentitem in object{
                    let image = UIImage(named:selectedRecentitem.image)
                    if image == nil{
                        if let index = object.firstIndex(of: selectedRecentitem) {
                            object.remove(at: index)
                        }
                    }
                }
                return Just(object).setFailureType(to: Error.self).eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        } else {
            return Fail(error: FTStickerError.fileNotFound).eraseToAnyPublisher()
        }
    }
    
    func removeDownloadedSticker(atDirectory directory: DirectoryType, filePath: String) {
        let fileURL = getDocumentPath(directory: directory).appendingPathComponent(filePath)
        if !fileManager.fileExists(atPath: fileURL.absoluteString)  {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }

    func fetchDownloadedStickerPath(filepath: String) -> URL?  {
        if let fileURL = downloadedStickersPath()?.appending(path: filepath + "/"){
            return fileURL
        }
        return nil
    }
    
    func getDocumentPath(directory: DirectoryType) -> URL {
        switch directory {
        case .document:
            return documentPath
        }
    }
    
    func getDirectoryContent() -> [String] {
        if let downloadedStickerURL = downloadedStickersPath() {
            do {
                let subpaths = try fileManager.contentsOfDirectory(at: downloadedStickerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles )
                return subpaths.map { $0.lastPathComponent }
            } catch {
                return []
            }
        }
        return []
    }


    func removeStickersFor(fileName: String) throws {
        if let downloadedStickerURL = downloadedStickersPath() {
            let dest = downloadedStickerURL.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
        }
    }

}
