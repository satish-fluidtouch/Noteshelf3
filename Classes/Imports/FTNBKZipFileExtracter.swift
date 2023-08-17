//
//  FTNBKZipFileExtracter.swift
//  Noteshelf
//
//  Created by Amar on 25/03/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

class FTImportItemZip: NSObject {
    var items: [URL] = [URL]();
    
    func removeFileItems() {
        items.forEach { (eachItem) in
            try? FileManager().removeItem(at: eachItem);
        }
    }
}

class FTNBKZipFileExtracter: NSObject {
    static func extractNBKContents(for url: URL,
                                   viewController: UIViewController?,
                                   onCompletion :@escaping (FTImportItem?)->()) {
        DispatchQueue.global().async {
            var importItem: FTImportItem?;
            let unzipPath = NSTemporaryDirectory().appending(UUID().uuidString)
            try? FileManager().removeItem(atPath: unzipPath)
            if SSZipArchive.unzipFile(atPath: url.path, toDestination: unzipPath) {
                let contentsToImport = self.getContentsRecursivelyOfFolder(unzipPath);
                if !contentsToImport.isEmpty {
                    let zipItem = FTImportItemZip();
                    contentsToImport.forEach { (eachItem) in
                        zipItem.items.append(eachItem);
                    }
                    importItem = FTImportItem(item: zipItem, onCompletion: nil);
                }
                DispatchQueue.main.async {
                    onCompletion(importItem);
                }
            }
            else {
                DispatchQueue.main.async {
                    onCompletion(importItem);
                }
            }
        }
    }
    
    private static func getContentsRecursivelyOfFolder(_ url: String) -> [URL] {
        var urlToReturn = [URL]();
        let urlPath = URL(fileURLWithPath: url);
        let contents = try? FileManager().contentsOfDirectory(atPath: url);
        contents?.forEach({ (eachFile) in
            let path = urlPath.appendingPathComponent(eachFile);
            var isDir = ObjCBool(false);
            if FileManager().fileExists(atPath: path.path, isDirectory: &isDir), isDir.boolValue {
                let urls = getContentsRecursivelyOfFolder(path.path);
                urlToReturn.append(contentsOf: urls);
            }
            else if path.pathExtension.lowercased() == nsBookExtension {
                urlToReturn.append(path);
            }
        })
        return urlToReturn;
    }
}

extension UIAlertController {
    static func showAlertIfNeeded(count: Int,
                                   viewController: UIViewController?,
                                   onCompletion: @escaping (Bool) ->()) {
        if let controller = viewController,count > 2 {
            let msg = String(format: NSLocalizedString("NBKImportAlertMsg", comment: "are you sure to import.."), count);
            let alertController = UIAlertController(title: msg,
                                                    message: nil,
                                                    preferredStyle: .alert);
            let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { (_) in
                onCompletion(true);
            }
            alertController.addAction(action);
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { (_) in
                onCompletion(false);
            }
            alertController.addAction(cancel);
            controller.present(alertController, animated: true, completion: nil);
        }
        else {
            onCompletion(true);
        }
    }
}
