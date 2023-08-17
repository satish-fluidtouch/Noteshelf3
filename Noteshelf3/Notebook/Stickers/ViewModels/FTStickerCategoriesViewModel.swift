//
//  StickerViewModel.swift
//  ShowStickers
//
//  Created by Rakesh on 01/03/23.
//

import Foundation
import Combine

final class FTStickerCategoriesViewModel: ObservableObject {
    @Published var stickerCategoryModel: [FTStickerCategory] = []
    @Published var menuItems: [String] = []
    @Published var recentStickerItems: [FTStickerItem] = []
    @Published var errorMessage = ""

    var subscriptions = Set<AnyCancellable>()
    weak var stickerDelegate: FTStickerdelegate?
    lazy var fileStickerManager = FTStickersStorageManager()

    init(delegate: FTStickerdelegate? ) {
        self.stickerDelegate = delegate
    }
    
    func getStickers(){
        FTStickerRepository.fetchCategories().sink { [unowned self] (completion) in
            switch completion {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .finished: return
            }
        } receiveValue: { sticker in
            self.createMenuItems(sticker)
            self.stickerCategoryModel = sticker
        }.store(in: &subscriptions)
    }
    
    func getRecents() {
        FTStickerRepository.getRecentStickers()
            .assign(to: \.recentStickerItems, on: self)
            .store(in: &subscriptions)
    }

    fileprivate func createMenuItems(_ models: [FTStickerCategory]) {
        var items:[String] = []
        if recentStickerItems.count > 0 {
            items.append("Recents".localized)
        }
        models.forEach { model in
            items.append(model.title)
        }
        menuItems = items
    }
    
    func removeRecentStickerList(_ recentStickerList: FTStickerItem) {
            if let index = self.recentStickerItems.firstIndex(of: recentStickerList) {
                self.recentStickerItems.remove(at: index)
            }
            if self.recentStickerItems.count == 0{
                self.menuItems.remove(at: 0)
            }
            FTStickerRepository.saveSticker(item: self.recentStickerItems)
        }
    }

