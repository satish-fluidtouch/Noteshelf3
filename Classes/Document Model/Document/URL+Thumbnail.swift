//
//  URL+Thumbnail.swift
//  Noteshelf3
//
//  Created by Akshay on 12/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
import QuickLookThumbnailing
import UniformTypeIdentifiers

extension URL {
    func fetchQLThumbnail(completion: @escaping ((UIImage?) -> Void)) {
        let request = QLThumbnailGenerator.Request(fileAt: self,
                                                   size: portraitCoverSize,
                                                   scale: 2,
                                                   representationTypes: .thumbnail)
#if DEBUG
        NSLog("🌄 Generating thumbnail for \(self.path)")
#endif

        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbnail {
#if DEBUG
                NSLog("🌄 Thumbnail Fetched for \(self)")
#endif
                completion(thumbnail.uiImage)
            } else if let error {
#if DEBUG
                NSLog("🌄 Thumbnail Error \(error)")
#endif
                completion(nil)
            } else {
#if DEBUG
                NSLog("🌄 Thumbnail Unknown Error")
#endif
                completion(nil)
            }
        }
    }
}
