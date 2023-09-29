//
//  FTRenderProperties.swift
//  Noteshelf
//
//  Created by Amar on 05/09/18.
//  Copyright © 2018 Fluid Touch. All rights reserved.
//

import UIKit

@objcMembers class FTRenderingProperties : NSObject {
    var synchronously : Bool;
    var cancelPrevious : Bool;
    var renderImmediately : Bool;
    var pageID : String?;
    var forcibly : Bool = false;
    var avoidOffscreenRefresh = false;
    
    public override init() {
        self.synchronously = false;
        self.cancelPrevious = false;
        self.renderImmediately = false;
    }
}
