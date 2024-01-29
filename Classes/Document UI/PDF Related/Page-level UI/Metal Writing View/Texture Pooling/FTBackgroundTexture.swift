//
//  FTBackgroundTexture.swift
//  Noteshelf
//
//  Created by Amar on 23/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTBackgroundTexture: NSObject {
    fileprivate var _backgroundTexture : MTLTexture?
    fileprivate var _backgroundTextureTileContent : FTBackgroundTextureTileContent?
    fileprivate var _scale : CGFloat = 1;
    var isBackgroundTextureGenInProgress = false;
    
    var loadedBackground : Bool = false;

    var scale : CGFloat {
        get {
            return _scale;
        }
        set {
            let newScale = bgTextureScale(newValue);
            if(_scale != newScale) {
                self._backgroundTexture = nil;
                self._backgroundTextureTileContent = nil
                _scale = newScale;
                //Special case, where when we're resetting the scale, while the generation is in progress.
                if isBackgroundTextureGenInProgress == true {
                    isBackgroundTextureGenInProgress = false
                }
            }
        }
    }
    
    var texture : MTLTexture?
    {
        get {
            return self._backgroundTexture;
        }
        set {
            self._backgroundTexture = newValue;
            self.loadedBackground = true;
        }
    }

    var backgroundTextureTileContent : FTBackgroundTextureTileContent? {
        get {
            return self._backgroundTextureTileContent;
        }
        set {
            self._backgroundTextureTileContent = newValue;
            self.loadedBackground = true;
        }
    }
    
    func resetForCurrentScale(_ scale : CGFloat,forceReset : Bool)
    {
        let newScale = bgTextureScale(scale);
        if(forceReset || _scale != newScale) {
            self._scale = newScale;
            self._backgroundTexture = nil;
            self._backgroundTextureTileContent = nil
            self.loadedBackground = false;
        }
    }
}

typealias TextureRequestCompletion = (_ texture: MTLTexture?) -> Void
typealias TextureTileRequestCompletion = (_ textureTileContent: FTBackgroundTextureTileContent?) -> Void

struct FTTextureCreationRequest {
    let page: FTPageProtocol
    let targetRect: CGRect

    let completion: TextureRequestCompletion?

    var docID: String? {
        return page.parentDocument?.documentUUID
    }
    
    var identifier: NSString {
        let scale = page.templateInfo.isImageTemplate ? 2 : textureScaleWRTScreen(targetRect.size);
        let pdfTitle = (page.associatedPDFFileName as NSString?)?.deletingPathExtension ?? "-"
        var key = "\(pdfTitle)_\(page.associatedPDFKitPageIndex)_\(bgTextureScale(scale))"
        let angle = (page.pdfPageRef?.rotation ?? 0) + Int(page.rotationAngle)
        if angle > 0 {
            key += "_\(angle)"
        }
        return key as NSString
    }
}

// MARK: - Tiling
struct FTTextureTileCreationRequest {
    let page: FTPageProtocol
    let scale: CGFloat
    let targetRect: CGRect
    let visibleRect: CGRect?

    let completion: TextureTileRequestCompletion?

    var docID: String? {
        return page.parentDocument?.documentUUID
    }

    var identifier: NSString {
        let _scale = page.templateInfo.isImageTemplate ? 2 : textureScaleWRTScreen(targetRect.size)
        let pdfTitle = (page.associatedPDFFileName as NSString?)?.deletingPathExtension ?? "-"
        var key = "\(pdfTitle)_\(page.associatedPDFKitPageIndex)_\(_scale)"
        let angle = (page.pdfPageRef?.rotation ?? 0) + Int(page.rotationAngle)
        if angle > 0 {
            key += "_\(angle)"
        }
        return key as NSString
    }
}

func bgTextureScale(_ scale :  CGFloat) -> CGFloat
{
    let maxScale: CGFloat
    if FTRenderConstants.USE_BG_TILING {
        maxScale = UIScrollView.nsMaximumZoomScale
    } else {
        maxScale = 3
    }

    let scale = max(1.0,min(round(scale), maxScale))
    return scale
}

func textureSizeWRTScreen(_ pageSize: CGSize) -> CGSize {
    let screenWidth = UIScreen.main.bounds.size.width;
    let screenHeight = UIScreen.main.bounds.size.height;

    var sizeToCreate = CGSize(width: min(screenWidth,screenHeight), height: max(screenWidth,screenHeight));
    if(pageSize.width > pageSize.height) {
        sizeToCreate = CGSize(width: max(screenWidth,screenHeight), height: min(screenWidth,screenHeight));
    }
    
    let aspectRect = aspectFittedRect(CGRect(origin: .zero, size: pageSize), CGRect(origin: .zero, size: sizeToCreate));
    return aspectRect.size;
}

func textureScaleWRTScreen(_ pageSize: CGSize) -> CGFloat {
    let textureSize = textureSizeWRTScreen(pageSize);
    var pageScale = pageSize.width/textureSize.width;
    pageScale = bgTextureScale(pageScale);
    return pageScale;
}
