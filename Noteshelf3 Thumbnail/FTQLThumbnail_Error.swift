//
//  FTQLThumbnail_Error.swift
//  Noteshelf3 Thumbnail
//
//  Created by Amar Udupa on 03/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let FTQLDomain = "FTNSQuickLookThumbnail";

enum FTQLThumbnailError: Int {
    case notDownloaded, coverNotFound
    
    var error: NSError {
        switch self {
        case .notDownloaded:
            return NSError(domain: FTQLDomain, code: 101,userInfo: [NSLocalizedDescriptionKey: "book not downloaded yet"])
        case .coverNotFound:
            return NSError(domain: FTQLDomain, code: 102,userInfo: [NSLocalizedDescriptionKey: "cover image did not found"])
        }
    }
}
