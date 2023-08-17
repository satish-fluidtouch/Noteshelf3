
import UIKit
import Combine

enum FTStickerError: String, Error {
    case fileNotFound = "File not found"
}

class FTStickersStorageManager {
    let fileManager: FileManager

    enum DirectoryType {
        case document
        case library
    }
    
    var recentStickersPlistUrl: URL? {
        let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last
        return url?.appendingPathComponent("\(StickerConstants.recentStickers).plist")
    }
    
    var documentPath: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var libraryPath: URL {
        fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }
    
    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
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
    
    func fetchDownloadedSticker(fromDirectory directory: DirectoryType = .document,
                              filepath: String) -> UIImage?  {
        let fileURL = getDocumentPath(directory: directory).appendingPathComponent(filepath)
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data) ?? UIImage()
        } catch {
            print("Error loading data: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchDownloadedStickerPath(fromDirectory directory: DirectoryType = .document,
                              filepath: String) -> URL  {
        let fileURL = getDocumentPath(directory: directory).appendingPathComponent(StickerConstants.downloadedStickerPathExtention).appending(path: filepath + "/")
        return fileURL
    }
    
    func getDocumentPath(directory: DirectoryType) -> URL {
        switch directory {
        case .document:
            return documentPath
        case .library:
            return libraryPath
        }
    }
    
    func getDirectoryContent(directory: DirectoryType, filePath: String = StickerConstants.downloadedStickerPathExtention) -> [String] {
        let downloadedStickerURL = libraryPath.appendingPathComponent(filePath, isDirectory: true)
        do {
            let subpaths = try fileManager.contentsOfDirectory(at: downloadedStickerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles )
            return subpaths.map { $0.lastPathComponent }
        } catch {
            return []
        }
    }


    func removeStickersFor(fileName: String) throws {
        let downloadedStickerURL = libraryPath.appendingPathComponent(StickerConstants.downloadedStickerPathExtention, isDirectory: true)
        let dest = downloadedStickerURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: dest.path) {
           try FileManager.default.removeItem(at: dest)
        }
    }

}
