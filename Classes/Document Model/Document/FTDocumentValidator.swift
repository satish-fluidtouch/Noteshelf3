//
//  FTDocumentValidator.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 10/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTDocumentValidator: NSObject {
    class func openNoteshelfDocument(for shelfItem: FTShelfItemProtocol,
                                     pin: String?,
                                     onViewController : UIViewController,
                                     onCompletion: ((FTDocumentProtocol?, Error?,FTDocumentOpenToken?) -> Void)?) {
        guard let documentItem = shelfItem as? FTDocumentItemProtocol, documentItem.isDownloaded else {
            onCompletion?(nil, FTDocumentOpenErrorCode.error(.notDownload),nil);
            return;
        }
        
        func openDoc(_ pin : String?) {
            let openRequest = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .write);
            openRequest.pin = pin;
            FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, error) in
                onCompletion?( ( nil == error) ? document : nil , error,token);
            }
        }
        if let documentPin = pin {
            openDoc(documentPin)
        }
        else{
            FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                         onviewController: onViewController) { (pin, success,_) in
                if(success) {
                    openDoc(pin)
                }
                else {
                    onCompletion?(nil, FTDocumentOpenErrorCode.error(.invalidPin), nil);
                }
            }
        }
    }
}
