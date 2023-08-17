//
//  FTPageThumbnailProtocol.swift
//  Noteshelf
//
//  Created by Amar on 25/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc protocol FTPageThumbnailProtocol : NSObjectProtocol{
    var shouldGenerateThumbnail : Bool {get set};

    init(page : FTPageProtocol, documentUUID: String, thumbnailGenerator: FTThumbnailGenerator?);
    
    func thumbnailImage(onUpdate : @escaping ((UIImage?,String) -> Void));
    func cachedThumbnailInfo(onCompletion: @escaping ((UIImage?,String) -> Void));
    func updateThumbnail(_ image : UIImage?,updatedDate:Date?);
    func delete();

    func cancelThumbnailGeneration()
}
