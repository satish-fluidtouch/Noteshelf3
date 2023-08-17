//
//  FTScanDocumentService.swift
//  Noteshelf
//
//  Created by Amar on 23/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import VisionKit

protocol FTScanDocumentServiceDelegate : NSObjectProtocol {
    func scanDocumentService(_ service : FTScanDocumentService, didFinishWith url: URL);
    func scanDocumentServiceDidCancel(_ service : FTScanDocumentService);
    func scanDocumentService(_ service : FTScanDocumentService, didFailWithError error: Error);
}

extension FTScanDocumentServiceDelegate
{
    func scanDocumentServiceDidCancel(_ service : FTScanDocumentService)
    {
        #if DEBUG
        debugPrint("scanDocumentServiceDidCancel is optional. Can be override");
        #endif
    }
    
    func scanDocumentService(_ service : FTScanDocumentService, didFailWithError error: Error)
    {
        #if DEBUG
        debugPrint("scanDocumentService:didFailWithError: is optional. Can be override");
        #endif
    }
}

private var serviceInstance = [FTScanDocumentService]();

class FTScanDocumentService: NSObject {

    weak var delegate : FTScanDocumentServiceDelegate?;
    
    required init(delegate inDel : FTScanDocumentServiceDelegate) {
        super.init();
        delegate = inDel;
        self.addToUsedQueue();
    }
    
    deinit {
        #if DEBUG
        debugPrint("scanDocument : deinit");
        #endif
    }
    
    static func controllerForScanning() -> AnyClass {
        if #available(iOS 13.0, *) {
            if(VNDocumentCameraViewController.isSupported) {
                return VNDocumentCameraViewController.self
            }
        }
        #if !targetEnvironment(macCatalyst)
        return ScanViewController.self
        #else
        return VNDocumentCameraViewController.self
        #endif
    }

    func startScanningDocument(onViewController : UIViewController)
    {
        var showOldApproach = true;
        if #available(iOS 13.0, *) {
            if(VNDocumentCameraViewController.isSupported) {
                showOldApproach = false;
                let documentScanner = VNDocumentCameraViewController.init();
                documentScanner.delegate = self;
                onViewController.present(documentScanner, animated: true, completion: nil);
            }
        }
        #if !targetEnvironment(macCatalyst)
        if(showOldApproach) {
            let scanStoryBoard:UIStoryboard = UIStoryboard.init(name: "Scanner", bundle: nil)
            if let scanController:ScanViewController = scanStoryBoard.instantiateViewController(withIdentifier: "ScanViewController") as? ScanViewController {
                scanController.modalPresentationStyle = .fullScreen
                scanController.scanDelegate = self;
                onViewController.present(scanController, animated: true)
            }
        }
        #endif
    }
    private func addToUsedQueue() {
        serviceInstance.append(self);
    }

    private func removeFromUsedQueue() {
        if let index = serviceInstance.index(of: self) {
            serviceInstance.remove(at: index);
        }
    }
}

#if !targetEnvironment(macCatalyst)
extension FTScanDocumentService : FTScanDocumentDelegate
{
    func scanDocumentDidCancel(_ viewController: ScanViewController) {
        self.delegate?.scanDocumentServiceDidCancel(self)
        self.removeFromUsedQueue();
    }
    
    func scanDocumentDidFinish(_ viewController: ScanViewController, withFileUrl fileURL: URL) {
        self.delegate?.scanDocumentService(self, didFinishWith: fileURL);
        self.removeFromUsedQueue();
    }
}
#endif

extension FTScanDocumentService : VNDocumentCameraViewControllerDelegate
{
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var loadingIndicator : FTLoadingIndicatorViewController?;
        var presentingController : UIViewController?
//        if let rootVC =  controller.presentingViewController as? FTRootViewController {
//            if let baseShelf = rootVC.children.first as? FTBaseShelfViewController{
//                presentingController = baseShelf.currentShelfVc
//            }
//        }
        if presentingController == nil {
            presentingController = controller.presentingViewController;
        }
        controller.dismiss(animated: true) {
            if let controller = presentingController {
                loadingIndicator = FTLoadingIndicatorViewController.show(onMode: .activityIndicator,
                                                                         from: controller,
                                                                         withText: NSLocalizedString("Generating", comment: "Generating..."),
                                                                         andDelay: 0.1);
            }
            DispatchQueue.global().async {
                let docURL = FTPDFFileGenerator().generatePDFWithDocumentCameraScan(scan);
                DispatchQueue.main.async { [weak self, weak loadingIndicator] in
                    loadingIndicator?.hide();
                    if let stringSelf = self {
                        stringSelf.delegate?.scanDocumentService(stringSelf, didFinishWith: docURL);
                    }
                    self?.removeFromUsedQueue();
                }
            }
        }
    }
    
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController)
    {
        controller.dismiss(animated: true) {
            self.delegate?.scanDocumentServiceDidCancel(self);
            self.removeFromUsedQueue();
        }
    }
    
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        self.delegate?.scanDocumentService(self, didFailWithError: error);
        self.removeFromUsedQueue();
    }
}
