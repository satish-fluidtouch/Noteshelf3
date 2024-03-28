//
//  FTCloudDocumentListener.swift
//  Noteshelf
//
//  Created by Akshay on 03/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon
import FTDocumentFramework

private let fileExtensionsToListen = [FTFileExtension.shelf,
                                      FTFileExtension.ns3,
                                      FTFileExtension.group,
                                      "m4a",
                                      "plist",
                                      FTFileExtension.sortIndex]

class FTCloudDocumentListener: FTDocumentListener {

    fileprivate var query: FTiCloudQueryObserver?
    fileprivate var listeners: [FTMetadataCachingProtocol]?

    fileprivate var tempCompletionBlock: (() -> Void)?

    required init(rootURLs: [URL]) {
        self.query = FTiCloudQueryObserver(rootURLs: rootURLs,
                                           extensionsToListen: fileExtensionsToListen,
                                           delegate: self);
    }

    deinit {
        listeners?.removeAll()
    }

    func addListener(_ listener: FTMetadataCachingProtocol) {
        if nil == self.listeners {
            self.listeners = [FTMetadataCachingProtocol]()
        }
        listener.listenerDelegate = self
        self.listeners?.append(listener)
    }

    func startQuery(onCompletion completion:@escaping (() -> Void)) {
        if let isStarted = query?.isStarted(), isStarted == true {
            completion()
        } else {
            query?.startQuery()
            guard let listeners = listeners else { return }
            for listener in listeners {
                listener.willBeginFetchingInitialData()
            }
            tempCompletionBlock = completion
        }
    }

    func stopQuery() {
        query?.stopQuery()
    }

    func enableUpdates() {
        query?.enableUpdates()
    }

    func disableUpdates() {
        query?.disableUpdates()
    }
}

// MARK: - FTiCloudQueryObserverDelegate
extension FTCloudDocumentListener: FTiCloudQueryObserverDelegate {

    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didFinishGathering results: [AnyObject]?) {

        guard let listeners = listeners, let items = results as? [NSMetadataItem] else { return }

        let audioMetadata = filterAudioRelatedFiles(with: items)

        for listener in listeners {
            if listener.canHandleAudio == true {
                listener.addMetadataItemsToCache(audioMetadata, isBuildingCache: true);
                listener.didEndFetchingInitialData()
            } else {
                listener.addMetadataItemsToCache(items, isBuildingCache: true)
                listener.didEndFetchingInitialData()
            }
        }

        //This should be called after
        if let initialCompletionBlok = tempCompletionBlock {
            initialCompletionBlok()
            tempCompletionBlock = nil
        }
    }

    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didAddedItems results: [AnyObject]) {

        guard let listeners = listeners, let items = results as? [NSMetadataItem] else { return }
        let audioMetadata = filterAudioRelatedFiles(with: items)

        for listener in listeners {
            if listener.canHandleAudio {
                listener.addMetadataItemsToCache(audioMetadata, isBuildingCache: false);
            } else {
                listener.addMetadataItemsToCache(items, isBuildingCache: false)
            }
        }
    }

    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didUpdatedItems results: [AnyObject]) {
        guard let listeners = listeners, let items = results as? [NSMetadataItem] else { return }

        let audioMetadata = filterAudioRelatedFiles(with: items)

        for listener in listeners {
            if listener.canHandleAudio {
                listener.updateMetadataItemsInCache(audioMetadata)
            } else {
                listener.updateMetadataItemsInCache(items)
            }
        }
    }

    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didRemovedItems results: [AnyObject]) {
        guard let listeners = listeners, let items = results as? [NSMetadataItem] else { return }
        let indexMetadata = filterIndexFiles(with: items)

        for listener in listeners {
            listener.removeMetadataItemsFromCache(items);
            listener.removeMetadataItemsFromCache(indexMetadata)
        }
    }
}

fileprivate extension FTCloudDocumentListener {

    func filterIndexFiles(with metadataItems: [NSMetadataItem]) -> [NSMetadataItem] {
        return metadataItems.filter({ $0.URL().pathExtension == FTFileExtension.sortIndex })
    }

    func filterAudioRelatedFiles(with metadataItems: [NSMetadataItem]?) -> [NSMetadataItem] {
        return metadataItems?.filter({
            $0.URL().deletingLastPathComponent().lastPathComponent == "Audio Recordings" &&
            ( $0.URL().pathExtension == "plist" || $0.URL().pathExtension == "m4a")
        }) ?? [NSMetadataItem]()
    }
}
