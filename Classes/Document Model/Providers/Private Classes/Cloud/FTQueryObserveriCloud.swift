//
//  FTQueryObserveriCloud.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTiCloudQueryObserverDelegate: AnyObject {
    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didFinishGathering results: [AnyObject]?);
    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didAddedItems results: [AnyObject]);
    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didUpdatedItems results: [AnyObject]);
    func ftiCloudQueryObserver(_ query: FTiCloudQueryObserver, didRemovedItems results: [AnyObject]);
}

class FTiCloudQueryObserver: FTQueryListenerProtocol {
    fileprivate var rootURLs: [URL]
    fileprivate var extsToListen: [String]
    fileprivate var query: NSMetadataQuery?
    fileprivate weak var delegate: FTiCloudQueryObserverDelegate?
    fileprivate var queryPaused = false

    //nil to root
    required init(rootURLs: [URL],
                  extensionsToListen exts: [String],
                  delegate: FTiCloudQueryObserverDelegate) {
        self.rootURLs = rootURLs.map{ $0.appendingPathComponent("Documents").urlByDeleteingPrivate() }

        self.extsToListen = exts;
        self.delegate = delegate;
    }

    deinit {
        self.stopQuery();

        #if DEBUG
            //print("deinit ☁️ Query Observer");
        #endif
    }

    func startQuery()
    {
        self.stopQuery();
        self.query = self.searchQuery();
        #if DEBUG
            //print("☁️ Query Started");
        #endif
        FTCLSLog("Provider -Initial Gather Started");
        NotificationCenter.default.addObserver(self, selector: #selector(FTiCloudQueryObserver.processiCloudFilesForInitialGathering(_:)), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil);
        self.query?.start();
    }

    func stopQuery()
    {
        self.query?.stop();
    }
    
    func isStarted() -> Bool {
        return self.query?.isStarted ?? false
    }
    
    func enableUpdates() {
        #if DEBUG
            //print("✅ Query Updates enabled")
        #endif
        self.query?.enableUpdates();
    }

    func disableUpdates() {
        #if DEBUG
            //print("🔴 Query Updates Disabled")
        #endif

        self.query?.disableUpdates();
    }

    // MARK: - Notifications
    @objc fileprivate func processiCloudFilesForInitialGathering(_ notification: Notification) {
        FTCLSLog("Provider -Initial Gather Ended");
        self.disableUpdates();

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil);

        // The query reports all files found, every time.
        if(self.delegate != nil) {
            self.delegate?.ftiCloudQueryObserver(self, didFinishGathering: self.query?.results as? [NSMetadataItem]);
        }

        //After initial gathering start observing for query results array for any changes

        NotificationCenter.default.addObserver(self, selector: #selector(FTiCloudQueryObserver.metaDataQueryDidUpdated(_:)), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: self.query);

        self.enableUpdates();
    }

    @objc fileprivate func metaDataQueryDidUpdated(_ notification: Notification)
    {
        self.disableUpdates();
        let itemsAdded = notification.userInfo![NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem];
        let itemsRemoved = notification.userInfo![NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem];
        let itemsChanged = notification.userInfo![NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem];

        if let itemsChanged, !itemsChanged.isEmpty, nil != self.delegate {
            self.delegate?.ftiCloudQueryObserver(self, didUpdatedItems: itemsChanged)
        }

        if let itemsRemoved, !itemsRemoved.isEmpty, nil != self.delegate {
            self.delegate?.ftiCloudQueryObserver(self, didRemovedItems: itemsRemoved)
        }

        if let itemsAdded, !itemsAdded.isEmpty, nil != self.delegate {
            self.delegate?.ftiCloudQueryObserver(self, didAddedItems: itemsAdded)
        }

        self.enableUpdates();
    }

    fileprivate func searchQuery() -> NSMetadataQuery {
        let query = NSMetadataQuery();
        // Search documents subdir only
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope];
        query.operationQueue = OperationQueue();
        query.operationQueue?.maxConcurrentOperationCount = 1;
        //        query.notificationBatchingInterval = 4;

        var predicateArray = [NSPredicate]();
        for eachExtension in self.extsToListen {
            let pattern = "*.\(eachExtension)"
            let  predicate = NSPredicate(format: "(%K Like %@)",
                                         NSMetadataItemFSNameKey, pattern)
            predicateArray.append(predicate)
        }
        query.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicateArray);
        return query;
    }

}
