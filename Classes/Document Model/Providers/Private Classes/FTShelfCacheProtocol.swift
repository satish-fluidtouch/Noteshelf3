//
//  FTShelfCacheProtocol.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTShelfCacheProtocol : NSObjectProtocol
{
    func addItemToCache(_ fileURL : URL) -> FTDiskItemProtocol?
    func removeItemFromCache(_ fileURL : URL,shelfItem : FTDiskItemProtocol);
    func moveItemInCache(_ item: FTDiskItemProtocol, toURL: URL) -> Bool;
}
