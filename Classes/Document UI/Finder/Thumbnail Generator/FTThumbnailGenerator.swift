//
//  FTThumbnailGenerator.swift
//  Noteshelf
//
//  Created by Akshay on 09/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
    static func pauseThumbnailGeneration(for uuid:String) -> Self {
        return Notification.Name(rawValue: "pauseThumbnailGeneration_for_"+uuid)
    }

    static func resumeThumbnailGeneration(for uuid:String) -> Self {
        return Notification.Name(rawValue: "resumeThumbnailGeneration_for_"+uuid)
    }
}

final class FTThumbnailGenerator: NSObject {

    let notificationObserverID : String = UUID().uuidString;
    private var requests = [FTThumbnailGenerationRequest]()
    private var currentRequest : FTThumbnailGenerationRequest?
    private var isPaused : Bool = false

    private var _thumnailRenderer : FTOffScreenRenderer?
    private lazy var thumbnailOffscreenRenderer : FTOffScreenRenderer = {
        let renderer = FTRendererProvider.shared.dequeOffscreenRenderer()
        _thumnailRenderer = renderer
        return renderer
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: .pauseThumbnailGeneration(for: self.notificationObserverID), object: nil, queue: nil) { [weak self] _ in
            self?.isPaused = true
        }
        NotificationCenter.default.addObserver(forName: .resumeThumbnailGeneration(for: self.notificationObserverID), object: nil, queue: nil) { [weak self] _ in
            self?.isPaused = false
            self?.startNextRequest()
        }
    }

    deinit {
        if let renderer = _thumnailRenderer {
           FTRendererProvider.shared.enqueOffscreenRenderer(renderer)            
        }
    }

    func generateThumbnail(for page:FTPageProtocol) {
        let previousrequests = thumbnailRequests(for: page)
        if previousrequests.isEmpty && currentRequest?.page?.uuid != page.uuid {
            let newRequest = FTThumbnailGenerationRequest(with: page, delegate: self)
            requests.append(newRequest)
            if currentRequest == nil {
                startNextRequest()
            }
        }
    }

    func cancelAllThumbnailGeneration() {
        requests.removeAll()
    }

    func cancelThumbnailGeneration(for page:FTPageProtocol) {
        requests.removeAll { request -> Bool in
            return request.page?.uuid == page.uuid
        }
    }
}

extension FTThumbnailGenerator: FTThumbnailGenerationRequestDelegate {
    func didCompleteRequest(_ request: FTThumbnailGenerationRequest) {
        startNextRequest()
    }
}

//MARK: Private
private extension FTThumbnailGenerator {
    func startNextRequest() {
        self.currentRequest = nil

        guard !self.isPaused else { return }

        if requests.isEmpty == false {
            currentRequest = requests.removeFirst()
            currentRequest?.execute(with: thumbnailOffscreenRenderer)
        }
    }

    func thumbnailRequests(for page: FTPageProtocol) -> [FTThumbnailGenerationRequest] {
        let requestsForPage = requests.filter { $0.page?.uuid == page.uuid }
        return requestsForPage
    }
}
