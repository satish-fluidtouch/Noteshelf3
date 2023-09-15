//
//  ThumbnailProvider.swift
//  Noteshelf3 Thumbnail
//
//  Created by Akshay on 12/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        NSLog("🌄 ✅ Thumbnail Fetch request for \(request.fileURL.path)")
        let thumbURL = request.fileURL.appendingPathComponent("cover-shelf-image.png")
        handler(QLThumbnailReply(imageFileURL: thumbURL), nil)
    }
}
