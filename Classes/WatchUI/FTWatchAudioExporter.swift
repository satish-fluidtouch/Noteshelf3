//
//  FTWatchAudioExporter.swift
//  Noteshelf
//
//  Created by Amar on 19/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWatchAudioExporter: NSObject {

    fileprivate weak var presentingViewController : UIViewController?
    #if !targetEnvironment(macCatalyst)
    fileprivate var audioShareInteractionController : UIDocumentInteractionController?
    fileprivate var audioExportIsSendingToOtherApp = false;
    fileprivate var completionExecution : (()->())?;
    #endif
    
    deinit {
        #if DEBUG
        debugPrint("FTWatchAudioExporter deinit");
        #endif
    }

    required init(baseViewController : UIViewController) {
        super.init();
        self.presentingViewController = baseViewController;
    }

    private var onViewController: UIViewController!

    func performExport(watchRecording recordedAudio : FTWatchRecording,
                       onViewController : UIViewController)
    {
        let loadingIndicatorViewController =  FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: onViewController, withText: NSLocalizedString("Exporting", comment: "Exporting..."));
        self.onViewController = onViewController
        let fileName = "Watch Recording_".appending(recordedAudio.audioTitle);
        let tempURL = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension(audioFileExtension);
        try? FileManager().removeItem(at: tempURL);
        FileManager.copyCoordinatedItemAtURL(recordedAudio.filePath!, toNonCoordinatedURL: tempURL, onCompletion: { (success, error) in
            loadingIndicatorViewController.hide();
            if(nil != error) {
                error?.showAlert(from: onViewController);
            }
            else {
                #if targetEnvironment(macCatalyst)
                let audioShareControlelr = UIDocumentPickerViewController.init(urls: [tempURL], in: .moveToService);
                self.presentingViewController?.present(audioShareControlelr,
                                                       animated: true,
                                                       completion: nil);
                #else
                self.audioShareInteractionController = UIDocumentInteractionController.init(url: tempURL)
                self.audioShareInteractionController?.name = fileName
                self.audioShareInteractionController?.delegate = self;
                self.audioShareInteractionController?.presentPreview(animated: true);

                self.completionExecution = {
                    if let contentURL = self.audioShareInteractionController?.url {
                        try? FileManager().removeItem(at: contentURL);
                    }
                    self.audioShareInteractionController = nil;
                    self.audioExportIsSendingToOtherApp = false;
                }
                #endif
            }
        });
    }
}

#if !targetEnvironment(macCatalyst)
extension FTWatchAudioExporter : UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return onViewController
    }

    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        if(!self.audioExportIsSendingToOtherApp) {
            self.completionExecution?();
        }
    }
    
    func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        self.audioExportIsSendingToOtherApp = true;
    }
    
    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        self.audioExportIsSendingToOtherApp = false;
        self.completionExecution?();
    }
}
#endif
