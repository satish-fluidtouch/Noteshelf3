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
    fileprivate var rootURL: URL;
    fileprivate var productionContainerURL: URL;
    fileprivate var extsToListen: [String];
    fileprivate var query: NSMetadataQuery?;
    fileprivate weak var delegate: FTiCloudQueryObserverDelegate?;
    fileprivate var queryPaused = false;

    var t1: TimeInterval = Date.timeIntervalSinceReferenceDate;

    //nil to root
    required init(rootURL: URL,
                  extensionsToListen exts: [String],
                  delegate: FTiCloudQueryObserverDelegate) {
        self.rootURL = rootURL.appendingPathComponent("Documents").urlByDeleteingPrivate()

        // TODO: (AK) put in a proper place
        guard let productionCloudURL = FileManager().url(forUbiquityContainerIdentifier: "iCloud.com.fluidtouch.noteshelf") else {
            fatalError("production Container not found")
        }

        self.productionContainerURL = productionCloudURL.appendingPathComponent("Documents").urlByDeleteingPrivate()

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
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            self.t1 = Date.timeIntervalSinceReferenceDate;
        }
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

        if(!self.queryPaused) {
            self.query?.enableUpdates();
        }
    }

    func disableUpdates() {
        #if DEBUG
            //print("🔴 Query Updates Disabled")
        #endif

        self.query?.disableUpdates();
    }

    func forceDisableUpdates() {
        #if DEBUG
            //print("🔴🔴🔴🔴 Force Query Updates disabled")
        #endif

        self.queryPaused = true;
        self.disableUpdates();
    }

    func forceEnableUpdates() {
        #if DEBUG
            //print("✅✅✅✅ Force Query Updates enabled")
        #endif

        self.queryPaused = false;
        self.enableUpdates();
    }

    // MARK: - Notifications
    @objc fileprivate func processiCloudFilesForInitialGathering(_ notification: Notification) {
        var t2: TimeInterval!;
        self.disableUpdates();

        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            t2 = Date.timeIntervalSinceReferenceDate;
            #if DEBUG
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Query: \(String(describing: self.rootURL)) time taken to gather:\(t2 - self.t1)");
            #endif
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil);

        // The query reports all files found, every time.
        if(self.delegate != nil) {
            self.delegate?.ftiCloudQueryObserver(self, didFinishGathering: self.query?.results as? [NSMetadataItem]);
        }
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            let t3 = Date.timeIntervalSinceReferenceDate;
             #if DEBUG
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Processing: \(String(describing: self.rootURL)) time taken to process:\(t3 - t2)");
            #endif
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
            let  predicate1 = NSPredicate(format: "(%K CONTAINS %@) AND (%K Like %@)",
                                          NSMetadataItemPathKey,
                                          self.rootURL.path,
                                          NSMetadataItemFSNameKey, pattern)
            predicateArray.append(predicate1);
            let  predicate2 = NSPredicate(format: "(%K CONTAINS %@) AND (%K Like %@)",
                                          NSMetadataItemPathKey,
                                          self.productionContainerURL.path,
                                          NSMetadataItemFSNameKey, pattern)
            
            predicateArray.append(predicate2);
        }
        query.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicateArray);
        return query;
    }

}
