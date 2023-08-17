//
//  FTBrushBuilder.swift
//  Noteshelf
//
//  Created by Akshay on 08/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTBrushBuilderVersion {
    var version:Int { get }
    func penAttributesFor(penType:FTPenType, brushWidth:CGFloat, isShapeTool:Bool) -> FTPenAttributes
    func metalBrushTextureFor(penType:FTPenType, brushWidth:CGFloat, scale inScale:CGFloat) -> MTLTexture?
    func thicknessCorrectionFactor(penType:FTPenType, brushWidth:CGFloat) -> CGFloat
}

protocol FTBrushProtocol {
    static func attributesFor(brushWidth: CGFloat, velocitySensitive: Bool) -> FTPenAttributes
    static func brushImageFor(brushWidth: CGFloat, scale: CGFloat) -> UIImage
    static func thicknessCorrectionFactorFor(brushWidth: CGFloat) -> CGFloat
}

final class FTBrushBuilder {

    static func penAttributesFor(penType:FTPenType, brushWidth:CGFloat, isShapeTool:Bool, version:Int) -> FTPenAttributes {
        if version != FTStroke.defaultAnnotationVersion() {
            fatalError("Stroke version should be current")
        }
        let builderVersion = builderForVersion(version)
        return builderVersion.penAttributesFor(penType:penType,
                                               brushWidth:brushWidth,
                                               isShapeTool:isShapeTool)
    }


    static func metalBrushTextureFor(penType:FTPenType,
                              brushWidth:CGFloat,
                              scale:CGFloat,
                              version:Int) -> MTLTexture? {
        //TODO: Synchronize
        let builderVersion = builderForVersion(version)
        return builderVersion.metalBrushTextureFor(penType: penType, brushWidth: brushWidth, scale: scale)
    }

    static func thicknessCorrectionFactor(penType:FTPenType, brushWidth:CGFloat, version:Int) -> CGFloat {
        let builderVersion = builderForVersion(version)
        return builderVersion.thicknessCorrectionFactor(penType:penType,
                                                                 brushWidth:brushWidth)
    }
}

private extension FTBrushBuilder {
    static func builderForVersion(_ version:Int) -> FTBrushBuilderVersion {
        let builder:FTBrushBuilderVersion
        switch (version) {
            case 1:
                builder = FTBrushBuilder_v1() //for NS1 imported documents
            case 2:
                builder = FTBrushBuilder_v2() //for NS2 documents before pilot pen introduced
            case 3:
                builder = FTBrushBuilder_v3() //for NS2 documents after pilot pen introduced
            case 4:
                builder = FTBrushBuilder_v4() //for NS2 documents after 2 Highlighter pens introduced
            case 5:
                builder = FTBrushBuilder_v5() //for NS2 documents after dynamic pen sizes and zero size introduced
            default:
                builder = FTBrushBuilder_v5() //for NS2 documents created in Beta before versioning introduced.
        }
        return builder
    }
}
