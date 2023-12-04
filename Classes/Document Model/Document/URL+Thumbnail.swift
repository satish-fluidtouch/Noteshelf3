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
    func fetchQLThumbnail(completion: @escaping ((UIImage?,Error?) -> Void)) -> QLThumbnailGenerator.Request {
        let request = QLThumbnailGenerator.Request(fileAt: self,
                                                   size: CGSize(width: 300, height: 300),
                                                   scale: 2,
                                                   representationTypes: .thumbnail)
#if DEBUG
        NSLog("🌄 Requesting thumbnail for \(self.path)")
#endif

        NSLog("called: \(self.path())");
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            DispatchQueue.main.async {
                NSLog("called respinde: \(self.path())");
                if let thumbnail {
#if DEBUG
                    NSLog("🌄 Thumbnail Fetched for \(self)")
#endif
                    completion(thumbnail.uiImage,error)
                } else if let error {
#if DEBUG
                    NSLog("🌄 Thumbnail Error \(error)")
#endif
                    completion(nil,error)
                } else {
#if DEBUG
                    NSLog("🌄 Thumbnail Unknown Error")
#endif
                    completion(nil,error)
                }
            }
        }
        return request;
    }
}
