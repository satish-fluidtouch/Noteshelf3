//
//  FTImportFileHandler.swift
//  Noteshelf
//
//  Created by Matra on 07/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

public protocol FTImportFileHandlerDelegate : AnyObject
{
    var supportsNoteshelfFormat : Bool {get};
    var supportsAudioFileImport : Bool {get};
    var allowsMultipleSelection : Bool {get};

    func importFileHandler(_ handler : FTImportFileHandler,didFinishingPickingURL urls: [URL]);
}

extension FTImportFileHandlerDelegate {
    public var supportsNoteshelfFormat : Bool {
        return false;
    }
    public var allowsMultipleSelection : Bool {
        return false;
    }

    public var supportsAudioFileImport : Bool {
        return false;
    }
}

@objc
public class FTImportFileHandler: NSObject, UIDocumentPickerDelegate {
    private weak var delegate : FTImportFileHandlerDelegate?
    
    public required init(withDelegate del: FTImportFileHandlerDelegate)
    {
        super.init();
        self.delegate = del;
    }
    
    public func importFile(onViewController : UIViewController) {
        var supportedUTIs = supportedUTITypesForDownload()
        if let del = self.delegate, del.supportsNoteshelfFormat {
            supportedUTIs.append(UTI_TYPE_NOTESHELF_BOOK)
            supportedUTIs.append(UTI_TYPE_NOTESHELF_NOTES)
        }
        if let del = self.delegate, del.supportsAudioFileImport {
            supportedUTIs.append(contentsOf:supportedAudioUTITypes());
        }
        
        var uttypes = [UTType]();
        supportedUTIs.forEach { eachType in
            if let type = UTType(eachType) {
                uttypes.append(type);
            }
        }
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: uttypes,asCopy: true)

        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        documentPicker.allowsMultipleSelection = self.delegate?.allowsMultipleSelection ?? false;

        onViewController.present(documentPicker, animated: true, completion: nil)
    }
    
    public func insertFrom(onViewController : UIViewController) {
        let supportedTypes = ["public.audio","public.image", "public.jpeg", "public.png"];
        var uttypes = [UTType]();
        supportedTypes.forEach { eachType in
            if let type = UTType(eachType) {
                uttypes.append(type);
            }
        }
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: uttypes, asCopy: true);

        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        documentPicker.allowsMultipleSelection = self.delegate?.allowsMultipleSelection ?? false;
        onViewController.present(documentPicker, animated: true, completion: nil)
    }
    // MARK: - UIDocumentPickerDelegate Methods
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            self.delegate?.importFileHandler(self, didFinishingPickingURL: urls);
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        #if DEBUG
        debugPrint("documentPickerWasCancelled");
        #endif
    }
}

