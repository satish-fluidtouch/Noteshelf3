//
//  FTShareManager.swift
//  Noteshelf3
//
//  Created by Narayana on 01/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShareCoordinator: NSObject {
    private let shelfItems: [FTShelfItemProtocol]
    private let pages: [FTPageProtocol]?
    private let sourceView: Any?
    private var exportManager: FTExportProgressManager?

    weak var presentingVc: UIViewController!

    init(shelfItems: [FTShelfItemProtocol], pages: [FTPageProtocol]? = [], presentingController: UIViewController, sourceView: Any? = nil) {
        self.shelfItems = shelfItems
        self.pages = pages
        self.presentingVc = presentingController
        self.sourceView = sourceView
        super.init()
        self.addObservers()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.sceneWillEnterForeground,
                                               object: self,
                                               queue: OperationQueue.main,
                                               using:
                                                { [weak self] (_) in
            self?.exportManager?.resumeExportOperation()
        })

        NotificationCenter.default.addObserver(forName: UIApplication.sceneDidEnterBackground,
                                               object: self,
                                               queue: OperationQueue.main,
                                               using:
                                                { [weak self] (_) in
            self?.exportManager?.pauseExportOperation()
        })
    }

    private func handleBooksShare(using properties: FTExportProperties) {
        var itemsToExport = [FTItemToExport]()
        shelfItems.forEach({ (eachItem) in
            let item = FTItemToExport(shelfItem: eachItem)
            itemsToExport.append(item)
        })

        if !itemsToExport.isEmpty {
            let target = FTExportTarget()
            target.itemsToExport = itemsToExport
            target.properties = properties
            self.handleShareUsing(target: target)
        }
    }

    private func handlePagesShare(using properties: FTExportProperties,type: FTShareType,option: FTShareOption) {
        let target = FTExportTarget()
        if self.shelfItems.count == 1, let reqItem = self.shelfItems.first {
            let item = FTItemToExport(shelfItem: reqItem)
            target.itemsToExport = [item]
            target.pages = self.pages
            if let page = self.pages?.first as? FTNoteshelfPage , let notebook = page.parentDocument {
                target.notebook = notebook
            }
            target.properties = properties
            target.pagesaveType = type
            target.shareOption = option
            self.handleShareUsing(target: target)
        }
    }

    private func handleShareUsing(target: FTExportTarget) {
        let exportManager = FTExportProgressManager()
        exportManager.exportTarget = target
        if let source = self.sourceView {
            exportManager.targetShareButton = source
        }
        exportManager.delegate = self
        exportManager.startExportingProcess(onViewController: presentingVc)
        self.exportManager = exportManager
    }
}

extension FTShareCoordinator {
    func beginShare(_ properties: FTExportProperties, option: FTShareOption,type:FTShareType) {
        if option == .notebook {
            self.handleBooksShare(using: properties)
        } else {
            self.handlePagesShare(using: properties,type: type, option: option)
        }
    }
}

extension FTShareCoordinator: FTExportActivityDelegate {
    public func didEndExport(withMessage message: String!) {
        endExportWith(true)
    }

    public func didFailExportWithError(_ error: Error!, withMessage message: String!) {
        endExportWith(false)
    }

    public func didCancelExport() {
        endExportWith(false)
    }

    func exportActivity(_ manager: FTExportActivityManager, didExportWith mode: RKExportMode) {
        endExportWith(true)
    }

    func exportActivity(_ manager: FTExportActivityManager, didFailWith error: Error, mode: RKExportMode) {
    }

    func exportActivity(_ manager: FTExportActivityManager, didCancelWith mode: RKExportMode) {
    }

    private func endExportWith(_ success: Bool) {
        self.exportManager = nil
        do {
            let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
            let tempFileLoc = (cacheDirectory)! + "/TEMP_CACHE_DIR"
            try FileManager.default.removeItem(atPath: tempFileLoc)
        }
        catch {
            FTCLSLog("FTSharing failed due to \(error.localizedDescription)")
        }
    }
}
