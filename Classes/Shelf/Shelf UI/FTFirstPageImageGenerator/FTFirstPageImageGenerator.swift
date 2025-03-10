//
//  FTFirstPageImageGenerator.swift
//  Noteshelf
//
//  Created by Naidu on 15/05/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objc enum FTCoverLabelStyle:Int{
    case `default`
    case bottom
}

extension FTCoverStyle{
    func coverSize() -> CGSize{
        var size = CGSize.zero
        switch self {
        case .default:
            size = CGSize.init(width: 137, height: 170)
        case .transparent:
            size = CGSize.init(width: 138, height: 171)
        case .audio:
            size = CGSize.init(width: 139, height: 172)
        case .clearWhite:
            size = CGSize.init(width: 140, height: 173)
        }
        return size
    }
}

class FTFirstPageImageGenerator {
    private let targetSize: CGSize
    required init(withTargetSize targetSize:CGSize) {
        self.targetSize = targetSize
    }
    
    func generateCoverImage(forImage image:UIImage, withCoverOverlayImage overlayImage:UIImage?) -> UIImage {
        let imgTargetSize = self.targetSize;
        guard let ftcontext = FTImageContext.imageContext(imgTargetSize, scale: 2) else {
            return image;
        }
        let coverPageRect = CGRect(x: 0, y: 0, width: imgTargetSize.width, height: imgTargetSize.height)
        //**********************************
        let colorCube = CCColorCube.init()
        let colors:[UIColor]? = colorCube.extractDefaultColors(from: image)!
        colors![0].set()
        UIRectFill(coverPageRect)
        
        //**********************************
        var aspectRect = AVMakeRect(aspectRatio: image.size, insideRect: coverPageRect);
        //Portrait mode aspect fill, top align
        if aspectRect.width < aspectRect.height { 
            let aspect = image.size.width / image.size.height
            var rect: CGRect
            if coverPageRect.size.width / aspect > coverPageRect.size.height {
                let height = coverPageRect.size.width / aspect
                rect = CGRect(x: 0, y: (coverPageRect.size.height - height) / 2,
                              width: coverPageRect.size.width, height: height)
            } else {
                let width = coverPageRect.size.height * aspect
                rect = CGRect(x: (coverPageRect.size.width - width) / 2, y: 0,
                              width: width, height: coverPageRect.size.height)
            }
            aspectRect = rect.integral
            
            aspectRect.origin = CGPoint.zero
            let ratio:CGFloat = aspectRect.size.height / aspectRect.size.width
            aspectRect.size.width = imgTargetSize.width
            aspectRect.size.height = aspectRect.size.width * ratio
        }
        else {
            aspectRect.origin.y = max(0, imgTargetSize.height - 70*2 - aspectRect.height + 20)
        }
        //**********************************
        if(overlayImage != nil){
            let bandSize = CGRect(x: 0, y: 0, width: imgTargetSize.width, height: imgTargetSize.height)
            image.draw(in: aspectRect)
            overlayImage?.draw(in: bandSize, blendMode: CGBlendMode.normal, alpha: 1.0)
        }
        
        let newImage:UIImage = ftcontext.uiImage() ?? image
        return newImage
    }
}
