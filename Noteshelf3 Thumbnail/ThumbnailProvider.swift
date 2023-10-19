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
        let coordinator = NSFileCoordinator(filePresenter: nil);
        var error: NSError?;
        coordinator.coordinate(readingItemAt: request.fileURL,
                               error: &error,
                               byAccessor: { readingURL in
            let thumbURL = readingURL.appendingPathComponent("cover-shelf-image.png")
            if let image = UIImage(contentsOfFile: thumbURL.path(percentEncoded: false)) {
                let maxsz = request.maximumSize;
                let r = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin:.zero, size:maxsz))
#if DEBUG
                NSLog("🌄 ✅✅✅ Thumbnail generated and sent modified at \(thumbURL.fileModificationDate) \(request.fileURL.path)")
#endif
                let reply = QLThumbnailReply(contextSize: r.size, currentContextDrawing: {
                    image.draw(in: CGRect(origin: .zero, size: r.size));
                    return true;
                })
                handler(reply, nil)
            }
            else {
#if DEBUG
                NSLog("🌄 🔴🔴 Thumbnail coverNotFound for \(request.fileURL.path) ")
#endif
                handler(nil,FTQLThumbnailError.coverNotFound);
            }
        })
        if let _error = error {
#if DEBUG
                NSLog("🌄 🔴🔴 Thumbnail coverNotFound for \(request.fileURL.path) ")
#endif
            handler(nil, _error);
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
