//
//  FTNoteshelfDocument_Finder.swift
//  Noteshelf
//
//  Created by Amar on 1/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTNoteshelfDocument : FTThumbnailableCollection {
    func documentPages() -> [FTThumbnailable]
    {
        if let documentInfoPlist = self.documentInfoPlist() {
            return documentInfoPlist.pages as? [FTThumbnailable] ?? [FTThumbnailable]();
        }
        else {
            return [FTThumbnailable]();
        }
    }
    
    func deletePages(_ pages: [FTThumbnailable])
    {
        guard let nsPages = pages as? [FTNoteshelfPage] else {
            return;
        }
        if let documentInfoPlist = self.documentInfoPlist() {
            let pagesInOrder = nsPages.sorted { (page1, page2) -> Bool in
                return page1.pageIndex() > page2.pageIndex();
            }
            documentInfoPlist.deletePages(pagesInOrder);
        }
    }
    
    func duplicatePages(_ pages: [FTThumbnailable], onCompletion: @escaping ([FTThumbnailable]?) -> Void) -> Progress
    {
        let progress = Progress.init();
        progress.totalUnitCount = Int64(pages.count);
        
        DispatchQueue.main.async {
            let pagesToCopy : [FTPageProtocol] = pages as! [FTNoteshelfPage];
            _ = self.recursivelyCopyPages(pagesToCopy,
                                          currentPageIndex: 0,
                                          startingInsertIndex: 0,
                                          pageInsertPosition: .nextToCurrent,
                                          onCompletion: { (_, error,copiedPages) in
                if(nil == error) {
                    onCompletion(copiedPages as? [FTNoteshelfPage]);
                }
            });
        };
        return progress;
    }
    
    func movePages(_ pages: [FTThumbnailable], toIndex: Int)
    {
        let documentInfoPlist = self.documentInfoPlist();
        if(nil != documentInfoPlist) {
            let pagesArray = pages.map { eachPage in
                return eachPage as! FTNoteshelfPage
            }
            documentInfoPlist!.movePages(pagesArray, toIndex: toIndex)
        }
    }
    
    func movePages(_ pages : [FTThumbnailable],
                   toDocument : URL,
                   pin: String?,
                   onCompletion : @escaping (Error?) -> Void) -> Progress
    {
        let progress = Progress.init();
        progress.totalUnitCount = Int64(pages.count);
        
        let request = FTDocumentOpenRequest(url: toDocument, purpose: .write);
        request.pin = pin;
        FTNoteshelfDocumentManager.shared.openDocument(request: request) { (tokenID, document, error) in
            if let toDoc = document as? FTNoteshelfDocument,
               let pagesToCopy = pages as? [FTNoteshelfPage] {
                toDoc.saveDocument(completionHandler: { (success) in
                    _ = toDoc.recursivelyCopyPages(pagesToCopy,
                                                   currentPageIndex: 0,
                                                   startingInsertIndex: 0,
                                                   pageInsertPosition: .atTheEnd,
                                                   onCompletion:
                                                    { (_, error,_) in
                        FTNoteshelfDocumentManager.shared.closeDocument(document: toDoc, token: tokenID) { (success) in
                            if(nil == error) {
                                self.deletePages(pages);
                                self.saveDocument(completionHandler: { (success) in
                                    onCompletion(nil);
                                });
                            }
                            else {
                                onCompletion(error);
                            }
                        }
                    });
                });
            }
            else {
                var docError = error;
                if(nil == docError) {
                    docError = FTDocumentTemplateImportErrorCode.error(.openFailed);
                }
                runInMainThread {
                    onCompletion(docError);
                }
            }
        }

        NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self);
        return progress;
    }

    func documentTags() -> [String] {
        if let documentInfoPlist = self.propertyInfoPlist() {
            if let tags = documentInfoPlist.object(forKey: DOCUMENT_TAGS_KEY) as? [String] {
                return Array(Set(tags))
            }
        }
        return []
    }

    func addTag(_ tag : String) {
        var tags = self.documentTags()
        tags.append(tag)
        self.updateDocumentTags(tags: tags)
    }

    func addTags(tags: [String]) {
        self.updateDocumentTags(tags: tags)
    }

    func deleteTags(_ tags : [String]) {
        var docTags = self.documentTags()
        tags.forEach { tag in
            let index = docTags.firstIndex(where: {$0 == tag})
            if let idx = index {
                docTags.remove(at: idx)
                self.updateDocumentTags(tags: docTags)
            }
        }

        self.pages().forEach { page in
            tags.forEach { tag in
                (page as? FTNoteshelfPage)?.removeTag(tag)
            }
        }
        
    }

    // This will remove tags from document
    func removeTags(_ tags : [String]) async {
        var docTags = self.documentTags()
        tags.forEach { tag in
            let index = docTags.firstIndex(where: {$0 == tag})
            if let idx = index {
                docTags.remove(at: idx)
                self.updateDocumentTags(tags: docTags)
            }
        }
    }

    func removeAllTags() async {
        self.updateDocumentTags(tags: [])
    }

    func renameTag(_ tag : String, with newTag: String) {
        var docTags = self.documentTags()
        let index = docTags.firstIndex(where: {$0 == tag})
        if let idx = index {
            docTags.remove(at: idx)
            docTags.append(newTag)
            self.updateDocumentTags(tags: docTags)
        }

        self.pages().forEach { page in
            (page as? FTNoteshelfPage)?.rename(tag: tag, with: newTag)
        }
    }

}
