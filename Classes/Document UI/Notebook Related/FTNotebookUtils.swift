//
//  FTNotebookUtils.swift
//  Noteshelf
//
//  Created by Amar on 27/9/16.
//
//

import Foundation

class FTNotebookUtils : NSObject
{
    static func checkIfAudioIsNotPlaying(forDocument document : FTDocumentProtocol,
                                      InAnyOf selectedPages: NSSet = NSSet(),
                                      alertMessage message : String,
                                      onViewController : UIViewController,
                                      onCompletion block : ((Bool) -> Void)?)
    {
        let  state = FTAudioSessionManager.sharedSession().activeSessionState();
        guard state != .stateNone else {
            block?(true);
            return;
        }

        guard let model = FTAudioSessionManager.sharedSession()?.activeSession()?.audioRecording else {
            block?(true);
            return;
        }

        guard let parentDoc = model.representedObject?.associatedNotebookPage()?.parentDocument,
            parentDoc.hash == document.hash else {
            block?(true);
            return;
        }

        let session = FTAudioSessionManager.sharedSession()?.activeSession()
        if (onViewController.view.window?.hash != session?.windowHash()) {
            block?(true);
            return;
        }
        
        if selectedPages.count != 0, let pageInRecording = model.representedObject?.associatedNotebookPage(), !selectedPages.contains(pageInRecording) {
            block?(true)
            return
        }
        
        if(.stateRecording == state) {
            let alert = UIAlertController.init(title: "", message: message, preferredStyle: UIAlertController.Style.alert);
            
            let defaultAction = UIAlertAction.init(title: NSLocalizedString("StopRecord", comment: "StopRecord"), style: UIAlertAction.Style.default, handler: { (_) in
                let session = FTAudioSessionManager.sharedSession().activeSession();
                session?.stopRecording();
                block?(true);
            });
            
            let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { (_) in
                block?(false);
            });
            
            alert.addAction(defaultAction);
            alert.addAction(cancelAction);

            onViewController.present(alert, animated: true, completion: nil);
        }
        else {
            let session = FTAudioSessionManager.sharedSession().activeSession();
            session?.stopPlayback();
            block?(true);
        }
    }
}
