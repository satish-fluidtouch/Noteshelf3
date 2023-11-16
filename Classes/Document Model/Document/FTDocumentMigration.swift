//
//  FTDocumentMigration.swift
//  Noteshelf3
//
//  Created by Akshay on 01/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

#if targetEnvironment(macCatalyst)
private let ns2URLScheme = "maccatalyst.com.fluidtouch.noteshelf://"
#else
#if DEBUG
private let ns2URLScheme = "com.fluidtouch.noteshelf-dev://"
#elseif BETA
private let ns2URLScheme = "com.fluidtouch.noteshelf-beta://"
#else
private let ns2URLScheme = "com.fluidtouch.noteshelf://"
#endif
#endif

enum FTMigrationError: Error {
    case moveToNS3Error
    case unableToCreateDocument
}

enum NS2MigrationSource {
    case local
    case cloud
    case doesNotSupport
}

final class FTDocumentMigration {
    static let migrationQueue = DispatchQueue(label: "com.fluidtouch.noteshelf3.migration")
    static func supportsMigration() -> Bool {
        return false
    }

    static func showNS3MigrationAlert(on controller: UIViewController,
                                      onCopyAction: (() -> Void)?) {
        let alert = UIAlertController(title: "migration.alert.title".localized, message: nil, preferredStyle: UIAlertController.Style.alert)

        let copy = UIAlertAction(title: "migration.alert.migrate".localized, style: UIAlertAction.Style.cancel) { _ in
            onCopyAction?()
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: UIAlertAction.Style.default)
        alert.addAction(cancel)
        alert.addAction(copy)
        controller.present(alert, animated: true)
    }

    static func showNS3MigrationSuccessAlert(on controller: UIViewController,
                                             relativePath: String,
                                             onOpenAction: (() -> Void)?) {
        let title = String(format: NSLocalizedString("migration.success.alert.message", comment: ""), relativePath)
        let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)

