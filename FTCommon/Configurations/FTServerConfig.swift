//
//  FTServerConfig.swift
//  Noteshelf
//
//  Created by Amar on 7/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

#if DEBUG || BETA
let userProductionServer = false; //turn it to false if wants to test of dev and beta bucket in debug or BETA builds
#endif

public class FTServerConfig: NSObject {
    #if DEBUG || BETA
    static let awsResourceURLDev = URL(string: "https://s3.amazonaws.com/noteshelf2-store-dev-env")!
    #endif
    static let awsResourceURL = URL(string: "https://noteshelfv2-public.s3.amazonaws.com")!
    static let chinaRegionURL = URL(string: "http://noteshelf.net/NS2_Store_China")!


    class func hostURL() -> URL {
        if(isInChinaRegion()) {
            return FTServerConfig.chinaRegionURL;
        }
        #if DEBUG || BETA
        if(userProductionServer) {
            return FTServerConfig.awsResourceURL;
        }
        return FTServerConfig.awsResourceURLDev;
        #else
        return FTServerConfig.awsResourceURL;
        #endif
    }
    
    private class var storePath: String {
        if(isInChinaRegion()) {
            return "v4";
        }
        return "store/v4";
    }
    
    private class func storeURL() -> URL
    {
        let hostURL = self.hostURL();
        #if DEBUG || BETA
        if(userProductionServer) {
            return hostURL.appendingPathComponent(self.storePath);
        }
        return hostURL.appendingPathComponent("store-v4");
        #else
        return hostURL.appendingPathComponent(self.storePath);
        #endif
    }

    public class func themesMetadataURL() -> URL {
        return self.storeURL().appendingPathComponent("Themes Metadata/v8");
    }
}
