//
//  NSItemProvider+Extension.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 24/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import MobileCoreServices
import FTCommon
import UIKit
import UniformTypeIdentifiers

extension NSItemProvider
{
    var isImageType : Bool {
        if let readType = UIImage.classForCoder() as? NSItemProviderReading.Type {
            return self.canLoadObject(ofClass: readType);
        }
        return false;
    }
    var isURLType : Bool {
        if self.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            return true
        }
        return false;
    }
    
    var notebookType : String? {
        var fileType : String?;
        if(self.hasItemConformingToTypeIdentifier(UTI_TYPE_NOTESHELF_BOOK)) {
            fileType = UTI_TYPE_NOTESHELF_BOOK;
        }
        else if(self.hasItemConformingToTypeIdentifier(UTI_TYPE_NOTESHELF_NOTES)) {
            fileType = UTI_TYPE_NOTESHELF_NOTES;
        }
        return fileType;
    }
    
    var isTextType : Bool {
        if let readType = NSString.classForCoder() as? NSItemProviderReading.Type {
            return self.canLoadObject(ofClass: readType);
        }
        return false;
    }
    
    var fileDocumentType : String? {
        let supportedItems = supportedUTITypesForDownload();
        let fileType = supportedItems.first { (UTI_TYPE) -> Bool in
            return self.hasItemConformingToTypeIdentifier(UTI_TYPE);
        }
        return fileType;
    }
    
    func loadImage(_ onCompeltion : @escaping (UIImage?) -> Void)
    {
        if let readType = UIImage.classForCoder() as? NSItemProviderReading.Type {
            self.loadObject(ofClass: readType) { (image, _) in
                onCompeltion(image as? UIImage);
            };
        }
        else {
            onCompeltion(nil)
        }
    }
    
    func loadString(_ onCompeltion : @escaping (String?) -> Void)
    {
        if let readType = NSString.classForCoder() as? NSItemProviderReading.Type {
            self.loadObject(ofClass: readType) { (text, _) in
                onCompeltion(text as? String);
            };
        }
        else {
            onCompeltion(nil)
        }
    }
    
    func loadUrlString(_ onCompeltion : @escaping (URL?) -> Void)
    {
        if let readType = NSURL.classForCoder() as? NSItemProviderReading.Type {
            self.loadObject(ofClass: readType) { (text, _) in
                onCompeltion(text as? URL);
            };
        }
        else {
            onCompeltion(nil)
        }
    }
    
    func loadFile(fileType : String,onCompeltion : @escaping (URL?) -> Void)
    {
        DispatchQueue.global().async {
            self.loadFileRepresentation(forTypeIdentifier: fileType,
                                        completionHandler:
                { (url, _) in
                    var returnURL : URL?;
                    if let fileURL = url {
                        let destFilePath = NSTemporaryDirectory().appendingFormat("%@", fileURL.lastPathComponent);
                        let destUrl = URL.init(fileURLWithPath: destFilePath)
                        try? FileManager.default.removeItem(at: destUrl)
                        do {
                            try FileManager.default.moveItem(at: fileURL, to: destUrl);
                            returnURL = destUrl;
                        }
                        catch {
                        }
                    }
                    onCompeltion(returnURL);
            });
        }
    }
    
    func loadTypeIdentifier( identifier: String, onCompletion: @escaping (URL?) -> Void) {
        self.loadItem(forTypeIdentifier: identifier, options: nil) { (data, error) in
            var returnURL : URL?;
            if let fileURLItem = URL(dataRepresentation: data as! Data, relativeTo: nil) {
                let destFilePath = NSTemporaryDirectory().appendingFormat("%@", fileURLItem.lastPathComponent);
                let destUrl = URL.init(fileURLWithPath: destFilePath)
                try? FileManager.default.removeItem(at: destUrl)
                do {
                    try FileManager.default.copyItem(at: fileURLItem, to: destUrl);
                    returnURL = destUrl;
                }
                catch {
                }
            }
            onCompletion(returnURL);
        }
    }
}
