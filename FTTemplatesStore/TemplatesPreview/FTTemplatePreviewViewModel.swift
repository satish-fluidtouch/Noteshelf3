//
//  FTTemplatePreviewViewModel.swift
//  TempletesStore
//
//  Created by Siva on 01/03/23.
//

import Foundation
import Combine
import PDFKit
import FTCommon

enum TemplateDownloadError: Error {
    case InvalidTemplate
}

class FTTemplatePreviewViewModel: ObservableObject {
    private let storeServiceApi: FTStoreServiceApi
    private let templateCache: FTTemplatesCacheService
    var template: TemplateInfo!
    var thumbnailSize: CGSize = CGSize(width: 400, height: 400)
    init(storeServiceApi: FTStoreServiceApi = FTStoreService(), templatesCache: FTTemplatesCacheService = FTTemplatesCache()) {
        self.storeServiceApi = storeServiceApi
        self.templateCache = templatesCache
    }

    func downloadTemplateFor(style: FTTemplateStyle) async throws -> URL {
        let url = try await downloadTemplateFromServer(style: style)
        return url
    }

    private func downloadTemplateFromServer(style: FTTemplateStyle) async throws -> URL {
        guard let templa = template as? DiscoveryItem else {
            throw TemplateDownloadError.InvalidTemplate
        }

        let url = style.pdfDownloadUrl(template: templa)
        let thumbnailPath = style.thumbnailPath()
        
        let pdfPath = style.pdfPath()
        //remove thumb from templates folder
        let defaultFileManager = FileManager();
        let thumbpath = pdfPath.deletingLastPathComponent().appending(path:thumbnailPath.lastPathComponent);
        try? defaultFileManager.removeItem(at: thumbpath);

        let currentVersion: Int = pdfPath.templateVersion;
        let shouldReDownlload = currentVersion != style.version;

        if !defaultFileManager.fileExists(atPath: pdfPath.path) || shouldReDownlload {
           var pdfUrl = try await self.storeServiceApi.downloadTemplateFor(url: url)
            if defaultFileManager.fileExists(atPath: style.thumbnailPath().path) {
                try defaultFileManager.removeItem(at: style.thumbnailPath())
            }
            pdfUrl.templateVersion = style.version;
            try pdfUrl.generateThumbnailForTemplate()
            return thumbnailPath
        } else if !defaultFileManager.fileExists(atPath: thumbnailPath.path) {
            try pdfPath.generateThumbnailForTemplate()
            return thumbnailPath
        }
        else {
            return thumbnailPath
        }
    }
}

extension URL {
    var templateVersion: Int {
        set {
            let versionKey = FileAttributeKey(rawValue: "version")
            let value = FileAttributeKey.ExtendedAttribute(key: versionKey, string: "\(newValue)");
            try? self.setExtendedAttributes(attributes: [value]);
        }
        get {
            var curVersion: Int = 1;
            let versionKey = FileAttributeKey(rawValue: "version")
            if let versionStr = self.getExtendedAttribute(for: versionKey)?.stringValue,
            let intValue = Int(versionStr) {
                curVersion = intValue;
            }
            return curVersion;
        }
    }
}
