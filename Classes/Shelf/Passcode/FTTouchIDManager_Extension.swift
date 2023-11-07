//
//  FTTouchIDManager_Extension.swift
//  Noteshelf
//
//  Created by Siva on 20/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation;
import LocalAuthentication;
import FTDocumentFramework

extension FTBiometricManager: UITextFieldDelegate {
    func evaluateTouchID(for shelfItem: FTShelfItemProtocol,
                         from viewController: UIViewController,
                         with completionHandler: @escaping ((_ success: Bool, _ pin: String?, _ error: NSError?) -> Void))
    {
        viewController.view.window?.makeKey();
        self.evaluateTouchID(NSLocalizedString("UseFingerPrintToOpenNotebook", comment: "Authentication is required to open this notebook")) { (success, error) in
            if success && nil == error {
                let pin = FTDocument.keychainGetPin(forKey: (shelfItem as! FTDocumentItemProtocol).documentUUID);
                if let pinStored = pin,
                    let docToBeOpened = FTDocumentFactory.documentForItemAtURL(shelfItem.URL) as? FTDocument {
                    docToBeOpened.authenticate(pinStored,
                                               coordinated: true)
                    { (success, error) in
                        if(success) {
                            completionHandler(success, pin, nil);
                        }
                        else {
                            var askForPassowrd = true;
                            if let nserrror = error as NSError? {
                                if(nserrror.domain != "com.Noteshelf.FluidTouch") {
                                    askForPassowrd = false;
                                    completionHandler(success, pin, nil);
                                }
                            }
                            if(askForPassowrd) {
                                self.isAttemptedEarlier = false;
                                self.showPasswordAlert(for: shelfItem,
                                                       from: viewController,
                                                       with: completionHandler);
                            }
                        }
                    };
                }
                else {
                    completionHandler(success, pin, nil);
                }
            }
            else {
                switch (error! as NSError).code {
                case LAError.appCancel.rawValue,LAError.userCancel.rawValue:
                    completionHandler(false, nil, nil);
                default:
                    self.isAttemptedEarlier = false;
                    self.showPasswordAlert(for: shelfItem, from: viewController, with: completionHandler);
                }
            }
        }
    }
    
    func showPasswordAlert(for shelfItem: FTShelfItemProtocol,
                                   from viewController: UIViewController,
                                   attempt : Int = 0,
                                   hint : String? = nil,
                                   with completionHandler: @escaping ((_ success: Bool, _ pin: String?, _ error: NSError?) -> Void))
    {
        var curAttempt = attempt;
        let alertMessage: String;
        if self.isAttemptedEarlier {
            var message = NSLocalizedString("NotCorrectPassword", comment: "That's not the correct password. Please try again.");
            if(attempt == 3) {
                if let availableHint = hint,!availableHint.isEmpty {
                    message = "Hint: " + availableHint
                }
                curAttempt = 0;
            }
            else {
                curAttempt += 1;
            }
            alertMessage = message;
        } else {
            alertMessage = String(format: NSLocalizedString("EnterPasswordToOpenThisNotebook", comment: "Enter the password to open %@"), shelfItem.displayTitle)
        }
     

        let alertController = UIAlertController.init(title: NSLocalizedString("EnterPassword", comment: "Enter Password"), message: alertMessage, preferredStyle: .alert);

        weak var weakAlertController = alertController;
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { (action) in
            let text = weakAlertController?.textFields?.first?.text;
            guard let pin = text, pin.count > 0 else {
                completionHandler(false, nil, nil)
                return;
            };
            if let docToBeOpened = FTDocumentFactory.documentForItemAtURL(shelfItem.URL) as? FTDocument {
                docToBeOpened.authenticate(text, coordinated: true, completion: { (success, error) in
                    if success, nil == error {
                        if let documentUUID = (shelfItem as? FTDocumentItemProtocol)?.documentUUID {
                            FTDocument.keychainSet(pin, forKey: documentUUID)
                        }
                        completionHandler(true, pin, nil);
                    }
                    else {
                        self.isAttemptedEarlier = true;
                        var hintValue : String?;
                        if let er = error as NSError? {
                            hintValue = er.userInfo["hint"] as? String
                        }
                        self.showPasswordAlert(for: shelfItem,
                                                     from: viewController,
                                                     attempt: curAttempt,
                                                     hint: hintValue, with: completionHandler)
                    }
                });
            }
        });
        
        alertController.addAction(okAction);
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"),
                                              style: .cancel,
                                              handler:
            { (_) in
                completionHandler(false, nil, nil);
        });
        alertController.addAction(cancelAction);
        
        alertController.addTextField(configurationHandler: {[weak self] (textFiled) in
            textFiled.delegate = self;
            textFiled.isSecureTextEntry = true;
            textFiled.setDefaultStyle(.defaultStyle);
            textFiled.setStyledPlaceHolder(NSLocalizedString("Password", comment: "Password"), style: .defaultStyle);
        });
        
        viewController.present(alertController, animated: true, completion: nil);
    }
    
    private func validatePin() {
        
    }
    
    //MARK:- UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    static func passwordForNS2Book(with uuid: String) -> String? {
        var passwordToReturn: String?
        let keyChain = KeychainItemWrapper(identifier: NS2_BUNDLE_ID, accessGroup: nil)
        if let data = keyChain?.object(forKey: kSecValueData) as? Data {
            let dict = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self],from: data) as? [String:Any]
            passwordToReturn = dict?[uuid] as? String ?? ""
        }
        return passwordToReturn
    }
    
    static func isTouchIdEnabled(for uuid: String) -> Bool {
        var isTouchEnabled = false
        let keyChain = KeychainItemWrapper(identifier: NS2_BUNDLE_ID, accessGroup: nil)
        if let data = keyChain?.object(forKey: kSecValueData) as? Data {
            if let dict = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self],from: data) as? [String:Any] {
                let passwordToReturn = dict[uuid+"_TouchID"] as? Int ?? 0
                isTouchEnabled = (passwordToReturn == 1) ? true : false
            }
        }
        return isTouchEnabled
    }
    
}
