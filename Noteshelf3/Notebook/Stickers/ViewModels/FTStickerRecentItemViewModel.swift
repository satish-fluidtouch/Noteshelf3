//
//  FTStickerRecentItemViewModel.swift
//  StickerModule
//
//  Created by Rakesh on 28/03/23.
//

import Foundation
import Combine

final class FTStickerRecentItemViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()

    func saveSticker(stickerInfo: FTStickerItem) {
        FTStickerRepository.getRecentStickers().sink { [weak self] stickers in
            var recentStickerItems = stickers
            if recentStickerItems.count == 0 {
                recentStickerItems.append(stickerInfo)
            }
            if  !recentStickerItems.contains(where: { $0.image == stickerInfo.image}) {
                if recentStickerItems.count == 7{
                    recentStickerItems.removeFirst()
                    recentStickerItems.append(stickerInfo)
                }else{
                    recentStickerItems.append(stickerInfo)
                }
            }
            FTStickerRepository.saveSticker(item: recentStickerItems)
            
        }.store(in: &subscriptions)
    }
}