        let open = UIAlertAction(title: "migration.alert.open".localized, style: UIAlertAction.Style.cancel) { _ in
            onOpenAction?()
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: UIAlertAction.Style.default)
        alert.addAction(cancel)
        alert.addAction(open)
        controller.present(alert, animated: true)
    }

    static func showNS3MigrationFailureAlert(on controller: UIViewController) {
        let alert = UIAlertController(title: "migration.failure.message".localized, message: nil, preferredStyle: UIAlertController.Style.alert)

        let action = UIAlertAction(title: "OK".localized, style: UIAlertAction.Style.cancel)
        alert.addAction(action)
        controller.present(alert, animated: true)
    }

    static func performNS2toNs3Migration(shelfItem: FTShelfItemProtocol,
                                         onCompletion: ((_ url: URL?, _ error: Error?) -> Void)?) {
        do {
            let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "NS3Migration")
            if(!FileManager().fileExists(atPath: temporaryDirectory.path)) {
                try? FileManager().createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil);
            }
            let fileName = shelfItem.URL.lastPathComponent.deletingPathExtension
            let documentTemporaryLocation = temporaryDirectory.appendingPathComponent(shelfItem.URL.lastPathComponent)

            let lastModificationDate = shelfItem.URL.fileModificationDate
            let fileCreationDate = shelfItem.URL.fileCreationDate
            // Remove if something already exists
            try? FileManager().removeItem(at: documentTemporaryLocation);

            // Copy the notebook to temporary location with new extension
            try FileManager().coordinatedCopy(fromURL: shelfItem.URL, toURL: documentTemporaryLocation);
            // When the user choses copy option, we must regenrate Document UUID, for this purpose, we're using the existing approach.
            FTDocumentFactory.prepareForImportingAtURL(documentTemporaryLocation) { error, document in
                if let fileURL = document?.URL {
                    do {
                        try? (fileURL as NSURL).setResourceValue(lastModificationDate, forKey: URLResourceKey.contentModificationDateKey)

                        try? (fileURL as NSURL).setResourceValue(fileCreationDate, forKey: URLResourceKey.creationDateKey)

                        let migratedURL = try FTNoteshelfDocumentProvider.shared.migrateNS2BookToNS3(url: fileURL, relativePath: shelfItem.URL.relativePathWRTCollection())

                        // TODO: Pass the document
                        onCompletion?(migratedURL, nil)
                    } catch {
                        onCompletion?(nil, FTMigrationError.unableToCreateDocument)
                    }
                }
                else {
                    onCompletion?(nil, FTMigrationError.unableToCreateDocument)
                }
            }
        } catch {
            debugLog("Migration Error \(error)")
            onCompletion?(nil, error)
        }
    }
    
    static func uuidFromURL(_ url: URL) -> String? {
        var uuid: String?
        let dest = url.appendingPathComponent(FTCacheFiles.cachePropertyPlist)
        let propertiList = FTFileItemPlist(url: dest, isDirectory: false)
        if let docId = propertiList?.object(forKey: DOCUMENT_ID_KEY) as? String {
            uuid = docId
        }
        return uuid
    }
    
     static func performNS2toNs3MassMigration(url: URL,
                                              onCompletion: ((_ url: URL?, _ error: Error?) -> Void)?) {
         var documentPin: String?
         let isPinEnabled = isPinEnabledForDownloadedDocument(url: url)
         if let uuid = FTDocumentMigration.uuidFromURL(url) {
             let isTouchIdEnabled = FTBiometricManager.isTouchIdEnabled(for: uuid)
             if isPinEnabled && isTouchIdEnabled {
                 //Get pin with NS2 Item UUID
                 documentPin = FTBiometricManager.passwordForNS2Book(with: uuid)
             }
         }
         do {
             let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "NS3Migration")
             if(!FileManager().fileExists(atPath: temporaryDirectory.path)) {
                 try? FileManager().createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil);
             }
             let fileName = url.lastPathComponent.deletingPathExtension
             let documentTemporaryLocation = temporaryDirectory.appendingPathComponent(url.lastPathComponent)

             let lastModificationDate = url.fileModificationDate
             let fileCreationDate = url.fileCreationDate
             // Remove if something already exists
             try? FileManager().removeItem(at: documentTemporaryLocation);

             // Copy the notebook to temporary location with new extension
             try FileManager().coordinatedMove(fromURL: url, toURL: documentTemporaryLocation)
             // When the user choses copy option, we must regenrate Document UUID, for this purpose, we're using the existing approach.
             FTDocumentFactory.prepareForImportingAtURL(documentTemporaryLocation) { error, document in
                 if let fileURL = document?.URL {
                     do {
                         try? (fileURL as NSURL).setResourceValue(lastModificationDate, forKey: URLResourceKey.contentModificationDateKey)

                         try? (fileURL as NSURL).setResourceValue(fileCreationDate, forKey: URLResourceKey.creationDateKey)

                         let migratedURL = try FTNoteshelfDocumentProvider.shared.migrateNS2BookToNS3(url: fileURL, relativePath: url.relativePathWRTCollection())

                         // TODO: Pass the document
                         if let migratedURL, let documentPin, isPinEnabled {
                             FTBiometricManager.keychainSetIsTouchIDEnabled(FTBiometricManager().isTouchIDEnabled(), withPin: documentPin, forKey: migratedURL.getExtendedAttribute(for: .documentUUIDKey)?.stringValue)
                         }
                         onCompletion?(migratedURL, nil)
                     } catch {
                         onCompletion?(nil, FTMigrationError.unableToCreateDocument)
                     }
                 }
                 else {
                     onCompletion?(nil, FTMigrationError.unableToCreateDocument)
                 }
             }
         } catch {
             debugLog("Migration Error \(error)")
             onCompletion?(nil, error)
         }
     }
    
    static func intiateNS2ToNS3MassMigration(on controller: UIViewController, _ onCompletion: @escaping (Bool, NSError?) -> Void) -> Progress {

        let progress = Progress()
        progress.isCancellable = true
        progress.isPausable = true
        if let ns3MigrationContainerURL =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:  FTUtils.getNS2GroupId())?.appendingPathComponent("Noteshelf3_migration"), let urls = self.contentsOfURL(ns3MigrationContainerURL) {
            var noteBookUrls = urls
            let totalItems = noteBookUrls.count
            progress.totalUnitCount = Int64(totalItems)
            FTCLSLog("---Migration In Progress---")
            func migrateBooks() {
                guard !progress.isCancelled else {
                    onCompletion(false, nil)
                    return
                }
                guard !progress.isPaused else {
                    return
                }

                let currentProcessingIndex = totalItems - noteBookUrls.count + 1;
                if let firstItem = noteBookUrls.first {
                    FTDocumentMigration.performNS2toNs3MassMigration(url: firstItem) { url, error in
                        progress.localizedDescription = url?.lastPathComponent.deletingPathExtension ?? "";
                        progress.completedUnitCount += 1;
                        noteBookUrls.removeFirst()
                        migrateBooks()
                    }
                } else {
                    onCompletion(true, nil)
                }
            }
            migrateBooks()
            progress.resumingHandler = {
                migrateBooks()
            }
        } else {
            onCompletion(false, nil)
        }
        
        return progress
    }
    
    private static func isPinEnabledForDownloadedDocument(url: URL) -> Bool {
        let securityPath = url.appendingPathComponent("secure.plist");
        if(FileManager().fileExists(atPath: securityPath.path)) {
            return true;
        }
        return false;
    }

    static func contentsOfURL(_ url: URL) -> [URL]? {
        if let urls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles) {
            let filteredURLS = FTDocumentMigration.filterItemsMatchingExtensions(urls);
            var notebookUrlList: [URL] = [URL]()
            filteredURLS.enumerated().forEach({ (_,eachURL) in
                if eachURL.pathExtension == FTFileExtension.shelf {
                    if let dirContents = self.contentsOfURL(eachURL) {
                        if !dirContents.isEmpty {
                            notebookUrlList.append(contentsOf: dirContents);
                        }
                    }
                } else if(eachURL.pathExtension == FTFileExtension.group) {
                    if let dirContents = self.contentsOfURL(eachURL) {
                        if !dirContents.isEmpty {
                            notebookUrlList.append(contentsOf: dirContents);
                        }
                    }
                }
                else {
                    notebookUrlList.append(eachURL);
                }
            });
            return notebookUrlList
        } else {
            return nil
        }
    }
    
    static func filterItemsMatchingExtensions(_ items : [URL]?) -> [URL]
    {
        let extToListen = [FTFileExtension.ns2, FTFileExtension.group, FTFileExtension.shelf]
        var filteredURLS = [URL]();
        if let items {
            if(!extToListen.isEmpty) {
                filteredURLS = items.filter({ (eachURL) -> Bool in
                    if(extToListen.contains(eachURL.pathExtension)) {
                        return true
                    }
                    return false
                });
            }
        }
        return filteredURLS
    }
}

extension FTDocumentMigration {
    static func getNS2MigrationDataSource() -> NS2MigrationSource {
        let source: NS2MigrationSource

        // Check whether the NS2 app is installed or not
        if isNS2AppInstalled() {

            // Check NS2 iCloud Status
            if isNS2iCloudTurnedOn() {
                source = .cloud
            } else {
                source = .local
            }
        } else {
            source = .doesNotSupport
        }
        return source
    }

    static func isNS2AppInstalled() -> Bool {
        guard let ns2URL = URL(string: ns2URLScheme) else {
            return false
        }
        let canOpen = UIApplication.shared.canOpenURL(ns2URL)
        return canOpen
    }

    static func isNS2iCloudTurnedOn() -> Bool {
        guard let ns2UserDefaults = UserDefaults(suiteName: FTSharedGroupID.getNS2AppGroupID()) else {
            fatalError("Make sure the \(FTSharedGroupID.getNS2AppGroupID()) added in capabilities")
        }

        let isNS2iCloudOn = ns2UserDefaults.iCloudOn
        return isNS2iCloudOn
    }
}
