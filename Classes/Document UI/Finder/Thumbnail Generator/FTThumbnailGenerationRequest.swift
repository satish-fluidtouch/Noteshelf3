//
//  FTThumbnailGenerationRequest.swift
//  Noteshelf
//
//  Created by Akshay on 09/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didFinishGeneratingThumbnail = Notification.Name(rawValue: "FTDidFinishGeneratingThumbnail")
}

protocol FTThumbnailGenerationRequestDelegate: AnyObject {
    func didCompleteRequest(_ request:FTThumbnailGenerationRequest)
}

let THUMBNAIL_SIZE = CGSize(width:200,height:248)

final class FTThumbnailGenerationRequest {
    weak var page: FTPageProtocol?
    weak var delegate: FTThumbnailGenerationRequestDelegate?

    init(with page: FTPageProtocol, delegate: FTThumbnailGenerationRequestDelegate) {
        self.page = page
        self.delegate = delegate
    }
    func execute(with offScreenRenderer:FTOffScreenRenderer) {
        DispatchQueue.global().async { [weak self] in
            guard let pageTobeUsed = self?.page else { return }
            let thumbnailUpdatedDate = Date(timeIntervalSinceReferenceDate: pageTobeUsed.lastUpdated.doubleValue)
            FTPDFExportView.snapshot(forPage: pageTobeUsed,
                                     size: THUMBNAIL_SIZE,
                                     screenScale: UIScreen.main.scale,
                                     offscreenRenderer: offScreenRenderer,
                                     purpose:FTSnapshotPurposeThumbnail,
                                     windowHash: nil,
                                     onCompletion:{ (generatedImage, page) in
                                        DispatchQueue.main.async {
                                            var userInfo: [String:Any]?
                                            if let image = generatedImage {
                                                userInfo = ["image":image, "updatedDate":thumbnailUpdatedDate]
                                            }
                                            NotificationCenter.default.post(name: .didFinishGeneratingThumbnail, object: page, userInfo:userInfo)
                                            self?.page?.unloadContents()
                                            if let strongSelf = self {
                                                self?.delegate?.didCompleteRequest(strongSelf)
                                            }
                                            
                                        }
            })
        }
    }
}
