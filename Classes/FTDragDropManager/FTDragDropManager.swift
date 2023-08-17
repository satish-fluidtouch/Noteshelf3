//
//  FTDragDropManager.swift
//  Noteshelf
//
//  Created by Naidu on 17/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTDragDropManager: NSObject {
    
    var isProcessing:Bool = false
    var totalFileCount:Int = 0
    var currentFileIndex:Int = -1
    var droppedItems:[[String: Any]] = []
    static let shared: FTDragDropManager = FTDragDropManager()

    func handleDroppedItems(_ coordinatorItems:[UICollectionViewDropItem]){
        self.isProcessing = false
        self.totalFileCount = 0
        self.currentFileIndex = -1
        self.droppedItems.removeAll()
        FTLoadingIndicatorViewController.sharedIndicatorView().shouldIgnoreDismissing = true

        var filesHandled:Int = 0
        let supportedItems = supportedUTITypesForDownload();
        for coordinatorItem in coordinatorItems{
            let itemProvider=coordinatorItem.dragItem.itemProvider as NSItemProvider
            
            var fileType = ""
            supportedItems.forEach({ (UTI_TYPE) in
                if(itemProvider.hasItemConformingToTypeIdentifier(UTI_TYPE))
                {
                    fileType = UTI_TYPE
                    return
                }
            })
            if(!fileType.isEmpty){
                
                FTCLSLog("Shelf Drop Type:: \(fileType)");
                itemProvider.loadFileRepresentation(forTypeIdentifier: fileType, completionHandler: { (url, error) in
                    if (nil == error) {
                        let destFilePath = NSTemporaryDirectory().appendingFormat("%@", (url?.lastPathComponent)!);
                        let destUrl = URL.init(fileURLWithPath: destFilePath)
                        if(FileManager.default.fileExists(atPath: destUrl.path))
                        {
                            do{ try FileManager.default.removeItem(at: destUrl)} catch{}
                        }
                        do{try FileManager.default.moveItem(at: url!, to: destUrl)} catch{}
                        DispatchQueue.main.async {
                        self.droppedItems.append(["fileItem":destUrl,"fileType":"URL"])
                        filesHandled += 1
                        if(filesHandled == coordinatorItems.count){
                            self.totalFileCount = self.droppedItems.count
                            self.startProcessingNextItem()
                        }

                      }
                    }
                    else
                    {
                        self.startProcessingNextItem()
                    }
                })
            }
            else if(itemProvider.hasItemConformingToTypeIdentifier(UTI_TYPE_NOTESHELF_BOOK)){
                FTCLSLog("Shelf Drop:: UTI_TYPE_NOTESHELF_BOOK");
                
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTI_TYPE_NOTESHELF_BOOK, completionHandler: { (url, error) in
                    if (nil == error) {
                        let destFilePath = NSTemporaryDirectory().appendingFormat("%@", (url?.lastPathComponent)!);
                        let destUrl = URL.init(fileURLWithPath: destFilePath)
                        if(FileManager.default.fileExists(atPath: destUrl.path))
                        {
                            do{ try FileManager.default.removeItem(at: destUrl)} catch{}
                        }
                        do{try FileManager.default.moveItem(at: url!, to: destUrl)} catch{}
                        DispatchQueue.main.async {
                        self.droppedItems.append(["fileItem":destUrl,"fileType":"URL"])
                        filesHandled += 1
                        if(filesHandled == coordinatorItems.count){
                            self.totalFileCount = self.droppedItems.count
                            self.startProcessingNextItem()
                        }

                        }
                    }
                    else
                    {
                        self.startProcessingNextItem()
                    }
                })
            }
            else if(itemProvider.hasItemConformingToTypeIdentifier(UTI_TYPE_NOTESHELF_NOTES)){
                FTCLSLog("Shelf Drop:: UTI_TYPE_NOTESHELF_NOTES");
                
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTI_TYPE_NOTESHELF_NOTES, completionHandler: { (url, error) in
                    if (nil == error) {
                        let destFilePath = NSTemporaryDirectory().appendingFormat("%@", (url?.lastPathComponent)!);
                        let pathExtension=(url?.pathExtension)!
                        
                        var destUrl = URL.init(fileURLWithPath: destFilePath)
                        if pathExtension == "nbk"
                        {
                            destUrl=destUrl.deletingPathExtension()
                            destUrl=destUrl.appendingPathExtension("noteshelf")
                        }
                        if(FileManager.default.fileExists(atPath: destUrl.path))
                        {
                            do{ try FileManager.default.removeItem(at: destUrl)} catch{}
                        }
                        do{try FileManager.default.moveItem(at: url!, to: destUrl)} catch{}
                        DispatchQueue.main.async {
                        self.droppedItems.append(["fileItem":destUrl,"fileType":"URL"])
                        filesHandled += 1
                        if(filesHandled == coordinatorItems.count){
                            self.totalFileCount = self.droppedItems.count
                            self.startProcessingNextItem()
                        }

                        }
                    }
                    else
                    {
                        self.startProcessingNextItem()
                    }
                })
            }
            else if let readingType = UIImage.classForCoder() as? NSItemProviderReading.Type,
                itemProvider.canLoadObject(ofClass: readingType){
                FTCLSLog("Shelf Drop Image");
                
                itemProvider.loadObject(ofClass:readingType, completionHandler: { (object, error) in
                    if let image:UIImage = object as? UIImage, error == nil {
                        
                        DispatchQueue.main.async {
                            self.droppedItems.append(["fileItem":image,"fileType":"Image"])
                            filesHandled += 1
                            if(filesHandled == coordinatorItems.count){
                                self.totalFileCount = self.droppedItems.count
                                self.startProcessingNextItem()
                            }
                        }
                    }
                    else
                    {
                        self.startProcessingNextItem()
                    }
                })
            }
            else
            {
                filesHandled += 1
                if(filesHandled == coordinatorItems.count){
                    self.totalFileCount = self.droppedItems.count
                    self.startProcessingNextItem()
                }
            }
        }
    }
     func startProcessingNextItem(){
        self.currentFileIndex += 1
        if(self.currentFileIndex == self.totalFileCount){
            self.isProcessing = false
            self.totalFileCount = 0
            self.currentFileIndex = -1
            self.droppedItems.removeAll()
            FTLoadingIndicatorViewController.sharedIndicatorView().shouldIgnoreDismissing = false
            FTLoadingIndicatorViewController.sharedIndicatorView().hide()
            return
        }
        self.isProcessing = true
        let dictItem = self.droppedItems[self.currentFileIndex]
        if let fileType = dictItem["fileType"] as? String, fileType == "URL" {
            (AppDelegate.rootViewController as? FTRootViewController)?.importNewDroppedFile(fromURL: dictItem["fileItem"] as! URL)
        }else if let imagFile = dictItem["fileItem"] as? UIImage{
            (AppDelegate.rootViewController as? FTRootViewController)?.willBeginPDFImportOfItem(imagFile, shouldOpen: true, completionHandler: nil)
        }
    }
}
