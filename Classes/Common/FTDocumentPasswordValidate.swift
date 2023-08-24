//
//  FTNoteshelfDocument_PasswordValidation.swift
//  Noteshelf
//
//  Created by Amar on 29/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTDocumentPasswordValidate : NSObject {
    class func validateShelfItem(shelfItem : FTShelfItemProtocol,
                                 onviewController : UIViewController,
                                 onCompletion: FTPinCompletionCallBack?)
    {
        guard let docItem = shelfItem as? FTDocumentItemProtocol,
            let docID = docItem.documentUUID else {
            onCompletion?(nil,false,false);
            return;
        }
        let doc = FTDocumentFactory.documentForItemAtURL(shelfItem.URL);
        guard let docToBeOpened = doc as? FTDocument else {
            onCompletion?(nil,false,false);
            return;
        }
        
        if docToBeOpened.isPinEnabled() {
            let biometricManager = FTBiometricManager()
            if biometricManager.isTouchIDEnabled(forUUID: docID) {
                biometricManager.evaluateTouchID(for: shelfItem,
                                                          from: onviewController,
                                                          with: { (success, pin, _) in
                                                            onCompletion?(pin,success,false);
                });
                return;
            }
            func showPasswordAlert() {
                biometricManager.showPasswordAlert(for: shelfItem, from: onviewController) { success, pin, error in
                    if error == nil {
                        onCompletion?(pin,success,true);
                    } else {
                        onCompletion?(pin,success,false);
                    }
                }
            }
            if let presentedViewController = onviewController.presentedViewController {
                presentedViewController.dismiss(animated: true) {
                    showPasswordAlert()
                }
            } else {
                showPasswordAlert()
            }
        }
        else {
            onCompletion?(nil,true,false);
        }
    }
}
