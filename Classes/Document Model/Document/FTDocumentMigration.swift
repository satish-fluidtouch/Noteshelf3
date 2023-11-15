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
private let ns2URLScheme = "com.fluidtouch.noteshelf://"
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

struct FTMigrationContainerData {
    var bookUrls: [URL]?
    var indexUrls: [URL]?
     
    init(bookUrls: [URL], indexUrls: [URL]) {
        self.bookUrls = bookUrls
        self.indexUrls = indexUrls
    }
}

final class FTDocumentMigration {
    static let migrationQueue = DispatchQueue(label: "com.fluidtouch.noteshelf3.migration")
    static var migratedPlistUrl : URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:  FTUtils.getNS2GroupId())?.appendingPathComponent("migratedBooks.plist")
    }
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
             let lastModificationDate = url.fileModificationDate
             let fileCreationDate = url.fileCreationDate
             // When the user choses copy option, we must regenrate Document UUID, for this purpose, we're using the existing approach.
             FTDocumentFactory.prepareForImportingAtURL(url) { error, document in
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
    
    static func fetchMigratedPlist() -> [String: Any] {
        var data = [String: Any]()
        if let plistUrl = migratedPlistUrl, let dict = NSDictionary(contentsOf: plistUrl) as? [String: Any] {
            data = dict
        }
        return data
    }
    
    static func updateMigratedPlist(dict: [String: Any]) {
        if let plistUrl = migratedPlistUrl {
            (dict as NSDictionary).write(to: plistUrl, atomically: true)
        }
    }

    
    static func intiateNS2ToNS3MassMigration(on controller: UIViewController, _ onCompletion: @escaping (Bool, NSError?) -> Void) -> Progress {

        let progress = Progress()
        progress.isCancellable = true
        progress.isPausable = true
        if let ns3MigrationContainerURL =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:  FTUtils.getNS2GroupId())?.appendingPathComponent("Noteshelf3_migration"), let migrationContainerData = self.contentsOfURL(ns3MigrationContainerURL) {
            var noteBookUrls = migrationContainerData.bookUrls ?? [URL]()
            var sortIndexUrls = migrationContainerData.indexUrls ?? [URL]()
            let totalItems = noteBookUrls.count + sortIndexUrls.count
            progress.totalUnitCount = Int64(totalItems)
            FTCLSLog("---Migration In Progress---")
            var migratedItems = fetchMigratedPlist()
            func copyIndexes() {
                guard !progress.isCancelled else {
                    onCompletion(false, nil)
                    return
                }
                guard !progress.isPaused else {
                    return
                }
                if let indexUrl = sortIndexUrls.first, indexUrl.pathExtension == FTFileExtension.sortIndex {
                    runInMainThread {
                        FTDocumentMigration.copyIndexItem(indexUrl)
                        progress.localizedDescription = "Indexing"
                        progress.completedUnitCount += 1;
                        sortIndexUrls.removeFirst()
                        copyIndexes()
                    }
                } else {
                    FTDocumentMigration.updateMigratedPlist(dict: migratedItems)
                    // TODO: Continue the Pinning process as last step, once the migration process is completed for booka
                    FTDocumentMigration.getPinnedItemsRelativePaths()
                    onCompletion(true, nil)
                }
            }
            func migrateBooks() {
                guard !progress.isCancelled else {
                    onCompletion(false, nil)
                    return
                }
                guard !progress.isPaused else {
                    return
                }
                if let firstItem = noteBookUrls.first {
                    let displayPath = firstItem.displayRelativePathWRTCollection()
                    let fileModificationDate = firstItem.fileModificationDate.data
                    FTDocumentMigration.performNS2toNs3MassMigration(url: firstItem) { url, error in
                        progress.localizedDescription = url?.lastPathComponent.deletingPathExtension ?? "";
                        migratedItems[displayPath] = ["modifiedDate": fileModificationDate]
                        progress.completedUnitCount += 1;
                        noteBookUrls.removeFirst()
                        migrateBooks()
                    }
                } else {
                    copyIndexes()
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
    
    static func copyIndexItem(_ indexUrl: URL) {
        do {
            let destUrl =  FTUtils.noteshelfDocumentsDirectory().appendingPathComponent("User Documents").appendingPathComponent(indexUrl.relativePathWRTCollection())
            let parentURL = destUrl.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parentURL.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
            }
            if !FileManager().fileExists(atPath: destUrl.path(percentEncoded: false)) {
                try FileManager.default.coordinatedMove(fromURL: indexUrl, toURL: destUrl)
            }
        }  catch {
            debugLog(error.localizedDescription)
        }
    }
    
    private static func isPinEnabledForDownloadedDocument(url: URL) -> Bool {
        let securityPath = url.appendingPathComponent("secure.plist");
        if(FileManager().fileExists(atPath: securityPath.path)) {
            return true;
        }
        return false;
    }

    static func contentsOfURL(_ url: URL) -> FTMigrationContainerData? {
        if let urls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles) {
            let filteredURLS = FTDocumentMigration.filterItemsMatchingExtensions(urls);
            var notebookUrlList: [URL] = [URL]()
            var sortIndexUrls: [URL] = [URL]()
            filteredURLS.enumerated().forEach({ (_,eachURL) in
                if eachURL.pathExtension == FTFileExtension.shelf || eachURL.pathExtension == FTFileExtension.group {
                    let data = self.contentsOfURL(eachURL)
                    if let bookUrls = data?.bookUrls, let indexUrls = data?.indexUrls {
                        if !bookUrls.isEmpty {
                            notebookUrlList.append(contentsOf: bookUrls);
                        }
                        if !indexUrls.isEmpty {
                            sortIndexUrls.append(contentsOf: indexUrls);
                        }
                    }
                } else if eachURL.pathExtension == FTFileExtension.sortIndex {
                    sortIndexUrls.append(eachURL);
                } else {
                    notebookUrlList.append(eachURL);
                }
            });
            let migrationData = FTMigrationContainerData(bookUrls: notebookUrlList, indexUrls: sortIndexUrls)
            return migrationData
        } else {
            return nil
        }
    }
    
    static func filterItemsMatchingExtensions(_ items : [URL]?) -> [URL]
    {
        let extToListen = [FTFileExtension.ns2, FTFileExtension.group, FTFileExtension.shelf, FTFileExtension.sortIndex]
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


extension FTDocumentMigration {
    class func getPinnedItemsRelativePaths() -> [String] {
        let pinnedItems = FTPinnedItemsMigration.getNS2PinnedEntries()
        let relativePaths = pinnedItems.compactMap { info -> String? in
            if let fullPath = info["path"] {
                let url = URL(fileURLWithPath: fullPath)
                return url.relativePathWRTCollection()
            } else {
                return nil
            }
        }
        print("pinned", relativePaths)
        return relativePaths
    }
}
