//
//  FTCustomCoverStyleProtocol.swift
//  Noteshelf
//
//  Created by Siva on 26/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTCoverBackgroundType {
    case image
    case color
}

enum FTCustomCoverStyle {
    case noBand
    case transparentBand
    case blurredBand
    case bottomPhoto
    case mosaicPhoto
    case cutoutPhoto
}

protocol FTCustomCoverStyleProtocol {
    var name: String! {get};
    var styleImageName: String! {get};
    var canChangeColors: Bool! {get};
    var hasTitle: Bool! {get};
    var borderWidth: CGFloat! {get};
    var hasBand: Bool {get};
    var hasBlurredBand: Bool {get};
    var hasTransparentBand: Bool {get};
    var maskImage: UIImage? {get};
    var backgroundType: FTCoverBackgroundType {get};
    var contentInset: UIEdgeInsets {get};
    var customCoverStyle: FTCustomCoverStyle {get}
}

extension FTCustomCoverStyleProtocol {
    var hasTransparentBand: Bool {
        return false;
    };
    
    var maskImage: UIImage? {
        return nil;
    };
    
    var backgroundType: FTCoverBackgroundType {
        return .image;
    };
    
    var contentInset: UIEdgeInsets {
        return UIEdgeInsets.zero;
    };
}
