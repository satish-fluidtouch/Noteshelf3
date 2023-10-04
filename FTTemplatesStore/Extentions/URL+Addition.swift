//
//  URL+Addition.swift
//  TempletesStore
//
//  Created by Siva on 26/05/23.
//

import UIKit
import QuickLook
import FTCommon

extension URL {
    func generateThumbnailForPdf(thumbnailName: String? = nil, completion: ((UIImage?) -> Void?)? = nil) {
        var thumbUrl: URL
        if let thumbnailName {
            thumbUrl = self.deletingLastPathComponent().appending(path: thumbnailName).appendingPathExtension("png")
        } else {
            thumbUrl = self.deletingPathExtension().appendingPathExtension("png")
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: self,
            size: CGSize(width: 400, height: 400),
            scale: 1,
            representationTypes: .thumbnail)

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbImage = thumbnail?.uiImage {
                try? thumbImage.pngData()?.write(to: thumbUrl)
                completion?(thumbImage)
            }
        }

    }

    func loadThumbnail( completion: @escaping (UIImage?) -> Void) {
        do {
            let imageData = try Data(contentsOf: self)
           let image = UIImage(data: imageData)
            completion(image)
        } catch {
            completion(nil)
        }
    }
}
