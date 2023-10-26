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
    func generateThumbnailForPdf(thumbnailName: String? = nil, size: CGSize = CGSize(width: 400, height: 400), completion: ((UIImage?) -> Void?)? = nil) {
        var thumbUrl: URL
        if let thumbnailName {
            thumbUrl = self.deletingLastPathComponent().appending(path: thumbnailName).appendingPathExtension("png")
        } else {
            thumbUrl = self.deletingPathExtension().appendingPathExtension("png")
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: self,
            size: size,
            scale: 1,
            representationTypes: .thumbnail)

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbImage = thumbnail?.uiImage {
                try? thumbImage.pngData()?.write(to: thumbUrl)
                completion?(thumbImage)
            } else {
                completion?(nil)
            }
        }
    }

    func generateThumbnailForTemplate(fileName: String? = nil) throws -> UIImage? {
        var fileURL = self.deletingPathExtension().appendingPathExtension("png")
        if let fileName {
            fileURL = fileURL.deletingLastPathComponent().appending(path: fileName).appendingPathExtension("png")
        }
        guard let document = PDFDocument(url: self) else { return nil }
        guard let page = document.page(at: 0) else { return nil }
        let pageBox = PDFDisplayBox.cropBox;
        let pageRect = page.bounds(for: pageBox)
        let thumbnailImage = page.thumbnail(of: pageRect.size, for: .cropBox)
        try thumbnailImage.pngData()?.write(to: fileURL)
        return thumbnailImage
    }

    func loadThumbnail() -> UIImage? {
        do {
            let imageData = try Data(contentsOf: self)
            let image = UIImage(data: imageData)
            return image
        } catch {
            return nil
        }
    }
}
