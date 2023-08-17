//
//  URL+Addition.swift
//  TempletesStore
//
//  Created by Siva on 26/05/23.
//

import UIKit
import PDFKit
import FTCommon

extension URL {
    @discardableResult
    func generateThumbnailForFile(fileName: String? = nil) throws -> UIImage? {
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
}
