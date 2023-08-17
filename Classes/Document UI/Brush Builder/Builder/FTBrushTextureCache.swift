//
//  FTBrushTextureCache.swift
//  Noteshelf
//
//  Created by Akshay on 01/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Metal

struct FTBrushTextureProps {
    let version: Int
    let penType: FTPenType
    let brushWidth: Int
    let scale: Int

    var key: String {
        return "\(version)_\(penType.rawValue)_\(brushWidth)_\(scale)"
    }
}

final class FTBrushTextures {
    private static var textures = [String: MTLTexture]()

    static func brushTexture(for props: FTBrushTextureProps) -> MTLTexture? {
        objc_sync_enter(self)
        let texture = textures[props.key]
        objc_sync_exit(self)
        #if DEBUG
        //print("⚽️ Brush texture for key ",props.key,texture == nil ? "⚠️" : "✅")
        #endif
        return texture
    }

    static func cacheBrushTexture(_ texture:MTLTexture, for props: FTBrushTextureProps) {
        objc_sync_enter(self)
        texture.label = props.key
        textures[props.key] = texture
        objc_sync_exit(self)
    }
}
