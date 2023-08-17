//
//  FTTexturePool.swift
//  Noteshelf
//
//  Created by Akshay on 29/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTTexturePool: NSObject {

    static let shared = FTTexturePool()
    private let cache = FTTextureCacheManager()

    private let textureQueue = DispatchQueue(label: "com.fluidtouch.bgtexture.request")

    private var ongoingRequest : FTTextureCreationRequest?
    private var pendingRequests = [FTTextureCreationRequest]()

    private override init() {
        super.init()
    }

    func texture(for request: FTTextureCreationRequest) -> MTLTexture? {
        var texture:  MTLTexture?
        textureQueue.sync {
            texture = self.executeTexture(request: request);
        }
        return texture;
    }

    func backgroundTexture(request: FTTextureCreationRequest) {
        textureQueue.async {
            let texture = self.executeTexture(request: request);
            request.completion?(texture)
        }
    }

    func evictCacheForDocument(docId:String) {
        cache.evictCacheForDocument(docId: docId)
    }
    
    private func executeTexture(request: FTTextureCreationRequest) -> MTLTexture? {
        if let ftTexture = self.cache.object(forKey: request.identifier) as? FTTextureCache {
            ftTexture.setDocument(docId:request.docID)
            return ftTexture.texture
        } else {
            let texture = FTSingleTextureCreation.createBackgroundTexture(for: request.page, targetRect: request.targetRect)
            if let _texture = texture {
                let ftTexture = FTTextureCache(texture: _texture)
                ftTexture.setDocument(docId: request.docID)
                cache.setObject(ftTexture, forKey: request.identifier as NSString)
            }
            return texture
        }
    }
}

// MARK:- Tiling
extension FTTexturePool {
    func backgroundTextureTiles(for request: FTTextureTileCreationRequest) -> FTBackgroundTextureTileContent? {
        var content: FTBackgroundTextureTileContent?
        textureQueue.sync {
            content = executeTexture(request: request)
        }
        return content
    }
    
    private func executeTexture(request: FTTextureTileCreationRequest) -> FTBackgroundTextureTileContent? {
        if let textureCache = self.cache.object(forKey: request.identifier) as? FTTiledTextureCache {
            textureCache.setDocument(docId:request.docID)
            return textureCache.content
        } else {
            //Create Texture Content Object
            let pageRect = CGRectScale(request.page.pdfPageRect, request.scale)
            let roundedScale = textureScaleWRTScreen(pageRect.size)

            let aspectFittedSize = textureSizeWRTScreen(pageRect.size)

            let totalScaleFactor = roundedScale * UIScreen.main.scale
            let scaledPageSize = CGSizeScale(aspectFittedSize, totalScaleFactor)

            let textureContent = FTNoteshelfBGTextureTileContent(page:request.page, contentSize: scaledPageSize)

            //Add to Cache
            let ftTexture = FTTiledTextureCache(content: textureContent)
            ftTexture.setDocument(docId: request.docID)
            cache.setObject(ftTexture, forKey: request.identifier as NSString)
            return textureContent
        }
    }
}
