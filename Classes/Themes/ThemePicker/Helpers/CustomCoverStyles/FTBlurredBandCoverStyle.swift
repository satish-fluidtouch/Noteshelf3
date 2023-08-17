//
//  FTBlurredBandCoverStyle.swift
//  Noteshelf
//
//  Created by Siva on 26/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTBlurredBandCoverStyle: FTCustomCoverStyleProtocol {
    var name: String! {
        return NSLocalizedString("BlurredBand", comment: "Blurred Band");
    };
    var styleImageName: String! {
        return "customcover3";
    };
    var canChangeColors: Bool! {
        return false;
    };
    var hasTitle: Bool! {
        return true;
    };
    var borderWidth: CGFloat! {
        return 0;
    };
    
    var hasBand: Bool {
        return true;
    }
    
    var hasBlurredBand: Bool {
        return true;
    }
    
    var customCoverStyle: FTCustomCoverStyle {
        return .blurredBand
    }

}

