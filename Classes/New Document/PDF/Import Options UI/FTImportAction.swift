//
//  FTImportAction.swift
//  Noteshelf
//
//  Created by Amar on 12/5/16.
//
//

import Foundation
import UIKit
import MobileCoreServices

protocol FTImportingProtocol {
    func beginImporting(items : [AnyObject])
}

extension FTImportingProtocol {
    func beginImporting(items : [AnyObject]) {

    }
}

class FTImportAction: NSObject,FTFolderPickerDelegate, FTExportImportTargetProtocol, UIDocumentPickerDelegate
{
    weak var parentViewController : UIViewController?
    weak var destinationController : UIViewController?
    var supportsNoteshelfBookImport = true;
    var allowsMultipleFileSelection = true;
    var fileIndex:Int = 0

    init(parentController: UIViewController)
    {
        self.parentViewController = parentController;
    }
    
    override init() {
        super.init();
    }
    
    func performAction(_ sender:UIView)
    {
        
    }
    
    //MARK:- FTExportImportTargetProtocol
    var name: String {
        return "";
    }
    
    var image: UIImage {
        return UIImage();
    }
    
    var smallIcon: UIImage {
        return UIImage();
    }
    
    var persistenceID: String {
        return "";
    };
    
    var defaultActive: Bool {
        return false;
    };
    
    var defaultOrder: Int {
        return 100;
    };
    
    var canDisable: Bool {
        return true;
    };
    
    var isActive: Bool {
        get {
            UserDefaults.standard.register(defaults: ["\(persistenceID)_Active" : NSNumber.init(value: self.defaultActive as Bool)]);
            return UserDefaults.standard.bool(forKey: "\(persistenceID)_Active");
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ("\(persistenceID)_Active"))
            UserDefaults.standard.synchronize();
        }
    };
    
    var order: Int {
        get {
            UserDefaults.standard.register(defaults: ["\(persistenceID)_Order" : NSNumber.init(value: self.defaultOrder as Int)]);
            return UserDefaults.standard.integer(forKey: "\(persistenceID)_Order");
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ("\(persistenceID)_Order"))
            UserDefaults.standard.synchronize();
        }
    };
    
    func downloadFiles(_ files: [Any]!, manager: FTBaseFolderPickerManager!) {
        (self.destinationController as? FTImportingProtocol)?.beginImporting(items: files! as [AnyObject]);
    }
    // MARK: - UIDocumentPickerDelegate Methods
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            (self.destinationController as? FTImportingProtocol)?.beginImporting(items: [url] as [AnyObject]);
        }
    }
}


class FTImportActionItunes : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return "iTunes";
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/iTunes")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/iTunes")!;
    }
    
    override var persistenceID: String {
        return "Import_iTunes";
    };
    
    override func performAction(_ sender:UIView)
    {
        let controller = FTItunesFolderPickerManager.init(rootViewController: self.parentViewController!);
        controller?.delegate = self;
        controller?.supportsNoteshelfBookImport = self.supportsNoteshelfBookImport;
        controller?.allowsMultipleFileSelection = self.allowsMultipleFileSelection
        controller?.showUI(for: FTViewMode.import,
                                 parentPath: nil,
                                 modalPresentationStyle: .formSheet,
                                 onCompletion: { (_ , _) in

        });
    }
}


class FTImportActionAlbum : FTImportAction,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return NSLocalizedString("PhotoAlbum",comment:"Photo Album");
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/Library")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/Library")!;
    }
    
    override var persistenceID: String {
        return "Import_Library";
    };
    
    override var defaultActive: Bool {
        return true;
    };
    
    override var defaultOrder: Int {
        return 2;
    };
    
    override var canDisable: Bool {
        return false;
    };
    
    override func performAction(_ sender:UIView)
    {
        let imagePickerController = UIImagePickerController.init();
        imagePickerController.allowsEditing = false;
        imagePickerController.delegate = self;
        imagePickerController.modalPresentationStyle = .popover;
        
        let popoverPresentationController = imagePickerController.popoverPresentationController;
        popoverPresentationController?.sourceRect = sender.bounds;
        popoverPresentationController?.sourceView = sender;
        self.parentViewController?.dismiss(animated: false) {
            self.destinationController?.present(imagePickerController, animated: true, completion: nil);
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        picker.dismiss(animated: false, completion: nil);

        var picture : UIImage?;
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! String;
        if (mediaType == kUTTypeImage as String)
        {
            picture = info[UIImagePickerController.InfoKey.editedImage] as? UIImage;
            if(picture == nil)
            {
                picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage;
            }
        }
        if(nil != picture) {
            self.downloadFiles([picture!], manager: nil);
        }
    }
}

class FTImportActionDropbox : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return "Dropbox";
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/Dropbox")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/Dropbox")!;
    }
    
    override var persistenceID: String {
        return "Import_Dropbox";
    };
    
    override var defaultActive: Bool {
        return true;
    };
    
    override var defaultOrder: Int {
        return 0;
    };
    
    override func performAction(_ sender:UIView)
    {
        let controller = FTDropboxFolderPickerManager.init(rootViewController: self.parentViewController!);
        controller?.delegate = self;
        controller?.supportsNoteshelfBookImport = self.supportsNoteshelfBookImport;
        controller?.allowsMultipleFileSelection = self.allowsMultipleFileSelection
        controller?.showUI(for: FTViewMode.import,
                                 parentPath: nil,
                                 modalPresentationStyle: .formSheet,
                                 onCompletion:  { (_, _) in
            
        });
    }
}

