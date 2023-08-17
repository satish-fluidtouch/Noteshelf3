//
//  FTPasteBoardManager.swift
//  Noteshelf
//
//  Created by Mahesh on 28/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


let copiedPagesKey = "FTCopiedPages"

class FTPasteBoardManager: NSObject {
    
    static let shared = FTPasteBoardManager();
    
    private var pasteBoard = UIPasteboard.general
    
    var copiedUrl: URL? {
        
        set {
            if let value = newValue {
                let data = value.path.data(using: .utf8)
                let copiedItems = [copiedPagesKey:data]
                pasteBoard.setItems([copiedItems as [String : Any]], options: [UIPasteboard.OptionsKey.localOnly : true])
            }
        }
        
        get {
            if let copiedItem = pasteBoard.items.first {
                if let data = copiedItem[copiedPagesKey] as? Data{
                    let urlPath = String(bytes: data, encoding: .utf8)
                    if let copiedURL = urlPath {
                        return URL(fileURLWithPath: copiedURL)
                    }
                }
            }
            return nil
        }
    }
    
    private override init() {
        super.init()
    }
    
    
    private func  isCopiedBookExists() -> Bool {
        if pasteBoard.types.contains(copiedPagesKey) {
            return true;
        }
        return false
    }
    
    func isUrlValid() -> Bool {
        
        if self.pasteBoard.hasImages {
            return true
        }
        
        if let files = self.checkAndReturnIfFilesExists(), !files.isEmpty {
            return true
        }
        
        if self.isCopiedBookExists() {
            let manager = FileManager.default
            if manager.fileExists(atPath: copiedUrl!.path) {
                return true
            }
        }
        return false
    }
    
    func getBookUrl() -> URL? {
        if isUrlValid() {
            return copiedUrl
        }
        return nil
    }
    
    func checkAndReturnIfFilesExists() -> [NSItemProvider]? {
        
        let itemProviders = pasteBoard.itemProviders

        let updatedProviders = itemProviders.filter { eachProvider in
            if eachProvider.hasItemConformingToTypeIdentifier(UIPasteboard.pdfAnnotationUTI()),
               eachProvider.registeredTypeIdentifiers.count == 1 {
                return false;
            }
            return true;
        }
        
        if updatedProviders.count == 1 {
            if updatedProviders[0].isTextType {
                return nil
            }
        }
        
        if !updatedProviders.isEmpty {
            return updatedProviders
        }
        return nil
    }
    
    func handledCopiedItems(_ onCompletion: @escaping (FTDroppedItemsList) ->()) {
        if let fileItems = self.checkAndReturnIfFilesExists() {
            
            var copiedItems = [UIDragItem]()
            fileItems.forEach { (itemProvider) in
                copiedItems.append(UIDragItem(itemProvider: itemProvider))
            }
            
            FTDropItemsHelper().validDroppedItems(copiedItems) { (list) in
               onCompletion(list)
            }
        }
    }
}
