//
//  FTNoteshelfDocumentProvider_LocaltoICloud.swift
//  Noteshelf
//
//  Created by Amar on 21/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTNoteshelfDocumentProvider {
    internal func moveCollectionToCloud(collections: [FTShelfItemCollection],
                                        toCloud: FTShelfCollection,
                                        onCompletion : @escaping ((NSError?) -> Void)) {
        var collectionItems = collections;
        let eachShelfCollection = collectionItems.first;
        if(nil != eachShelfCollection) {
            collectionItems.removeFirst();
            let title = eachShelfCollection!.title;
            let collectionInCloud = toCloud.collection(withTitle: title);
            if(nil == collectionInCloud) { //If same collection NOT exists in Cloud, moving whole .shelf to Cloud
                let destinationURL = toCloud.documentsDirectory().appendingPathComponent(eachShelfCollection!.URL.lastPathComponent);
                DispatchQueue.global().async {
                    do {
                        try FileManager().setUbiquitous(true,
                                                        itemAt: eachShelfCollection!.URL,
                                                        destinationURL: destinationURL);
                        DispatchQueue.main.async {
                            self.moveCollectionToCloud(collections: collectionItems,
                                                       toCloud: toCloud,
                                                       onCompletion: onCompletion);
                        }
                    } catch let fileError as NSError {
                        DispatchQueue.main.async {
                            onCompletion(fileError);
                        }
                    }
                }
            } else {
                eachShelfCollection?.shelfItems(.byName,
                                                parent: nil,
                                                searchKey: nil,
                                                onCompletion: { items in
                                                collectionInCloud?.shelfItems(.byName, parent: nil, searchKey: nil, onCompletion: { _ in
                self.moveItemsToCloud(items: items,
                                toCollection: collectionInCloud!,
                                toGroup: nil,
                                onCompletion: { error in
                                if(nil == error) {
                                    self.moveIndexInfoItem(from: eachShelfCollection as? FTSortIndexContainerProtocol,
                                                             to: collectionInCloud as? FTSortIndexContainerProtocol) { (_) in
                                        DispatchQueue.main.async {
                                            self.moveCollectionToCloud(collections: collectionItems, toCloud: toCloud, onCompletion: onCompletion);
                                        }
                                    }
                                    
                                } else {
                                    DispatchQueue.main.async {
                                        onCompletion(error);
                                    }
                                }
                                });
                    });
                });
            }
        } else {
            onCompletion(nil);
        }
    }
    
    fileprivate func moveIndexInfoItem(from localFolder: FTSortIndexContainerProtocol?,
                                       to cloudIndexFolder: FTSortIndexContainerProtocol?,
                                       onCompletion : @escaping ((NSError?) -> Void)) {
        if let destFolder = cloudIndexFolder, let indexPlist = localFolder?.indexPlistContent {
            indexPlist.moveIndexInfoItemFromLocal(destFolder, onCompletion: onCompletion)
        }
        else {
            onCompletion(NSError.init(domain: "Error", code: 1000, userInfo: nil))
        }
    }
    
    fileprivate func moveItemsToCloud(items: [FTShelfItemProtocol],
                                      toCollection: FTShelfItemCollection,
                                      toGroup: FTGroupItemProtocol?,
                                      onCompletion : @escaping ((NSError?) -> Void)) {
        var shelfItems = items;
        let eachitem = shelfItems.first;
        if(eachitem == nil) {
            onCompletion(nil);
        } else {
            shelfItems.removeFirst();
            if(eachitem?.URL.pathExtension == groupExtension) {
                let fromGroupItem = eachitem as! FTGroupItemProtocol;
                let groupItem = toCollection.groupItemWithName(title: eachitem!.displayTitle);
                if(nil == groupItem) {
                    eachitem!.shelfCollection.moveShelfItems([eachitem!],
                                                            toGroup: toGroup,
                                                            toCollection: toCollection,
                                                            onCompletion: { error, _ in
                                                                if(nil != error) {
                                                                    onCompletion(error);
                                                                } else {
                                                                    self.moveItemsToCloud(items: shelfItems,
                                                                                          toCollection: toCollection,
                                                                                          toGroup: toGroup,
                                                                                          onCompletion: onCompletion);
                                                                }
                    })
                } else {
                    self.moveItemsToCloud(items: fromGroupItem.childrens,
                                          toCollection: toCollection,
                                          toGroup: groupItem!,
                                          onCompletion: { error in
                                            if(nil == error) {
                                                self.moveIndexInfoItem(from: fromGroupItem as? FTSortIndexContainerProtocol,
                                                                         to: toGroup as? FTSortIndexContainerProtocol) { (_) in
                                                    try? FileManager().removeItem(at: fromGroupItem.URL);
                                                    self.moveItemsToCloud(items: shelfItems,
                                                                          toCollection: toCollection,
                                                                          toGroup: toGroup,
                                                                          onCompletion: onCompletion);
                                                }
                                            } else {
                                                onCompletion(error);
                                            }
                    });
                }
            } else {
                eachitem!.shelfCollection.moveShelfItems([eachitem!],
                                                        toGroup: toGroup,
                                                        toCollection: toCollection,
                                                        onCompletion: { error, _ in
                                                            if(nil != error) {
                                                                onCompletion(error);
                                                            } else {
                                                                self.moveItemsToCloud(items: shelfItems,
                                                                                      toCollection: toCollection,
                                                                                      toGroup: toGroup,
                                                                                      onCompletion: onCompletion);
                                                            }
                });
            }
        }
    }
    
    //MARK: - Audio related -
    internal func moveAudioItems(items: [FTWatchRecording],
                                    fromLocalURL localURL: URL,
                                    toCloud cloudURL: URL,
                                    onCompletion : @escaping ((Error?) -> Void)) {
        var itemsMutable = items;
        let eachItem = itemsMutable.first;
        if(nil == eachItem) {
            DispatchQueue.main.async {
                onCompletion(nil);
            }
            return;
        }
        itemsMutable.removeFirst();
        let audioPath = eachItem!.filePath!
        let sourcePlist = audioPath.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
        
        let destPlist = cloudURL.appendingPathComponent(sourcePlist.lastPathComponent);
        let destAudioURL = destPlist.deletingPathExtension().appendingPathExtension(audioFileExtension);
        
        FileManager.replaceCoordinatedItem(atURL: destPlist, fromLocalURL: sourcePlist) { error in
            if(nil == error) {
                FileManager.replaceCoordinatedItem(atURL: destAudioURL,
                                                   fromLocalURL: audioPath,
                                                   onCompletion: { inError in
                                                    if(nil == inError) {
                                                        try? FileManager().removeItem(at: sourcePlist);
                                                        try? FileManager().removeItem(at: audioPath);
                                                        
                                                        self.moveAudioItems(items: itemsMutable,
                                                                            fromLocalURL: localURL,
                                                                            toCloud: cloudURL,
                                                                            onCompletion: onCompletion);
                                                    } else {
                                                        DispatchQueue.main.async {
                                                            onCompletion(inError);
                                                        }
                                                    }
                });
            } else {
                DispatchQueue.main.async {
                    onCompletion(error);
                }
            }
        }
    }

}
