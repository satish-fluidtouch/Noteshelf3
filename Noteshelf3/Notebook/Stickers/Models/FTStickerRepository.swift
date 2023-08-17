import Foundation
import Combine

struct StickerConstants{
    static let recentStickers = "recentStickers"
    static let downloadedStickerPathExtention = "com.ns3.storeStickers"
}

class FTStickerRepository: NSObject {
    static func fetchCategories() -> AnyPublisher<[FTStickerCategory], Error> {
        let stickerResponse = FTStickerDataSource.loadData()
        return  Just(stickerResponse?.stickers ?? [])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
    }
    
    static func saveSticker(item: [FTStickerItem]) {
        guard let stickersData = try? PropertyListEncoder().encode(item) else {return}
        FTStickersStorageManager().saveRecentItem(data: stickersData)
    }
    
    static func getRecentStickers() -> AnyPublisher<[FTStickerItem], Never> {
        FTStickersStorageManager().fetchRecentStickers()
            .flatMap { (response) -> AnyPublisher<[FTStickerItem], Never> in
                if let stickers = response as? [FTStickerItem] {
                    return Just(stickers).eraseToAnyPublisher()
                } else {
                    return Empty(completeImmediately: true).eraseToAnyPublisher()
                }
            }.replaceError(with: []).eraseToAnyPublisher()
    }
}


