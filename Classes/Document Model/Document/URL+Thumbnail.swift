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
                                                   scale: 1.0,
                                                   representationTypes: .all)

        NSLog("🌄 Generating thumbnail for \(self.path)")
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbnail {
                NSLog("🌄 Thumbnail Fetched for \(self)")
                completion(thumbnail.uiImage)
            } else if let error {
                NSLog("🌄 Thumbnail Error \(error)")
                completion(nil)
            } else {
                NSLog("🌄 Thumbnail Unknown Error")
                completion(nil)
            }
        }
    }
}
