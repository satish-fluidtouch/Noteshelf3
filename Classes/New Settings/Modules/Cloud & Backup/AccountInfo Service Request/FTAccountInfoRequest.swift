//
//  FTAccountInfoRequest.swift
//  Noteshelf
//
//  Created by Siva on 24/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTAccountInfoRequest: NSObject {
    class func accountInfoRequestForType(_ cloudType: FTAccount) -> FTAccountInfoRequest {
        var serviceRequest: FTAccountInfoRequest!;

        switch cloudType {
        case .dropBox:
            serviceRequest = FTAccountInfoRequestDropbox();
        case .evernote:
            serviceRequest = FTAccountInfoRequestEvernote();
        case .oneDrive:
            serviceRequest = FTAccountInfoRequestOneDrive();
        case .googleDrive:
            serviceRequest = FTAccountInfoRequestGoogleDrive()
        case .webdav:
            serviceRequest = FTAccountInfoRequestWebdav()
        }
        return serviceRequest;
    }

    func isLoggedIn() -> Bool {
        preconditionFailure("You should override this method")
    }
    func accountInfo(onUpdate updateBlock: ((FTCloudAccountInfo) -> Void), onCompletion completionBlock : @escaping ((FTCloudAccountInfo, NSError?) -> Void)) {
        preconditionFailure("You should override this method")
    }

    func showLoginView(withViewController viewController: UIViewController, completion: @escaping ((Bool) -> Void)) {
        //subclass should override
        preconditionFailure("You should override this method")
    }

    func logOut(_ onCompletion : @escaping ((Bool) -> Void)) {
        preconditionFailure("You should override this method")
    }

}
