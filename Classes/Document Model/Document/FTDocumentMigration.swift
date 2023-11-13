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
        return getNS2MigrationDataSource() != .doesNotSupport
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
