//
//  ThumbnailProvider.swift
//  Noteshelf3 Thumbnail
//
//  Created by Amar Udupa on 19/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import QuickLookThumbnailing
import AVFoundation

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
#if DEBUG
        NSLog("🌄 🌎🌎🌎 Thumbnail Fetch request for \(request.fileURL.path)")
#endif
        guard request.fileURL.downloadStatus() == .downloaded else {
            handler(nil,FTQLThumbnailError.notDownloaded);
            return;
        }

        var nsError: NSError?
        
        NSFileCoordinator().coordinate(readingItemAt: request.fileURL, options: .immediatelyAvailableMetadataOnly, error: &nsError) { readingURL in
            self.URLBasedResponse(readingURL, handler: handler);
//            self.contextBasedResponse(readingURL, handler: handler);
        }
        if let error = nsError {
#if DEBUG
                NSLog("🌄 🔴🔴 Thumbnail coverNotFound for \(request.fileURL.path) ")
#endif
            handler(nil, error)
        }
    }

#if DEBUG
    func storeintempDirectory(uiImage: UIImage) {
        let temp = URL(fileURLWithPath: "/Users/akshay/Desktop/Logo/").appendingPathComponent("thumb.png")
        try? FileManager.default.removeItem(at: temp)
        if let imageData = uiImage.pngData() {
            do {
                // Write the image data to the specified file URL
                try imageData.write(to: temp)
                // Image successfully saved to the file
                NSLog("🌄 ✅✅✅ Image saved to \(temp.absoluteString)")
            } catch {
                // Handle any errors that occur during file writing
                NSLog("🌄 🔴🔴 Error saving image: \(error.localizedDescription)")
            }
        }
    }
#endif
}

private extension ThumbnailProvider {
    func URLBasedResponse(_ packageURL: URL, handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        guard let tempPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
#if DEBUG
            NSLog("🌄 🔴🔴 Thumbnail coverNotFound for \(packageURL.path) ")
#endif
            handler(nil, FTQLThumbnailError.coverNotFound)
            return;
        }
        
        let thumbURL = packageURL.appendingPathComponent("cover-shelf-image.png")
        let cache = packageURL.path(percentEncoded: false).hashValue;
        let pathToCopy = URL(filePath: tempPath).appending(path: "\(cache).png");
        do {
            let fileManager = FileManager()
            try? fileManager.removeItem(at: pathToCopy);
            try fileManager.copyItem(at: thumbURL, to: pathToCopy);
            
//#if DEBUG
//            NSLog("🌄 ✅✅✅ Thumbnail generated and sent modified at \(thumbURL.fileModificationDate) \(packageURL.path)")
//#endif
            let reply = QLThumbnailReply(imageFileURL: pathToCopy);
            handler(reply, nil)
        }
        catch {
#if DEBUG
            NSLog("🌄 🔴🔴 Thumbnail coverNotFound for \(packageURL.path) ")
#endif
            handler(nil, error)
        }
    }
    
    func contextBasedResponse(_ packageURL: URL, handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let thumbURL = packageURL.appendingPathComponent("cover-shelf-image.png")
        if let image = UIImage(contentsOfFile: thumbURL.path(percentEncoded: false)) {
            let r = CGRect(origin: .zero, size: image.size)
//#if DEBUG
//            NSLog("🌄 ✅✅✅ Thumbnail generated and sent modified at \(thumbURL.fileModificationDate) \(packageURL.path)")
//#endif
            let reply = QLThumbnailReply(contextSize: r.size, currentContextDrawing: {
                image.draw(in: CGRect(origin: .zero, size: r.size));
                return true;
            })
            handler(reply, nil)
        }
        else {
#if DEBUG
            NSLog("🌄 🔴🔴 Thumbnail coverNotFound for \(packageURL.path) ")
#endif
            handler(nil,FTQLThumbnailError.coverNotFound);
        }
    }
}

