//
//  FTTaggedEntity.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTTagsType {
    case page, book
}

class FTTaggedEntity: NSObject, Identifiable {
    @objc dynamic private(set) var downloadStatus = FTDownloadStatus.notDownloaded {
        willSet {
            if newValue != downloadStatus {
                self.willChangeValue(forKey: "downloadStatus");
            }
        }
        didSet {
            if oldValue != downloadStatus {
                self.didChangeValue(forKey: "downloadStatus");
            }
        }
    }
    
    private var notificationObserver: NSObjectProtocol?;
    
    static func taggedEntity(_ documentID: String
                             , documentPath: String?
                             , pageID: String? = nil) -> FTTaggedEntity {
        let item: FTTaggedEntity
        if let _pageID = pageID {
            item = FTPageTaggedEntity(documentUUID: documentID
                                      , documentPath: documentPath
                                      , pageUUID: _pageID);
        }
        else {
            item = FTDocumentTaggedEntity(documentUUID: documentID, documentPath: documentPath);
        }
        return item;
    }

    var id = UUID().uuidString;

    private(set) var documentUUID: String
    var documentName: String {
        return relativePath?.lastPathComponent.deletingPathExtension ?? "";
    }
    
    var relativePath: String?;

    var tagType: FTTagsType {
        fatalError("subclass should override")
    };
    private(set) var tags = Set<FTTag>();

    init(documentUUID: String,documentPath: String?) {
        self.documentUUID = documentUUID;
        self.relativePath = documentPath;
        super.init()
        self.updateURLAndDownloadStatusLocally();
    }
    
    func thumbnail(onCompletion: ((UIImage?,String)->())?) -> String {
        fatalError("Subclass should override")
    }
    
    var thumbnailURL: URL {
        let thumbnailFolderPath = URL.thumbnailFolderURL();
        let documentPath = thumbnailFolderPath.appendingPathComponent(self.documentUUID);
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: documentPath.path(percentEncoded: false)
                                           , isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil);
        }
        return documentPath;
    }
    
    override var hash: Int {
        return self.documentUUID.hashKey.hash;
    }

    func addTag(_ tag: FTTag) {
        if !self.tags.contains(tag) {
            self.tags.insert(tag)
        }
    }
    
    func removeTag(_ tag: FTTag) {
        self.tags.remove(tag)
        if self.tags.isEmpty {
            FTTagsProvider.shared.removeTaggedEntityFromCache(self);
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? FTTaggedEntity else {
            return false;
        }
        return self.hash == other.hash
    }
    
    override var description: String {
        return super.description + ">>" + "Tag Name:- \(self.tags.map{$0.tagName})";
    }
    
    deinit {
        removeObserver();
    }
    
    func documentShelfItem(_ ifDownloaded: Bool = true, onCompletion: ((FTDocumentItemProtocol?)->())?) {
        FTNoteshelfDocumentProvider.shared.document(with: self.documentUUID
                                                    , orRelativePath: ifDownloaded ? nil : self.relativePath) { docItem in
            onCompletion?(docItem);
        }
    }
}

private extension FTTaggedEntity {
    func updateURLAndDownloadStatusLocally() {
        guard let relPath = self.relativePath
                ,let fileURL = FTTagsProvider.shared.rootDocumentsURL?.appending(path: relPath) else {
            return;
        }
        DispatchQueue.global(qos: .background).async {
            let downloadStatus = fileURL.downloadStatus();
            runInMainThread {
                self.downloadStatus = downloadStatus;
                if downloadStatus != .downloaded {
                    self.addObserver(fileURL);
                }
            }
        }
    }

    func removeObserver() {
        guard let obserbser = self.notificationObserver else {
            return;
        }
        NotificationCenter.default.removeObserver(obserbser)
        self.notificationObserver = nil;
    }
    
    func addObserver(_ path: URL) {
        guard nil == self.notificationObserver else {
            return;
        }
        self.notificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "FinishedDownload_\(path.hashKey)"),
                                                                           object: nil,
                                                                           queue: OperationQueue.main,
                                                                           using:
                                                                            { [weak self] (notification) in
            if let object = notification.object as? FTDocumentItem {
                if object.isDownloaded {
                    self?.downloadStatus = .downloaded;
                    self?.removeObserver();
                }
                else if object.isDownloading {
                    self?.downloadStatus = .downloading;
                }
            }
        })
    }
}
