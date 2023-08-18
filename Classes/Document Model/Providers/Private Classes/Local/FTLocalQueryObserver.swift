//
//  FTQueryObserverLocal.swift
//  Noteshelf
//
//  Created by Amar on 23/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTLocalQueryGatherDelegate: AnyObject {
    func ftLocalQueryGather(_ query : FTLocalQueryGather,didFinishGathering results:[URL]?);
}

class FTLocalQueryGather {
    fileprivate var rootURL : URL;
    fileprivate var extToListen : [String] = [String]()
    fileprivate var skipSubFolder = true;
    
    fileprivate weak var delegate : FTLocalQueryGatherDelegate!;
    fileprivate var ns2ProdLocalURL: URL?

    init(rootURL: URL,
         extensionsToListen exts: [String],
         skipSubFolder : Bool,
         delegate: FTLocalQueryGatherDelegate,
         ns2ProdLocalURL: URL? = nil) {
        self.rootURL = rootURL;
        self.extToListen = exts;
        self.delegate = delegate;
        self.skipSubFolder = skipSubFolder;
        self.ns2ProdLocalURL = ns2ProdLocalURL
    }
    
    deinit
    {
        #if DEBUG
            debugPrint("FTQueryObserverLocal deinit");
        #endif
    }
    
    func startQuery()
    {
        var t1: TimeInterval!;
        var t2: TimeInterval!;
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            t1 = Date.timeIntervalSinceReferenceDate;
        }
        
        var urls = self.contentsOfURL(self.directoryURLToSearch(), skipsSubFolder: skipSubFolder);
        if let ns2ProdURL = self.ns2ProdLocalURL {
            urls.append(contentsOf:self.contentsOfURL(ns2ProdURL, skipsSubFolder: skipSubFolder))
        }
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            t2 = Date.timeIntervalSinceReferenceDate;
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Gathering : \(String(describing: self.rootURL)) time taken to gather:\(t2-t1)");
        }
        
        self.delegate.ftLocalQueryGather(self, didFinishGathering: urls);
        
        if(ENABLE_SHELF_RPOVIDER_LOGS) {
            let t3 = Date.timeIntervalSinceReferenceDate;
            debugPrint("\(#file.components(separatedBy: "/").last ?? ""): Processing : \(String(describing: self.rootURL)) time taken to process:\(t3-t2)");
        }
    }
    
    func stopQuery()
    {
        
    }
}

private extension FTLocalQueryGather {
    
    func directoryURLToSearch() -> URL
    {
        return self.rootURL;
    }
    
    func filterItemsMatchingExtensions(_ items : [URL]?) -> [URL]
    {
        var filteredURLS = [URL]();
        if let items {
            if(!self.extToListen.isEmpty) {
                filteredURLS = items.filter({ (eachURL) -> Bool in
                    if(self.extToListen.contains(eachURL.pathExtension)) {
                        return true
                    }
                    return false
                });
            }
        }
        return filteredURLS
    }

    func contentsOfURL(_ url: URL,skipsSubFolder: Bool) -> [URL] {
        let urls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                includingPropertiesForKeys: nil,
                                                                options: .skipsHiddenFiles);
        let filteredURLS = self.filterItemsMatchingExtensions(urls);
        
        var notebookUrlList: [URL] = [URL]()
        if(!skipsSubFolder) {
            filteredURLS.enumerated().forEach({ (_,eachURL) in
                if(eachURL.pathExtension == groupExtension) {
                    let dirContents = self.contentsOfURL(eachURL,skipsSubFolder: skipsSubFolder);
                    notebookUrlList.append(contentsOf: dirContents);
                }
                else {
                    notebookUrlList.append(eachURL);
                }
            });
        }
        else {
            notebookUrlList = filteredURLS;
        }
        return notebookUrlList
    }
}
