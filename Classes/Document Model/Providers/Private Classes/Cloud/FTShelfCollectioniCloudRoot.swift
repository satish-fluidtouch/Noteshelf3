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
        internal init(ns2booksMetadata: [NSMetadataItem], ns2ShelfsMetadata: [NSMetadataItem], ns3IndexMetadata: [NSMetadataItem], ns3booksMetadata: [NSMetadataItem], ns3ShelfsMetadata: [NSMetadataItem]) {
            self.ns2booksMetadata = ns2booksMetadata
            self.ns2ShelfsMetadata = ns2ShelfsMetadata
            self.ns3IndexMetadata = ns3IndexMetadata
            self.ns3booksMetadata = ns3booksMetadata
            self.ns3ShelfsMetadata = ns3ShelfsMetadata
        }

        let ns2booksMetadata: [NSMetadataItem]
        let ns2ShelfsMetadata: [NSMetadataItem]

        // NS3 Meta data items
        let ns3booksMetadata: [NSMetadataItem]
        let ns3ShelfsMetadata: [NSMetadataItem]
        let ns3IndexMetadata: [NSMetadataItem]

    }

    let ns3Collection: FTShelfCollectioniCloud
    let ns2Collection: FTShelfCollectioniCloud

    // FTMetadataCachingProtocol
    var listenerDelegate: FTQueryListenerProtocol?

    override init() {
        guard let icloudRootURL = FTNSiCloudManager.shared().iCloudRootURL() else {
            fatalError("iCloud Container not found")
        }

        // TODO: (AK) put identifier in a proper place
        guard let productionCloudURL = FileManager().url(forUbiquityContainerIdentifier: "iCloud.com.fluidtouch.noteshelf") else {
            fatalError("production Container not found")
        }
        //TODO: (AK) Think about a refactor for passing the Boolean or always compare the URL
        // Passing the boolean is a bit effective as we are injecting from the initializer
        self.ns3Collection = FTShelfCollectioniCloud(rootURL: icloudRootURL, isNS2Collection: false)
        self.ns2Collection = FTShelfCollectioniCloud(rootURL: productionCloudURL, isNS2Collection: true)

        super.init()
    }
}
// MARK: - FTMetadataCachingProtocol
extension FTShelfCollectioniCloudRoot: FTMetadataCachingProtocol {
    var canHandleAudio: Bool {
        false
    }
    
    func willBeginFetchingInitialData() {
        self.ns2Collection.willBeginFetchingInitialData()
        self.ns3Collection.willBeginFetchingInitialData()
    }
    
    func didEndFetchingInitialData() {
        self.ns2Collection.didEndFetchingInitialData()
        self.ns3Collection.didEndFetchingInitialData()
    }
    
    func addMetadataItemsToCache(_ metadataItems: [NSMetadataItem], isBuildingCache: Bool) {
        let metadata = filterAndUpdate(metadataItems: metadataItems)
        // NS2
        self.ns2Collection.addMetadataItemsToCache(metadata.ns2ShelfsMetadata, isBuildingCache: isBuildingCache)
        self.ns2Collection.addMetadataItemsToCache(metadata.ns2booksMetadata, isBuildingCache: isBuildingCache)
        self.ns2Collection.addMetadataItemsToCache(metadata.ns3IndexMetadata, isBuildingCache: isBuildingCache)

        // NS3
        self.ns3Collection.addMetadataItemsToCache(metadata.ns3ShelfsMetadata, isBuildingCache: isBuildingCache)
        self.ns3Collection.addMetadataItemsToCache(metadata.ns3booksMetadata, isBuildingCache: isBuildingCache)
    }
    
    func removeMetadataItemsFromCache(_ metadataItems: [NSMetadataItem]) {
        let metadata = filterAndUpdate(metadataItems: metadataItems)
        // NS2
        self.ns2Collection.removeMetadataItemsFromCache(metadata.ns2ShelfsMetadata)
        self.ns2Collection.removeMetadataItemsFromCache(metadata.ns2booksMetadata)
        self.ns2Collection.removeMetadataItemsFromCache(metadata.ns3IndexMetadata)

        // NS3
        self.ns3Collection.removeMetadataItemsFromCache(metadata.ns3ShelfsMetadata)
        self.ns3Collection.removeMetadataItemsFromCache(metadata.ns3booksMetadata)

    }
    
    func updateMetadataItemsInCache(_ metadataItems: [NSMetadataItem]) {
        let metadata = filterAndUpdate(metadataItems: metadataItems)
        // NS2
        self.ns2Collection.updateMetadataItemsInCache(metadata.ns2ShelfsMetadata)
        self.ns2Collection.updateMetadataItemsInCache(metadata.ns2booksMetadata)

        // NS3
        self.ns3Collection.updateMetadataItemsInCache(metadata.ns3ShelfsMetadata)
        self.ns3Collection.updateMetadataItemsInCache(metadata.ns3booksMetadata)
        self.ns3Collection.updateMetadataItemsInCache(metadata.ns3IndexMetadata)

    }
}


private extension FTShelfCollectioniCloudRoot {
    private func filterAndUpdate(metadataItems: [NSMetadataItem]) -> MetadataContainer {
        // NS2 Meta data items
        var ns2booksMetadata = [NSMetadataItem]()
        var ns2ShelfsMetadata = [NSMetadataItem]()

        // NS3 Meta data items
        var ns3booksMetadata = [NSMetadataItem]()
        var ns3ShelfsMetadata = [NSMetadataItem]()
        var ns3IndexMetadata = [NSMetadataItem]()

        for metadata in metadataItems {
            if ns2Collection.belongsToDocumentsFolder(metadata.URL()) {
                switch metadata.URL().pathExtension {
                case FTFileExtension.shelf:
                    ns2ShelfsMetadata.append(metadata)

                case FTFileExtension.ns2:
                    ns2booksMetadata.append(metadata)

                default:
                    debugLog("🌤️ Unhandled NS2 metadata item for \(metadata.URL().pathExtension)")
                }
            } else if ns3Collection.belongsToDocumentsFolder(metadata.URL()) {
                switch metadata.URL().pathExtension {
                case FTFileExtension.shelf:
                    ns3ShelfsMetadata.append(metadata)

                case FTFileExtension.ns3:
                    ns3booksMetadata.append(metadata)

                case FTFileExtension.sortIndex:
                    ns3IndexMetadata.append(metadata)

                default:
                    debugLog("🌤️ Unhandled NS3 metadata item for \(metadata.URL().pathExtension)")
                }
            } else {
                debugLog("🌤️ Neither NS2/NS3 metadata item for \(metadata.URL())")
            }
        }

        return MetadataContainer(ns2booksMetadata: ns2booksMetadata,
                                 ns2ShelfsMetadata: ns2ShelfsMetadata,
                                 ns3IndexMetadata: ns3IndexMetadata,
                                 ns3booksMetadata: ns3booksMetadata,
                                 ns3ShelfsMetadata: ns3ShelfsMetadata)
    }
}
