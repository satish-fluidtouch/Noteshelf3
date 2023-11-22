//
//  FTShelfCollectioniCloudRoot.swift
//  Noteshelf3
//
//  Created by Akshay on 24/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

final class FTShelfCollectioniCloudRoot: NSObject {
    private class MetadataContainer {
        internal init(ns3IndexMetadata: [NSMetadataItem], ns3booksMetadata: [NSMetadataItem], ns3ShelfsMetadata: [NSMetadataItem], ns3groupsMetadata: [NSMetadataItem]) {
            self.ns3IndexMetadata = ns3IndexMetadata
            self.ns3booksMetadata = ns3booksMetadata
            self.ns3ShelfsMetadata = ns3ShelfsMetadata
            self.ns3groupsMetadata = ns3groupsMetadata
        }

        // NS3 Meta data items
        let ns3booksMetadata: [NSMetadataItem]
        let ns3ShelfsMetadata: [NSMetadataItem]
        let ns3IndexMetadata: [NSMetadataItem]
        let ns3groupsMetadata: [NSMetadataItem]
    }

    let ns3Collection: FTShelfCollectioniCloud?
    // FTMetadataCachingProtocol
    weak var listenerDelegate: FTQueryListenerProtocol? {
        didSet {
            self.ns3Collection?.listenerDelegate = listenerDelegate;
        }
    }

    override init() {
        if let icloudRootURL = FTNSiCloudManager.shared().iCloudRootURL()  {
            self.ns3Collection = FTShelfCollectioniCloud(rootURL: icloudRootURL)
        } else {
            self.ns3Collection = nil
        }
        super.init()
    }
}

// MARK: - FTMetadataCachingProtocol
extension FTShelfCollectioniCloudRoot: FTMetadataCachingProtocol {
    var canHandleAudio: Bool {
        false
    }
    
    func willBeginFetchingInitialData() {
        self.ns3Collection?.willBeginFetchingInitialData()
    }
    
    func didEndFetchingInitialData() {
        self.ns3Collection?.didEndFetchingInitialData()
    }
    
    func addMetadataItemsToCache(_ metadataItems: [NSMetadataItem], isBuildingCache: Bool) {
        let metadata = filterAndUpdate(metadataItems: metadataItems)
        // NS3
        self.ns3Collection?.addMetadataItemsToCache(metadata.ns3ShelfsMetadata, isBuildingCache: isBuildingCache)
        self.ns3Collection?.addMetadataItemsToCache(metadata.ns3booksMetadata, isBuildingCache: isBuildingCache)
        self.ns3Collection?.addMetadataItemsToCache(metadata.ns3IndexMetadata, isBuildingCache: isBuildingCache)
        self.ns3Collection?.addMetadataItemsToCache(metadata.ns3groupsMetadata, isBuildingCache: isBuildingCache)
    }
    
    func removeMetadataItemsFromCache(_ metadataItems: [NSMetadataItem]) {
        let metadata = filterAndUpdate(metadataItems: metadataItems)
        // NS3
        self.ns3Collection?.removeMetadataItemsFromCache(metadata.ns3ShelfsMetadata)
        self.ns3Collection?.removeMetadataItemsFromCache(metadata.ns3booksMetadata)
        self.ns3Collection?.removeMetadataItemsFromCache(metadata.ns3IndexMetadata)
        self.ns3Collection?.removeMetadataItemsFromCache(metadata.ns3groupsMetadata)
    }
    
    func updateMetadataItemsInCache(_ metadataItems: [NSMetadataItem]) {
        let metadata = filterAndUpdate(metadataItems: metadataItems)
        // NS3
        self.ns3Collection?.updateMetadataItemsInCache(metadata.ns3ShelfsMetadata)
        self.ns3Collection?.updateMetadataItemsInCache(metadata.ns3booksMetadata)
        self.ns3Collection?.updateMetadataItemsInCache(metadata.ns3IndexMetadata)
        self.ns3Collection?.updateMetadataItemsInCache(metadata.ns3groupsMetadata)
    }
}


private extension FTShelfCollectioniCloudRoot {
    private func filterAndUpdate(metadataItems: [NSMetadataItem]) -> MetadataContainer {

        // NS3 Meta data items
        var ns3booksMetadata = [NSMetadataItem]()
        var ns3ShelfsMetadata = [NSMetadataItem]()
        var ns3IndexMetadata = [NSMetadataItem]()
        var ns3groupsMetadata = [NSMetadataItem]()

        for metadata in metadataItems {
            if ns3Collection?.belongsToDocumentsFolder(metadata.URL()) == true {
                switch metadata.URL().pathExtension {
                case FTFileExtension.shelf:
                    ns3ShelfsMetadata.append(metadata)

                case FTFileExtension.ns3:
                    ns3booksMetadata.append(metadata)
                    
                case FTFileExtension.group:
                    ns3groupsMetadata.append(metadata)

                case FTFileExtension.sortIndex:
                    ns3IndexMetadata.append(metadata)

                default:
                    debugLog("🌤️ Unhandled NS3 metadata item for \(metadata.URL().pathExtension)")
                }
            } else {
                debugLog("🌤️ Neither NS2/NS3 metadata item for \(metadata.URL())")
            }
        }

        return MetadataContainer(ns3IndexMetadata: ns3IndexMetadata,
                                 ns3booksMetadata: ns3booksMetadata,
                                 ns3ShelfsMetadata: ns3ShelfsMetadata,
                                 ns3groupsMetadata: ns3groupsMetadata)
    }
}
