//
//  FTSegmentTransientCache.swift
//  Noteshelf
//
//  Created by Akshay on 11/02/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTErasedSegmentCache {
    let stroke: FTStroke
    let index: Int
    init(stroke: FTStroke, index: Int) {
        self.stroke = stroke
        self.index = index
    }
}

final class FTSegmentTransientCache: NSObject {

    private var eraseCache = [FTErasedSegmentCache]()

    func cacheItemCount() -> Int {
        objc_sync_enter(self)
        let count = eraseCache.count
        objc_sync_exit(self)
        return count
    }

    //DOUBT: Cache update is serial, we may remove objc_sync.
    func addEraseCache(_ segment: FTErasedSegmentCache) {
        objc_sync_enter(self)
        eraseCache.append(segment)
        objc_sync_exit(self)
    }

    func cache(at index:Int) -> FTErasedSegmentCache? {
        objc_sync_enter(self)
        guard index < eraseCache.count else { return nil }
        let pointer = eraseCache[index]
        objc_sync_exit(self)
        return pointer
    }

    func clear() {
        objc_sync_enter(self)
        eraseCache.removeAll()
        objc_sync_exit(self)
    }

    func reset() {
        objc_sync_enter(self)
        eraseCache.forEach { cache in
            cache.stroke.setErase(isErased: false, index: cache.index)
        }
        objc_sync_exit(self)
    }

    deinit {
        clear()
    }
}
