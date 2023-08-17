//
//  FTPermissionManager.swift
//  Noteshelf
//
//  Created by Akshay on 15/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Intents

@objcMembers class FTPermissionManager : NSObject {
    class func askForSiriPermission(onController controller:UIViewController, shouldForce:Bool, completion:((_ status: Bool) -> Void)?) {
        #if targetEnvironment(macCatalyst)
        completion?(false)
        return;
        #endif
        let status = INPreferences.siriAuthorizationStatus()
        if status == .notDetermined {
            INPreferences.requestSiriAuthorization({ status in
                if status == .authorized {
                    completion?(true)
                    FTCLSLog("Authorized Siri on Prompt")
                } else {
                    completion?(false)
                    FTCLSLog("Siri Authorization Failed")
                }
            })
        } else if status == .authorized {
            completion?(true)
        } else {
            completion?(false)
            if shouldForce {
                let message = String(format: NSLocalizedString("SiriPermissionPopupMsg", comment: "Please allow to access..."), applicationName()!, applicationName()!);
                UIAlertController.showAlert(withTitle: "", message: message, from: controller, withCompletionHandler: nil)
            }
        }
    }
    
    class func isMicrophoneAvailable(onViewController : UIViewController,onCompletion : @escaping (Bool)->()) {
        if(self.microPhoneAvailbale()) {
            onCompletion(true);
        }
        else {
            UIAlertController.showAlert(withTitle: "",
                                        message: NSLocalizedString("MicophoneNotAvailable", comment: ""),
                                        from: onViewController) {
                                            onCompletion(false);
            }
        }
    }
    
    private static func microPhoneAvailbale() -> Bool
    {
        #if targetEnvironment(macCatalyst)
        var isMicAvailable = false
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord);
            try audioSession.setActive(true)
            if let arrayInputs = audioSession.availableInputs {
                if (!arrayInputs.isEmpty) {
                    isMicAvailable = true
                }
            }
        }
        catch {}
        return isMicAvailable;
        #else
        return true;
        #endif
    }
}
