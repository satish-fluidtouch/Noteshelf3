//
//  URL+ImagePath.swift
//  Noteshelf
//
//  Created by Dev_Guest on 28/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension URL {
   
    func isCloudItem() -> Bool
    {
        if(self.isUbiquitousFileExists()) {
            return true;
        }
        /*
        if(nil == icloudURL) {
            URL.triggerICloud();
        }

        if let ubiPath = icloudURL {
            if(self.urlByDeleteingPrivate().path.contains(ubiPath.urlByDeleteingPrivate().path)) {
                return true;
            }
        }
         */
        return false;
    }
}
