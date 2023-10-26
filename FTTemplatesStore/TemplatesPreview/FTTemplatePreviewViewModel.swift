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
        try url.generateThumbnailForTemplate()
        return url
    }

    private func downloadTemplateFromServer(style: FTTemplateStyle) async throws -> URL {
        guard let templa = template as? DiscoveryItem else {
            throw TemplateDownloadError.InvalidTemplate
        }

        let url = style.pdfDownloadUrl(template: templa)
        let dest = style.thumbnailPath()

        // VersionItem
        let versionItem = FTTemplateVerionItem(version: style.version, templateName: style.pdfPath().deletingPathExtension().lastPathComponent)
        let shouldReDownlload = try FTStoreTemplatesVersionHandler.shared.allowToReDownload(item: versionItem)
        if !FileManager.default.fileExists(atPath: dest.path) || shouldReDownlload {
           let pdfUrl = try await self.storeServiceApi.downloadTemplateFor(url: url)
            if FileManager.default.fileExists(atPath: style.thumbnailPath().path) {
                try FileManager.default.removeItem(at: style.thumbnailPath())
            }
            try FTStoreTemplatesVersionHandler.shared.updateVersionPlistWith(item: versionItem)
            return pdfUrl
        } else {
            return dest
        }
    }
}