class FTImportActionGDrive : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return "Google Drive";
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/GDrive")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/GDrive")!;
    }
    
    override var persistenceID: String {
        return "Import_GDrive";
    };
    
    override var defaultActive: Bool {
        return true;
    };
    
    override var defaultOrder: Int {
        return 1;
    };
    
    override func performAction(_ sender:UIView)
    {
        #if !targetEnvironment(macCatalyst)
        let controller = FTGoogleDriveFolderPickerManager.init(rootViewController: self.parentViewController!);
        controller?.delegate = self;
        controller?.allowsMultipleFileSelection = self.allowsMultipleFileSelection
        controller?.supportsNoteshelfBookImport = self.supportsNoteshelfBookImport;
        controller?.showUI(for: FTViewMode.import,
                                 parentPath: nil,
                                 modalPresentationStyle: .formSheet,
                                 onCompletion:  { (_, _) in
            
        });
        #endif
    }
}

class FTImportActionOneDrive : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return "OneDrive";
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/OneDrive")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/OneDrive")!;
    }
    
    override var persistenceID: String {
        return "Import_OneDrive";
    };
    
    override func performAction(_ sender:UIView)
    {
//        let controller = FTOneDriveFolderPickerManager.init(rootViewController: self.parentViewController!);
//        controller?.delegate = self;
//        controller?.supportsNoteshelfBookImport = self.supportsNoteshelfBookImport;
//        controller?.allowsMultipleFileSelection = self.allowsMultipleFileSelection
//        controller?.showUI(for: FTViewMode.import,
//                                 parentPath: nil,
//                                 modalPresentationStyle: .formSheet,
//                                 onCompletion:  { (_, _) in
//
//        });
    }
}
class FTImportActionScanDocument : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return NSLocalizedString("ScanDocument", comment: "Scan Document");
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/ScanDoc")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/ScanDoc")!;
    }
    
    override var persistenceID: String {
        return "Import_ScanDoc";
    };
    
    override func performAction(_ sender:UIView)
    {
        FTCLSLog("Import Scan Click");
        self.parentViewController!.dismiss(animated: true, completion: {
            guard let destController = self.destinationController else {
                fatalError("self.destinationController should not be nil");
            }
            guard let scanDocumentDelegate = destController as? FTScanDocumentServiceDelegate else {
                    fatalError("self.destinationController should confirm to FTScanDocumentServiceDelegate protocol");
            }
            let scanService = FTScanDocumentService.init(delegate: scanDocumentDelegate);
            scanService.startScanningDocument(onViewController: destController);
        })
    }
}
class FTImportActioniCloudDrive : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return NSLocalizedString("Files", comment: "Files");
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/Files")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/Files")!;
    }
    
    override var persistenceID: String {
        return "Import_iCloudDrive";
    };
    
    override func performAction(_ sender:UIView)
    {
        FTCLSLog("Import iCloud Drive Click");
        var supportedUTIs = supportedUTITypesForDownload()
        if(self.supportsNoteshelfBookImport){
            supportedUTIs.append(UTI_TYPE_NOTESHELF_BOOK)
            supportedUTIs.append(UTI_TYPE_NOTESHELF_NOTES)
        }
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: supportedUTIs, in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        
        self.parentViewController?.dismiss(animated: true, completion: {
            self.destinationController?.present(documentPicker, animated: true, completion: nil)
        })
    }
}
class FTImportActionWeLink : FTImportAction
{
    static func isWhiteListed() -> Bool{
        if let isWhilteListed = UserDefaults.standard.object(forKey: "isWeLinkAppWhiteListed") as? Bool{
            return isWhilteListed
        }
        return false
    }
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return "WeLink";
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/WeLink")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/WeLink")!;
    }
    
    override var persistenceID: String {
        return "Import_WeLink";
    };
    
    override func performAction(_ sender:UIView)
    {
        let controller = FTWeLinkFolderPickerManager.init(rootViewController: self.parentViewController!);
        controller?.delegate = self;
        controller?.supportsNoteshelfBookImport = self.supportsNoteshelfBookImport;
        controller?.allowsMultipleFileSelection = self.allowsMultipleFileSelection
        controller?.showUI(for: FTViewMode.import,
                           parentPath: nil,
                           modalPresentationStyle: .formSheet,
                           onCompletion:  { (_, _) in
                            
        });
    }
}

//MARK: - Classkit
class FTPublishAssignmentAction : FTImportAction
{
    //MARK:- FTExportImportTargetProtocol
    override var name: String {
        return "Schoolwork";
    }
    
    override var image: UIImage {
        return UIImage.init(named: "Targets/Icons/swicon")!;
    }
    
    override var smallIcon: UIImage {
        return UIImage.init(named: "Targets/Icons/Small/schoolworkicon")!;
    }
    
    override var persistenceID: String {
        return "Schoolwork";
    };
    
    override var defaultActive: Bool {
        return true;
    };
    
    override func performAction(_ sender:UIView)
    {
    }
}
