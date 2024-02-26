//
//  FTCachedDocument.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCachedDocument: NSObject {
    private lazy var propertyPlist: FTFileItemPlist = {
        let url = self.cachedFileURL.appending(path: METADATA_FOLDER_NAME).appending(path: PROPERTIES_PLIST);
        return FTFileItemPlist(url: url, isDirectory: false)
    }()
    
    private lazy var documentPlist: FTNSDocumentInfoPlistItem = {
        let url = self.cachedFileURL.appending(path: DOCUMENT_INFO_FILE_NAME);
        return FTNSDocumentInfoPlistItem(url: url, isDirectory: false)
    }();
    
    private(set)  var documentUUID: String = UUID().uuidString;
    private var cachedFileURL: URL;
    
    convenience init(documentID: String) {
        let url = FTDocumentCache.shared.cachedLocation(for: documentID);
        self.init(fileURL: url)
        documentUUID = documentID;
    }
    
    required init(fileURL : Foundation.URL) {
        self.cachedFileURL = fileURL;
    }

    func documentTags() -> [String] {
        let tags = self.propertyPlist.contentDictionary["tags"] as? [String]
        return tags ?? [String]();
    }
    
    func pages() -> [FTPageProtocol] {
        return self.documentPlist.pages;
    }
    
    var relativePath: String? {
        if let relativePath = self.propertyPlist.contentDictionary["relativePath"] as? String {
            return relativePath;
        }
        return nil
    }
}

@objc extension FTCachedDocument: FTDocumentProtocol {
    var shelfImage: UIImage? {
        get { return nil }
        set {}
    }
    
    var hasNS1Content: Bool {
        get { return false }
        set {}
    }
    
    var isDirty: Bool {
        get { return false }
        set {}
    }
    
    var isJustCreatedWithQuickNote: Bool {
        get { return false }
        set {}
    }
    
    var undoManager: UndoManager {
        fatalError("class should implement this if needed");
    }
    
    var URL: URL {
        return self.cachedFileURL
    }
    
    var hasAnyUnsavedChanges: Bool {
        return false
    }
    
    var shouldGenerateCoverThumbnail: Bool {
        return false
    }
    
    var wasPinEnabled: Bool {
        get { return false }
        set {}
    }
    
    func isPinEnabled() -> Bool {
        return false;
    }
            
    var documentState: UIDocument.State {
        return .normal
    }
    
    var pdfOutliner: FTPDFOutliner? {
        return nil;
    }
    
    var localMetadataCache: FTDocumentLocalMetadataCacheProtocol? {
        return nil;
    }
    
    var thumbnailGenerator: FTThumbnailGenerator? {
        return nil;
    }
        
    func resetPageModificationStatus() {
        fatalError("class should implement this if needed");
    }
    //Doc insert/create
    func createDocument(_ info : FTDocumentInputInfo,onCompletion : @escaping  ((NSError?,Bool) -> Void)) {
        fatalError("class should implement this if needed");
    }
    
    func insertFile(_ info : FTDocumentInputInfo,onCompletion: @escaping ((NSError?, Bool) -> Void)) {
        fatalError("class should implement this if needed");
    }
    
    func updatePageTemplate(page : FTPageProtocol,info : FTDocumentInputInfo,onCompletion: @escaping ((NSError?, Bool) -> Void)) {
        fatalError("class should implement this if needed");
    }

    //Doc creation from selectedPages
    func createDocumentAtTemporaryURL(_ toURL : Foundation.URL,
                                      purpose: FTItemPurpose,
                                      fromPages : [FTPageProtocol],
                                      documentInfo: FTDocumentInputInfo?,
                                      onCompletion : @escaping ((Bool,NSError?) -> Void)) -> Progress {
        fatalError("class should implement this if needed");
    }

    //Doc insertion at index
    func insertDocumentAtURL(_ url : Foundation.URL,
                             atIndex : Int,
                             onCompletion : @escaping ((Bool,NSError?) -> Void)) -> Progress {
        fatalError("class should implement this if needed");
    }

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    @discardableResult func insertPageAbove(page: FTPageProtocol) -> FTPageProtocol? {
        fatalError("class should implement this if needed");
    }
    @discardableResult func insertPageBelow(page: FTPageProtocol) -> FTPageProtocol? {
        fatalError("class should implement this if needed");
    }
    @discardableResult func insertPageAtIndex(_ index : Int) -> FTPageProtocol? {
        fatalError("class should implement this if needed");
    }
    func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)?) {
        fatalError("class should implement this if needed");
    }
    func cancelAllThumbnailGeneration() {
        fatalError("class should implement this if needed");
    }
    #endif
    
    //Document Operation
    func saveDocument(completionHandler: ((Bool) -> Void)?) {
        fatalError("class should implement this if needed");
    }
}
