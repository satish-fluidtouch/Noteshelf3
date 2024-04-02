//
//  FTNoteshelfDocumentProvider_iCloudToLocal.swift
//  Noteshelf
//
//  Created by Amar on 21/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework
import FTCommon

extension FTNoteshelfDocumentProvider {
    func moveCollectionToLocal(collections: [FTShelfItemCollection],
                               toLocal: FTShelfCollection,
                               onCompletion : @escaping ((NSError?) -> Void)) {
        var collectionItems = collections;
        let eachShelfCollection = collectionItems.first;
        if(nil != eachShelfCollection) {
            collectionItems.removeFirst();
            let title = eachShelfCollection?.URL.deletingPathExtension().lastPathComponent;
            let collectionInLocal = toLocal.collection(withTitle: title!);
            if(nil == collectionInLocal) { //If same collection NOT exists in Local, moving whole .shelf to Local
                toLocal.createShelf(title!) { error, _ in
                    if(nil == error) {
                        self.moveCollectionToLocal(collections: collections,
                                                   toLocal: toLocal,
                                                   onCompletion: onCompletion);
                    } else {
                        onCompletion(error);
                    }
                }
            } else {
                eachShelfCollection?.shelfItems(.byName, parent: nil, searchKey: nil, onCompletion: { items in
                    collectionInLocal?.shelfItems(.byName, parent: nil, searchKey: nil, onCompletion: { _ in
                        self.copyItems(items: items, toGroup: nil, toCollection: collectionInLocal!, onCompletion: { error in
                            if(nil != error) {
                                onCompletion(error);
                            } else {
                                self.copyIndexInfoItem(from: eachShelfCollection as? FTSortIndexContainerProtocol,
                                                         to: collectionInLocal as? FTSortIndexContainerProtocol) { (_) in
                                    self.moveCollectionToLocal(collections: collectionItems,
                                                               toLocal: toLocal,
                                                               onCompletion: onCompletion);
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
    
    private func copyIndexInfoItem(from cloudIndexFolder: FTSortIndexContainerProtocol?,
                                       to localFolder: FTSortIndexContainerProtocol?,
                                       onCompletion : @escaping ((NSError?) -> Void)) {
        if let destFolder = localFolder {
            cloudIndexFolder?.indexPlistContent?.copyIndexInfoItemFromCloud(destFolder, onCompletion: onCompletion)
        }
    }

    fileprivate func copyItems(items: [FTShelfItemProtocol],
                               toGroup: FTGroupItemProtocol?,
                               toCollection: FTShelfItemCollection, onCompletion : @escaping ((NSError?) -> Void)) {
        var shelfItems = items;
        let eachShelfItem = shelfItems.first;
        if(nil == eachShelfItem) {
            onCompletion(nil);
        } else {
            shelfItems.removeFirst();

            if(eachShelfItem!.URL.pathExtension == FTFileExtension.group) {
                let groupItem = eachShelfItem as! FTGroupItemProtocol;
                let relativePath = groupItem.URL.pathRelativeTo(groupItem.shelfCollection.URL);
                let destinationURL = toCollection.URL.appendingPathComponent(relativePath);
                if FileManager().fileExists(atPath: destinationURL.path)
                    ,let localGroupItem = toCollection.groupItemForURL(destinationURL) {
                    self.copyItems(items: groupItem.childrens,
                                   toGroup: localGroupItem,
                                   toCollection: toCollection,
                                   onCompletion: { error in
                                    if(nil == error) {
                                        self.copyItems(items: shelfItems,
                                                       toGroup: toGroup,
                                                       toCollection: toCollection,
                                                       onCompletion: onCompletion);
                                    } else {
                                        onCompletion(error);
                                    }
                    });
                } else {
                    toCollection.createGroupItem(eachShelfItem!.displayTitle,
                                                 inGroup: toGroup,
                                                 shelfItemsToGroup: nil) { error, localGroupItem in
                                                    if(nil == error) {
                                                        self.copyIndexInfoItem(from: eachShelfItem as? FTSortIndexContainerProtocol,
                                                                                 to: localGroupItem as? FTSortIndexContainerProtocol) { (_) in
                                                            if let group = eachShelfItem as? FTGroupItemProtocol {
                                                                self.copyItems(items: group.childrens,
                                                                               toGroup: localGroupItem,
                                                                               toCollection: toCollection) { error in
                                                                    if(nil == error) {
                                                                        self.copyItems(items: shelfItems,
                                                                                       toGroup: toGroup,
                                                                                       toCollection: toCollection,
                                                                                       onCompletion: onCompletion);
                                                                    } else {
                                                                        onCompletion(error);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        onCompletion(error);
                                                    }
                    }
                }
            } else {
                var parentURL = toCollection.URL;
                if(nil != toGroup) {
                    parentURL = toGroup!.URL//toCollection.URL.appendingPathComponent(toGroup!.URL.lastPathComponent)
                }
                var destinationURL = parentURL.appendingPathComponent(eachShelfItem!.URL.lastPathComponent);

                if(FileManager().fileExists(atPath: destinationURL.path)) {
                    let uniqueName = FileManager.uniqueFileName(eachShelfItem!.URL.lastPathComponent, inFolder: parentURL);
                    destinationURL = toCollection.URL.appendingPathComponent(uniqueName);
                }
                self.copyItemAtURL(sourceURL: eachShelfItem!.URL, toURL: destinationURL, onCompletion: { error in
                    DispatchQueue.main.async {
                        if(nil == error) {
                            self.copyItems(items: shelfItems,
                                           toGroup: toGroup,
                                           toCollection: toCollection,
                                           onCompletion: onCompletion);
                        } else {
                            onCompletion(error);
                        }
                    }
                });
            }
        }
    }

    fileprivate func copyItemAtURL(sourceURL: URL, toURL destination: URL, onCompletion : @escaping (NSError?) -> Void) {
        DispatchQueue.global().async {
            var error: NSError?;
            FTCLSLog("NFC - Copy icloud to local");
            let fileCoordinator = NSFileCoordinator(filePresenter: nil);
            fileCoordinator.coordinate(readingItemAt: sourceURL,
                                       options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                       error: &error,
                                       byAccessor: { localSourceURL in
                                        do {
                                            let nsSourceURL = localSourceURL as NSURL;
                                            var thumbnailInfo: AnyObject?;
                                            try? nsSourceURL.getPromisedItemResourceValue(&thumbnailInfo, forKey: URLResourceKey.thumbnailDictionaryKey);

                                            let fileManager = FileManager();
                                            try fileManager.copyItem(at: localSourceURL, to: destination);

                                            //update the document uuid
                                            let propertyPlist = destination.appendingPathComponent(METADATA_FOLDER_NAME).appendingPathComponent(PROPERTIES_PLIST);
                                            let dict = NSMutableDictionary(contentsOf: propertyPlist);
                                            if(nil != dict) {
                                                let newdocumentUUID = FTUtils.getUUID();
                                                let oldDocumentUUID = dict?[DOCUMENT_ID_KEY] as? String;

                                                dict?[DOCUMENT_ID_KEY] = newdocumentUUID;
                                                dict?.write(to: propertyPlist, atomically: true);
                                                if FTDocumentPropertiesReader.USE_EXTENDED_ATTRIBUTE {
                                                    try? destination.setExtendedAttributes(attributes: [FileAttributeKey.ExtendedAttribute(key: .documentUUIDKey, string: newdocumentUUID)])
                                                }
                                                //update dropbox/evernote/thumbanil as the document uuid is changed
                                                if(oldDocumentUUID != nil) {
                                                    //Thumbnail Folder
                                                    let thumbnailFolderPath = URL.thumbnailFolderURL();
                                                    let oldDocThumbPath = thumbnailFolderPath.appendingPathComponent(oldDocumentUUID!);
                                                    let newDocThumbPath = thumbnailFolderPath.appendingPathComponent(newdocumentUUID);
                                                    try? fileManager.moveItem(at: oldDocThumbPath, to: newDocThumbPath)
                                                    
                                                    //update evernote
                                                    FTENPublishManager.shared.updateDocumentId(from: oldDocumentUUID!, to: newdocumentUUID);
                                                }
                                            }

                                            if(nil != thumbnailInfo) {
                                                try? (destination as NSURL).setResourceValue(thumbnailInfo, forKey: URLResourceKey.thumbnailDictionaryKey);
                                            }

                                            onCompletion(nil);
                                        } catch let fileError as NSError {
                                            onCompletion(fileError);
                                        }
            });
            if(nil != error) {
                onCompletion(error);
            }
        }
    }
    
    //MARK: - Audio related -
    internal func copyAudioItems(items: [FTWatchRecording],
                                 fromCloud cloudURL: URL,
                                 toLocalURL localURL: URL,
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
        let audioCloudURL = eachItem!.filePath!
        let plistCloudURL = audioCloudURL.deletingPathExtension().appendingPathExtension(audioMetadataFileExtension);
        
        let plistLocalURL = localURL.appendingPathComponent(plistCloudURL.lastPathComponent);
        
        let plistInfo = eachItem?.dictionaryRepresentation();
        do {
            try (plistInfo! as NSDictionary).write(to: plistLocalURL);
            let audioLocalURL = plistLocalURL.deletingPathExtension().appendingPathExtension(audioFileExtension);
            
            try? FileManager().removeItem(at: audioLocalURL);
            
            FileManager.copyCoordinatedItemAtURL(audioCloudURL,
                                                 toNonCoordinatedURL: audioLocalURL,
                                                 onCompletion: { success, error in
                                                    if(nil == error) {
                                                        DispatchQueue.global().async {
                                                            self.copyAudioItems(items: itemsMutable,
                                                                                fromCloud: cloudURL,
                                                                                toLocalURL: localURL,
                                                                                onCompletion: onCompletion);
                                                        }
                                                    } else {
                                                        DispatchQueue.main.async {
                                                            onCompletion(error);
                                                        }
                                                    }
            });
        } catch {
            DispatchQueue.main.async {
                onCompletion(error);
            }
        }
    }
}
