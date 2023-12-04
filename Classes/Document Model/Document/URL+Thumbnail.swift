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
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { thumbnail, _, error in
            DispatchQueue.main.async {
                if let thumbnail {
                    completion(thumbnail.uiImage,error)
                } else if let error {
                    completion(nil,error)
                } else {
                    completion(nil,error)
                }
            }
        }
        return request;
    }
}
