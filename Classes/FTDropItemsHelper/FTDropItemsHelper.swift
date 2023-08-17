//
//  FTDropItemsHelper.swift
//  Noteshelf
//
//  Created by Naidu on 17/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MobileCoreServices

class FTDroppedItemsList : NSObject
{
    var fileItems = [URL]();
    var notebookItems = [URL]();
    var imageItems = [UIImage]();
    var textItems = [String]();
    var urlClips = [URL]();
}

class FTDropItemsHelper : NSObject
{
    let droppedItems = FTDroppedItemsList();
    let group = DispatchGroup.init();

    func validDroppedItems(_ dragItems : [UIDragItem],
                           onCompletion : @escaping (FTDroppedItemsList)->())
    {
        for eachDragItem in dragItems {
            group.enter();
            let itemProvider = eachDragItem.itemProvider;
            self.processDropItem(itemProvider)
        }
        self.group.notify(queue: DispatchQueue.main) {
            onCompletion(self.droppedItems);
        }
    }
    func processDropItem(_ itemProvider: NSItemProvider){
        if(itemProvider.isImageType) {
            FTCLSLog("Drop Image");
            itemProvider.loadImage { (object) in
                if let image = object {
                    objc_sync_enter(self.droppedItems);
                    self.droppedItems.imageItems.append(image);
                    objc_sync_exit(self.droppedItems);
                }
                self.group.leave();
            }
        }
        else if let fileType = itemProvider.fileDocumentType {
            FTCLSLog("Drop Type:: \(fileType)");
            itemProvider.loadFile(fileType: fileType) { (url) in
                if let fileURL = url {
                    objc_sync_enter(self.droppedItems);
                    self.droppedItems.fileItems.append(fileURL);
                    objc_sync_exit(self.droppedItems);
                }
                self.group.leave();
            }
        }
        else if let fileType = itemProvider.notebookType {
            FTCLSLog("Drop Type:: \(fileType)");
            itemProvider.loadFile(fileType: fileType) { (url) in
                if let fileURL = url {
                    objc_sync_enter(self.droppedItems);
                    self.droppedItems.notebookItems.append(fileURL);
                    objc_sync_exit(self.droppedItems);
                }
                self.group.leave();
            }
        } else if (itemProvider.isURLType) {
            FTCLSLog("Drop Type: URL");
            #if targetEnvironment(macCatalyst)
            itemProvider.loadTypeIdentifier(identifier: kUTTypeURL as String) { (url) in
                if let fileURL = url {
                    objc_sync_enter(self.droppedItems);
                    if let img = UIImage(contentsOfFile: fileURL.path) {
                        self.droppedItems.imageItems.append(img);
                    } else {
                        self.droppedItems.fileItems.append(fileURL);
                    }
                    objc_sync_exit(self.droppedItems);
                }
                self.group.leave();
            }
            #else
            itemProvider.loadUrlString { url in
                if let droppedUrl = url {
                    self.droppedItems.urlClips.append(droppedUrl)
                }
                self.group.leave();
            }
            #endif
        }

        else if(itemProvider.isTextType) {
            FTCLSLog("Drop Text");
            itemProvider.loadString { (object) in
                if let text = object {
                    objc_sync_enter(self.droppedItems);
                    self.droppedItems.textItems.append(text);
                    objc_sync_exit(self.droppedItems);
                }
                self.group.leave();
            }
        }

        else {
            self.group.leave();
        }
    }
    func validDroppedItems(_ dragItems : [NSItemProvider],
                           onCompletion : @escaping (FTDroppedItemsList)->())
    {
        for itemProvider in dragItems {
            group.enter();
            self.processDropItem(itemProvider)
        }
        group.notify(queue: DispatchQueue.main) {
            onCompletion(self.droppedItems);
        }
    }
}


extension UICollectionViewDropCoordinator {
    var dragItems : [UIDragItem] {
        var items = [UIDragItem]();
        for eachItem in self.items {
            items.append(eachItem.dragItem);
        }
        return items;
    }
}
