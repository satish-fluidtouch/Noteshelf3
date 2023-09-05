//
//  FTPageProtocol_MetalExtension.swift
//  Noteshelf
//
//  Created by Amar on 27/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FirebaseAnalytics

extension FTPageProtocol
{
    func backgroundTexture(toFitIn rect : CGRect,
                           onCompletion : @escaping TextureRequestCompletion)
    {
        let req = FTTextureCreationRequest(page: self,
                                           targetRect: rect,
                                           completion: onCompletion)
        FTTexturePool.shared.backgroundTexture(request: req)
    }
    
    func backgroundTexture(toFitIn rect: CGRect) -> MTLTexture?
    {
        let req = FTTextureCreationRequest(page: self,
                                           targetRect: rect,
                                           completion: nil)
        let textureToreturn = FTTexturePool.shared.texture(for: req)
        return textureToreturn;
    }

    // MARK:- Tiling
    func backgroundTextureTiles(scale: CGFloat, targetRect: CGRect, visibleRect: CGRect?) -> FTBackgroundTextureTileContent? {
        let req = FTTextureTileCreationRequest(page: self, scale: scale, targetRect: targetRect, visibleRect: visibleRect, completion: nil)
        let content = FTTexturePool.shared.backgroundTextureTiles(for: req)
        return content
    }
}
