//
//  FTDocumentListener.swift
//  Noteshelf
//
//  Created by Akshay on 11/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTDocumentListener: FTQueryListenerProtocol {
    func addListener(_ listener: FTMetadataCachingProtocol)
}

protocol FTQueryListenerProtocol: AnyObject {

    func enableUpdates()
    func disableUpdates()
    //Should be used only for Force File operations
    func forceEnableUpdates()
    func forceDisableUpdates()
}

protocol FTMetadataCachingProtocol: AnyObject {
    var listenerDelegate: FTQueryListenerProtocol? { get set }
    var canHandleAudio: Bool { get }

    func willBeginFetchingInitialData()
    func didEndFetchingInitialData()
    func addMetadataItemsToCache(_ metadataItems: [NSMetadataItem], isBuildingCache: Bool)
    func removeMetadataItemsFromCache(_ metadataItems: [NSMetadataItem])
    func updateMetadataItemsInCache(_ metadataItems: [NSMetadataItem])
}
