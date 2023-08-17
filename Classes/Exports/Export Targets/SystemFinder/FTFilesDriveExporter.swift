//
//  FTFilesDriveExporter.swift
//  Noteshelf
//
//  Created by Simhachalam on 28/12/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive

class FTFilesDriveExporter: FTBaseExporter, UIDocumentPickerDelegate {
    var documentPickerController: UIDocumentPickerViewController!
    
    override func export() {
        var itemsToExport = [URL]();
        var itemsToExportPath = [String]();
        
        if let ftExportItems = self.exportItems as? [FTExportItem] {
            ftExportItems.forEach({ (item) in
                if let itemPath = item.representedObject as? String {
                    let url = URL(fileURLWithPath: itemPath);
                    itemsToExportPath.append(url.path);
                    itemsToExport.append(url);
                }
            });
        }
        
        if(!itemsToExport.isEmpty) {
            var pathsToExport : [URL]? = itemsToExport;
            
            //avoid temporarily for export
/*
            let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("notes.zip");
            try? FileManager().removeItem(atPath: tempPath);

            if(itemsToExport.count > 1 || exportFormat == kExportFormatImage || (itemsToExport.count == 1 && exportFormat == kExportFormatPDF)) {
                if(SSZipArchive.createZipFile(atPath: tempPath, withFilesAtPaths: itemsToExportPath)) {
                    pathsToExport = [URL(fileURLWithPath: tempPath)];
                }
                else {
                    pathsToExport = nil;
                }
            }
 */
            if let paths = pathsToExport {
                //Workaround for the failure of export to Finder function from macOS BigSur
                #if targetEnvironment(macCatalyst)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentDocumentPicker(paths)
                }
                #else
                    self.presentDocumentPicker(paths)
                #endif
            }
            else{
                self.delegate.didFailExportWithError(NSError.init(domain: "Noteshelf Export", code: 100, userInfo: nil), withMessage: "Failed");
            }
        }
        else {
            self.delegate.didFailExportWithError(NSError.init(domain: "Noteshelf Export", code: 100, userInfo: nil), withMessage: "Failed");
        }
    }
    
    private func presentDocumentPicker(_ urls: [URL]) {
        self.documentPickerController = UIDocumentPickerViewController.init(urls: urls, in: UIDocumentPickerMode.moveToService)
        self.documentPickerController.delegate = self;
        self.documentPickerController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        self.baseViewController.present(self.documentPickerController, animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerDelegate Methods
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]){
        if controller.documentPickerMode == UIDocumentPickerMode.moveToService {
            self.delegate.didEndExport(withMessage: "ExportComplete".localized);
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
    {
        if controller.documentPickerMode == UIDocumentPickerMode.moveToService {
            self.delegate.didCancelExport();
        }
    }
    
    override func name() -> String! {
        return NSLocalizedString("Files",comment:"Files");
    }
}
