//
//  FTTextureCacheManager.swift
//  Noteshelf
//
//  Created by Akshay on 06/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTRenderKit

private let cacheContentLimit = 10

protocol FTTextureCacheable: NSObjectProtocol {
    var lastAccessTime: TimeInterval {get set}
    var documentIds : [String] {get set}
    func setDocument(docId: String?)
    func removeDocument(docId: String)
    func canEvict() -> Bool
    func evictAllContents()
    func evictContentsPartially()
    var cacheCount: Int { get }
}

final class FTTextureCache: NSObject, FTTextureCacheable {
    var texture: MTLTexture?
    var lastAccessTime: TimeInterval
    var documentIds = [String]()

    init(texture: MTLTexture) {
        self.texture = texture
        lastAccessTime = Date().timeIntervalSinceReferenceDate
    }

    func setDocument(docId: String?) {
        objc_sync_enter(self)
        if let _docId = docId {
            documentIds.append(_docId)
        }
        objc_sync_exit(self)
    }
    
    func removeDocument(docId: String) {
        objc_sync_enter(self)
        documentIds.removeAll(where:{ $0 == docId })
        objc_sync_exit(self)
    }

    func canEvict() -> Bool {
        return documentIds.isEmpty
    }

    func evictAllContents() {
        texture = nil
    }

    func evictContentsPartially() {
        //Nothing to do
    }

    var cacheCount: Int {
        return 1
    }
}

final class FTTiledTextureCache: NSObject, FTTextureCacheable {
    let content: FTBackgroundTextureTileContent
    var lastAccessTime: TimeInterval
    var documentIds = [String]()

    init(content: FTBackgroundTextureTileContent) {
        self.content = content
        lastAccessTime = Date().timeIntervalSinceReferenceDate
    }

    func setDocument(docId: String?) {
        objc_sync_enter(self)
        if let _docId = docId {
            documentIds.append(_docId)
        }
        objc_sync_exit(self)
    }

    func removeDocument(docId: String) {
        objc_sync_enter(self)
        documentIds.removeAll(where:{ $0 == docId })
        objc_sync_exit(self)
    }

    func canEvict() -> Bool {
        return documentIds.isEmpty
    }

    func evictAllContents() {
        content.evictTiles(mode: .aggressive)
    }

    func evictContentsPartially() {
        content.evictTiles(mode: .partial)
    }

    var cacheCount: Int {
        return content.tiles.count
    }

    override var description: String {
        content.description
    }
}

final class FTTextureCacheManager: NSObject {

    private var cacheMap = [NSString:FTTextureCacheable]()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            guard let strongSelf = self else {
                return;
            }
            objc_sync_enter(strongSelf)
            strongSelf.cacheMap.removeAll()
            objc_sync_exit(strongSelf)
        }
    }

    func object(forKey key: NSString) -> FTTextureCacheable? {
        var texture : FTTextureCacheable?
        objc_sync_enter(self)
            texture = self.cacheMap[key]
            texture?.lastAccessTime = Date().timeIntervalSinceReferenceDate
        objc_sync_exit(self)

            //Introduced eviction at this level, because, we're generating the textures on Renderer demand. so we don't have clearing off control while generating.
            //where as in earlier approache, we used to create textures upfront and clear of whenever we set the new texture.
        defer {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(evictUnusedIfRequired), object: nil)
            self.perform(#selector(evictUnusedIfRequired), with: nil, afterDelay: 1.0)
        }
        return texture
    }

    func setObject(_ obj: FTTextureCacheable, forKey key: NSString) {
        obj.lastAccessTime = Date().timeIntervalSinceReferenceDate
        objc_sync_enter(self)
            self.cacheMap[key] = obj
        objc_sync_exit(self)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(evictUnusedIfRequired), object: nil)
        self.perform(#selector(evictUnusedIfRequired), with: nil, afterDelay: 1.0)
    }

    @objc private func evictUnusedIfRequired() {
        let orderedMap = cacheMap.sorted { $0.value.lastAccessTime > $1.value.lastAccessTime }

        // Cache eviction Strategy
        // 1. Keep only cacheContentLimit of most recently used elements in the cacheMap.
        // 2. Out of this limit partially remove the contents from the second half of the cacheMap elements. This partial eviction strategy is implemented in the FTTextureTile, to keep the 36 most recently used tiles.

        //1. Remove cached contents, if they exceed the limit
        if cacheMap.count > cacheContentLimit {
            objc_sync_enter(self)
            let morethanLimitRange = cacheContentLimit-1..<orderedMap.count-1
            orderedMap[morethanLimitRange].forEach { (key, _) in
                cacheMap.removeValue(forKey: key)
            }
            objc_sync_exit(self)
        }

        //2. Partial eviction
        cacheMap.forEach { (key,item) in
            item.evictContentsPartially();
        }
    }

    func evictCacheForDocument(docId:String) {
        objc_sync_enter(self)
        let evictables = self.cacheMap.filter { (_, value) -> Bool in
            value.removeDocument(docId: docId)
            return value.canEvict()
        }

        evictables.forEach({ (key, cache) in
            cache.evictAllContents()
            self.cacheMap.removeValue(forKey: key)
        })
        #if DEBUG
        print("Current Cached textures count", self.cacheMap.count)
        #endif
        objc_sync_exit(self)
    }
}
