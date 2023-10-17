//
//  FTDocumentTags.swift
//  Noteshelf3
//
//  Created by Siva on 11/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTCachedDocumentPage: Decodable, Identifiable, Hashable {
    var uuid: String

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(uuid)
    }

    public static func == (lhs: FTCachedDocumentPage, rhs: FTCachedDocumentPage) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    func addTag(tag: String) {
        tags.append(tag)
    }

    func removeTag(tag: String) {
        if let index = self.tags.firstIndex(where: {$0 == tag}) {
            self.tags.remove(at: index)
        }
    }

    fileprivate func thumbnailPath(documentUUID: String) -> String
    {
        let thumbnailFolderPath = URL.thumbnailFolderURL();
        let documentPath = thumbnailFolderPath.appendingPathComponent(documentUUID);
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: documentPath.path, isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil);
        }
        let thumbnailPath  = documentPath.appendingPathComponent(self.uuid);
        return thumbnailPath.path;
    }

    func thumbnail(documentUUID: String, onCompletion: @escaping ((UIImage?,String) -> Void)) {
        let thumbnailPath = self.thumbnailPath(documentUUID: documentUUID)
        let pageUUID = self.uuid
        var img: UIImage? = nil
        if nil == img && FileManager().fileExists(atPath: thumbnailPath) {
            DispatchQueue.global().async {
                img = UIImage.init(contentsOfFile: thumbnailPath)
                DispatchQueue.main.async {
                    onCompletion(img, pageUUID)
                }
            }
        } else {
            onCompletion(img, pageUUID)
        }
    }

    var pageRect: CGRect {
        var pageRec = NSCoder.cgRect(for: self.pdfKitPageRect)
        if self.rotationAngle > 0 {
            pageRec = pageRec.rotate(by: self.rotationAngle)
            pageRec.origin = .zero
        }
        return pageRec
    }

    var pageIndex: Int?
    var tags: [String]
    var pdfKitPageRect: String
    var rotationAngle: UInt
    var bookmarkTitle: String
    var isBookmarked: Bool
}

class FTCachedDocumentPlist: Decodable {
     var pages: [FTCachedDocumentPage]
    func pageFor(pageUUID: String) -> FTCachedDocumentPage? {
        if let index = self.pages.firstIndex(where: { $0.uuid == pageUUID }) {
            let page = self.pages[index]
            page.pageIndex = index
            return page
        }
        return nil
    }

}
