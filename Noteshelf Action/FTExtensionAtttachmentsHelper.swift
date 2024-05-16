//
//  FTExtensionAtttachmentsHelper.swift
//  
//
//  Created by Simhachalam Naidu on 23/04/20.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class FTExtensionAtttachmentsHelper: NSObject {
    func loadInputAttachments(_ extensionContext: NSExtensionContext, onCompletion : @escaping (FTAttachmentsInfo)->()) {
        
        let attachmentsInfo = FTAttachmentsInfo()
        let allItemProviders = extensionContext.fileItemProviders
        if (allItemProviders.isEmpty) {
            DispatchQueue.main.async() {
                onCompletion(attachmentsInfo)
            }
            return
        }
        
        let group = DispatchGroup.init();
        for provider in allItemProviders {
            group.enter()
             if provider.isURLType {// This check should be first, because images from Mail app will be received as Image but cannot access
                 provider.loadItem(forTypeIdentifier: UTType.url.identifier,
                                  options:nil,
                                  completionHandler:
                    { (obj, error) in
                        if nil == error, let importedURL = obj as? URL {
                            if importedURL.pathExtension.isEmpty {
                                objc_sync_enter(attachmentsInfo);
                                attachmentsInfo.websiteURLs.append(importedURL)
                                objc_sync_exit(attachmentsInfo);
                            }
                            else {
                                if FTExtensionAtttachmentsHelper.supportedFilesPathExtensions.contains(importedURL.pathExtension.lowercased()) {
                                    objc_sync_enter(attachmentsInfo);
                                    attachmentsInfo.publicURLs.append(importedURL)
                                    objc_sync_exit(attachmentsInfo);
                                } else if FTExtensionAtttachmentsHelper.supportedAudiosPathExtensions.contains(importedURL.pathExtension.lowercased()) {
                                    objc_sync_enter(attachmentsInfo);
                                    attachmentsInfo.audioUrls.append(importedURL)
                                    objc_sync_exit(attachmentsInfo);
                                }
                                else if FTExtensionAtttachmentsHelper.supportedImagePathExtensions.contains(importedURL.pathExtension.lowercased()) {
                                    objc_sync_enter(attachmentsInfo);
                                    attachmentsInfo.publicImageURLs.append(importedURL)
                                    objc_sync_exit(attachmentsInfo);
                                }
                                else
                                {
                                    objc_sync_enter(attachmentsInfo);
                                    attachmentsInfo.unSupportedItems.append(importedURL)
                                    objc_sync_exit(attachmentsInfo);
                                }
                            }
                        }
                        group.leave()
                })
            }
            else if provider.isImageType {
                provider.loadImage { (object) in
                    if let image = object {
                        objc_sync_enter(attachmentsInfo);
                         let url = self.addImageTotempDirectory(image: image)
                         attachmentsInfo.imageItems.append(url)
                        objc_sync_exit(attachmentsInfo);
                    }
                    group.leave()
                }
            }
            else {
                objc_sync_enter(attachmentsInfo);
                attachmentsInfo.unSupportedItems.append("UNSUPPORTED_DATA")
                objc_sync_exit(attachmentsInfo);
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            onCompletion(attachmentsInfo)
        }
    }
    
    func addImageTotempDirectory(image: UIImage) -> URL {
        let uuid = UUID().uuidString
        let destPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(uuid).png");
        let fileURL = URL(fileURLWithPath: destPath)
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            do {
                try imageData.write(to: fileURL)
            } catch {}
        }
        return fileURL
    }
    
    #if targetEnvironment(macCatalyst)
    private static let supportedFileDocsPathExtensions = ["pdf","noteshelf"];
    #else
    private static let supportedFileDocsPathExtensions = ["pdf","doc","docx","ppt","pptx","xls","xlsx","noteshelf"];
    #endif
    static let supportedAudiosPathExtensions = ["wav", "mp3", "aiff", "flac", "caf", "m4a", "aif", "aac", "aifc"];
    static let supportedImagePathExtensions = ["jpg", "jpeg", "png"];

    static var supportedFilesPathExtensions : [String] {
        var pathsExts = FTExtensionAtttachmentsHelper.supportedFileDocsPathExtensions;
        pathsExts.append(contentsOf: FTExtensionAtttachmentsHelper.supportedAudiosPathExtensions);
        return pathsExts
    }
}
//****************************************
//MARK:- FTAttachmentsInfo
class FTAttachmentsInfo: NSObject {
    var publicURLs = [URL]();
    var websiteURLs = [URL]();
    var imageItems = [URL]();
    var audioUrls = [URL]();
    var publicImageURLs = [URL]();
    var unSupportedItems = [Any]();
    
    func hasPublicFiles() -> Bool {
        return (!publicURLs.isEmpty)
    }
    func hasOnlyPublicImageURLs() -> Bool {
        return (!publicImageURLs.isEmpty && imageItems.isEmpty && websiteURLs.isEmpty && publicURLs.isEmpty)
    }
    func hasOnlyImageFiles() -> Bool {
        return (!imageItems.isEmpty && websiteURLs.isEmpty && publicURLs.isEmpty && publicImageURLs.isEmpty)
    }
    func hasOnlyWebsiteLinks() -> Bool {
        return (!websiteURLs.isEmpty && publicURLs.isEmpty && imageItems.isEmpty && publicImageURLs.isEmpty)
    }
    func hasOnlyUnSupportedFiles() -> Bool {
        return (publicURLs.isEmpty && websiteURLs.isEmpty && imageItems.isEmpty && publicImageURLs.isEmpty)
    }
    
    func hasAudioUrlsOnly() -> Bool {
        return (publicURLs.isEmpty && websiteURLs.isEmpty && imageItems.isEmpty && publicImageURLs.isEmpty && !audioUrls.isEmpty)
    }
    
    func hasAnyNoteShelfFiles() -> Bool {
        return self.publicURLs.contains { $0.pathExtension.lowercased() == "noteshelf" }
    }
}
//****************************************
//MARK:- NSExtensionContext
extension NSExtensionContext {
    var fileItemProviders : [NSItemProvider] {
        var fileItemProviders = [NSItemProvider]();
        if let extInputItems = self.inputItems as? [NSExtensionItem] {
            for eachItem in extInputItems {
                if let attachmentItems = eachItem.attachments {
                    fileItemProviders.append(contentsOf: attachmentItems)
                }
            }
        }
        return fileItemProviders;
    }
}
