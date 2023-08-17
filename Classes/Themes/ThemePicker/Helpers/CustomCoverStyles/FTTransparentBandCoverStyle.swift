//
//  FTTransparentBandCoverStyle.swift
//  Noteshelf
//
//  Created by Siva on 26/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTTransparentBandCoverStyle: FTCustomCoverStyleProtocol {
    var name: String! {
        return NSLocalizedString("TransparentBand", comment: "Transparent Band");
    };
    var styleImageName: String! {
        return "customcover2";
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
        return false;
    }
    var hasTransparentBand: Bool {
        return true;
    };
    
    var customCoverStyle: FTCustomCoverStyle {
        return .transparentBand
    }

}
