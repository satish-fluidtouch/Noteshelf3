//
//  FTPasswordPolicy.swift
//  Noteshelf
//
//  Created by Narayana on 24/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum PasswordPolicy {
    case success
    case failedToMatch
    case empty
    case missingHint
    
    func showErrorMessage(onController: UIViewController?) {
        switch self {
            case .failedToMatch:
                let alert = UIAlertController(title: NSLocalizedString("PasswordsDontMatch", comment: "Passwords Don't Match"), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
                onController?.present(alert, animated: true, completion: nil)
            
            case .empty:
                let alert = UIAlertController(title: NSLocalizedString("EnterAPassword", comment: "Enter a password"), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
                onController?.present(alert, animated: true, completion: nil)
            
            case .missingHint:
                let alert = UIAlertController(title: NSLocalizedString("EnterPasswordHint", comment: "Enter a password"), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
                onController?.present(alert, animated: true, completion: nil)
            default:
                break
        }
    }
}

class FTDocumentPin: NSObject {
    var pin:String?
    var hint:String?
    var isTouchIDEnabled:Bool!
    
    convenience init(pin:String?, hint:String?, isTouchIDEnabled:Bool!) {
        self.init()
        self.pin = pin
        self.hint = hint
        self.isTouchIDEnabled = isTouchIDEnabled;
    }
}
