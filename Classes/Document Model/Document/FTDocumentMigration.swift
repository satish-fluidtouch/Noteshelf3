//
//  FTDocumentMigration.swift
//  Noteshelf3
//
//  Created by Akshay on 01/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTMigrationError: Error {
    case unfiledCollectionNotFound
    case unableToCreateDocument
}

final class FTDocumentMigration {
    static func canSupportMigration() -> Bool {
        guard let ns2URL = URL(string: "com.fluidtouch.noteshelf://") else {
            return false
        }
        let canOpen = UIApplication.shared.canOpenURL(ns2URL)
        return canOpen
    }

    static func showNS3MigrationAlert(on controller: UIViewController,
                                      onCopyAction: (() -> Void)?) {
        let alert = UIAlertController(title: "migration.alert.title".localized, message: "migration.alert.message".localized, preferredStyle: UIAlertController.Style.alert)

        let copy = UIAlertAction(title: "migration.alert.copy".localized, style: UIAlertAction.Style.default) { _ in
            onCopyAction?()
        }
        let cancel = UIAlertAction(title: "migration.alert.cancel".localized, style: UIAlertAction.Style.cancel)
        alert.addAction(copy)
        alert.addAction(cancel)
        controller.present(alert, animated: true)
    }

    static func showNS3MigrationSuccessAlert(on controller: UIViewController,
                                             onOpenAction: (() -> Void)?) {
        let alert = UIAlertController(title: "migration.success.alert.title".localized, message: "migration.success.alert.message".localized, preferredStyle: UIAlertController.Style.alert)

        let open = UIAlertAction(title: "migration.alert.open".localized, style: UIAlertAction.Style.default) { _ in
            onOpenAction?()
        }
        let cancel = UIAlertAction(title: "migration.alert.cancel".localized, style: UIAlertAction.Style.cancel)
        alert.addAction(open)
        alert.addAction(cancel)
        controller.present(alert, animated: true)
    }

    static func performNS2toNs3Migration(shelfItem: FTShelfItemProtocol, inPlace: Bool = false, onCompletion: ((_ documentItem: FTDocumentItemProtocol?, _ error: Error?) -> Void)?) {
        do {
            let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "NS3Migration")
            if(!FileManager().fileExists(atPath: temporaryDirectory.path)) {
                try? FileManager().createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil);
            }
            // Change Path extension from `.ns` to `.ns3`
            let fileName = shelfItem.URL.lastPathComponent.deletingPathExtension
            let documentTemporaryLocation = temporaryDirectory.appendingPathComponent(shelfItem.URL.lastPathComponent)

            // Remove if something already exists
            try? FileManager().removeItem(at: documentTemporaryLocation);

            // Copy the notebook to temporary location with new extension
            _ = try FileManager().coordinatedCopy(fromURL: shelfItem.URL, toURL: documentTemporaryLocation);


//            if inPlace {
//                // Generate path to the original shelf/group
//                let destinationCollection = shelfItem.URL.deletingLastPathComponent()
//                var destinationURL = destinationCollection.appendingPathComponent(fileName).appendingPathExtension(FTFileExtension.ns3)
//
//                // Create unique name if required
//                if(FileManager().fileExists(atPath: destinationURL.path)) {
//                    let uniqueName = FileManager.uniqueFileName(destinationURL.lastPathComponent, inFolder: destinationCollection);
//                    destinationURL = destinationCollection.appendingPathComponent(uniqueName)
//                }
//
//                // When we're using the same iCloud container, i.e, in Production, when In Place option is chosen, we must replace the current document with ns3.
//                // With this, the book will not be shown in the NS2 as we're not listening to ns3 extension changes in ns2
//                _ = try FileManager().coordinatedMove(fromURL: documentTemporaryLocation, toURL: destinationURL)
//                onCompletion?(destinationURL, nil)
//            }
//            else {
                // When the user choses copy option, we must regenrate Document UUID, for this purpose, we're using the existing approach.
                FTDocumentFactory.prepareForImportingAtURL(documentTemporaryLocation) { error, document in
                    if let fileURL = document?.URL {
                        let title = fileURL.deletingPathExtension().lastPathComponent;
                        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { uncategorised in
                            if let uncategorised {
                                uncategorised.addShelfItemForDocument(fileURL,
                                                                toTitle: title,
                                                                toGroup: nil,
                                                                onCompletion: { (error, item) in
                                    if let item, error == nil {
                                        debugLog("Migration success")
                                        onCompletion?(item, nil)
                                    } else {
                                        debugLog("Migration Failure")
                                        onCompletion?(nil, error)
                                    }
                                });
                            } else {
                                onCompletion?(nil, FTMigrationError.unfiledCollectionNotFound)
                            }
                        }
                    }
                    else {
                        onCompletion?(nil, FTMigrationError.unableToCreateDocument)
                    }
                }
//            }
            // Move notebook back to original shelf/group
        } catch {
            debugLog("Migration Error \(error)")
            onCompletion?(nil, error)
        }
    }
}
