//
//  FTCutOutPhotoCoverStyle.swift
//  Noteshelf
//
//  Created by Siva on 26/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTCutOutPhotoCoverStyle: FTCustomCoverStyleProtocol {
    var name: String! {
        return NSLocalizedString("CutOutPhoto", comment: "Cut-Out Photo");
    };
    var styleImageName: String! {
        return "customcover6";
    };
    var canChangeColors: Bool! {
        return true;
    };
    var hasTitle: Bool! {
        return true;
    };
    var borderWidth: CGFloat! {
        return 6;
    };
    
    var hasBand: Bool {
        return true;
    }
    
    var hasBlurredBand: Bool {
        return false;
    }
    
    var maskImage: UIImage? {
        return UIImage(named: "custommask3");
    };
    
    var backgroundType: FTCoverBackgroundType {
        return .color;
    };
    
    var contentInset: UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6);
    };
    
    var customCoverStyle: FTCustomCoverStyle {
        return .cutoutPhoto
    }

}

