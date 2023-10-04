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
        NSLog("🌄 ✅ Thumbnail Fetch request for \(request.fileURL.path)")
#endif
        guard request.fileURL.downloadStatus() == .downloaded else {
            handler(nil,FTQLThumbnailError.notDownloaded.error);
            return;
        }
        let thumbURL = request.fileURL.appendingPathComponent("cover-shelf-image.png")
        let coordinator = NSFileCoordinator(filePresenter: nil);
        var error: NSError?;
        coordinator.coordinate(readingItemAt: thumbURL
                               , options: .immediatelyAvailableMetadataOnly
                               , error: &error
                               , byAccessor: { readingURL in
            if let image = UIImage(contentsOfFile: readingURL.path(percentEncoded: false)) {            
                let maxsz = request.maximumSize;
                let r = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin:.zero, size:maxsz))
                handler(QLThumbnailReply(contextSize: r.size, currentContextDrawing: {
                    image.draw(in: CGRect(origin: .zero, size: r.size));
                    return true;
                }),nil)
            }
            else {
                handler(nil,FTQLThumbnailError.coverNotFound.error);
            }
        })
        if let _error = error {
            handler(nil,_error);
        }
    }
}
