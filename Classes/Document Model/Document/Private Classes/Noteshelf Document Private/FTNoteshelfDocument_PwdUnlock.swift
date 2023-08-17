//
//  FTNoteshelfDocument_PwdUnlock.swift
//  Noteshelf
//
//  Created by Amar on 14/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTNoteshelfDocument
{
    internal func unlockTemplateDocument(templatename : String,
                                         onViewController viewContorller: UIViewController?,
                                         onCompletion : @escaping (_ pin:String?, _ error:NSError?,_ isTouchIDEnabled : Bool) -> ())
    {
        if(self.fileURL.isPinEnabledForDocument()) {
            
            guard let onViewController = viewContorller else {
                fatalError("viewContorller is nil");
            }
            FTCLSLog("Notebook Template : Locked Template");
            var pinReuqestContorller : FTPinRequestViewController?;
            pinReuqestContorller = FTPinRequestViewController.show(from: onViewController,
                                                                   title: templatename,
                                                                   onCompletion:
                { (pin, isTouchIDEnabled,cancelled) in
                    if let enteredPin = pin {
                        self.authenticate(enteredPin, coordinated: false, completion: { (success, error) in
                            if success {
                                FTCLSLog("Notebook Template : Unlocked Successfully");
                                pinReuqestContorller!.dismiss(animated: true, completion: {
                                    onCompletion(pin,nil,isTouchIDEnabled);
                                });
                            }
                            else {
                                FTLogError("Notebook Template : Failed to Unlock");
                                let notification = Notification(name: Notification.Name(rawValue: "FTDidFailedToAuthenticate"), object: error, userInfo: nil)
                                NotificationCenter.default.post(notification)
                            }
                        });
                    }
                    else {
                        pinReuqestContorller?.dismiss(animated: true, completion: nil);
                        onCompletion(nil,FTDocumentCreateErrorCode.error(.cancelled),false);
                    }
            });
            pinReuqestContorller?.showTouchIDOptions = false;
        }
        else {
            onCompletion(nil,nil,false);
        }
    }
}
