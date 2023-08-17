//
//  FTPageProtocol_Additions.swift
//  Noteshelf
//
//  Created by Akshay on 13/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc protocol FTPageEvernoteSyncProtocol : NSObjectProtocol
{
    #if !targetEnvironment(macCatalyst)
    var edamResource: EDAMResource? {get};
    #endif
}

protocol FTPageTileAnnotationMap {
    func tileMapAddAnnotation(_ annotation : FTAnnotation)
    func tileMapRemoveAnnotation(_ annotation : FTAnnotation);
    func clearMapCache();
    func tileMappingRect(_ rects : [CGRect]) -> [FTTileMap];
}
