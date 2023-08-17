//
//  FTNoBandCoverStyle.swift
//  Noteshelf
//
//  Created by Siva on 26/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTNoBandCoverStyle: FTCustomCoverStyleProtocol {
    var customCoverStyle: FTCustomCoverStyle {
        return .noBand
    }
    
    var name: String! {
        return NSLocalizedString("NoBand", comment: "No Band");
    };
    var styleImageName: String! {
        return "customcover1";
    };
    var canChangeColors: Bool! {
        return false;
    };
    var hasTitle: Bool! {
        return false;
    };
    var borderWidth: CGFloat! {
        return 0;
    };
    
    var hasBand: Bool {
        return false;
    }
    
    var hasBlurredBand: Bool {
        return false;
    }

}
