//
//  FTNBKZipFileImporter.swift
//  Noteshelf
//
//  Created by Amar on 26/03/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNBKZipFileImporter: NSObject {
    var progress = Progress();
    private var collection: FTShelfItemCollection
    private var parentShelfItem: FTGroupItemProtocol?
    
    init(shelfItemCollection: FTShelfItemCollection,group: FTGroupItemProtocol?) {
        collection = shelfItemCollection;
        parentShelfItem = group;
    }
    
    func performImport(_ item : FTImportItemZip,onCompletion: @escaping (Error?)->()) -> Progress {
        progress.totalUnitCount = Int64(item.items.count);
        if(item.items.isEmpty) {
            DispatchQueue.main.async {
                onCompletion(nil);
            }
        }
        else {
            progress.totalUnitCount = Int64(item.items.count);
            progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");
            self.execute(items: item.items, onCompletion: onCompletion);
        }
        return progress;
    }
    
    private func execute(items: [URL],onCompletion: @escaping (Error?)->()) {
        var _items = items;
        guard !_items.isEmpty else {
            onCompletion(nil);
            return;
        }
        let item = _items.removeFirst();
        let subProgress = self.startImportingBookAtPath(item,
                                      deleteSourceFile: true) {(error) in
            if let _error = error {
                onCompletion(_error);
            }
            else {
                self.execute(items: _items, onCompletion: onCompletion);
            }
        }
        self.progress.addChild(subProgress, withPendingUnitCount: 1);
    }
    
    private func startImportingBookAtPath(_ url : URL,
                                              deleteSourceFile : Bool,
                                              onCompletion : ((Error?) -> Void)?) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 100;
        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");
        
        DispatchQueue.main.async(execute: {
            let importer = FTNBKFormatImporter(url: url,
                                               collection: self.collection,
                                               group: self.parentShelfItem,
                                               shelfItem: nil);
            importer.deleteSourceFileOnCompletion = deleteSourceFile;
            importer.startImporting(onUpdate: { (progressValue) in
                progress.completedUnitCount = Int64(progressValue*100);
            }, onCompletion: { (error, _) in
                progress.completedUnitCount = 100;
                onCompletion?(error);
            })
        });
        return progress;
    }
}
