//
//  FTFavoritebarManager.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritePensetManager: NSObject {
    let dataManager = FTFavoritePensetDataManager()

    func fetchFavorites() -> [FTPenSetProtocol] {
        let favorites = dataManager.fetchFavorites().favorites
        let favs = favorites.compactMap(({$0.getPenset()}))
        return favs
    }

    func saveFavorites(_ favorites: [FTPenSetProtocol]) {
        var dataModel = dataManager.fetchFavorites()
        dataModel.favorites = favorites.compactMap({ penset in
            FTFavoritePenset(type: penset.type.rawValue, color: penset.color, size: CGFloat(penset.size.rawValue), preciseSize: String(Float(penset.preciseSize)))
        })
        self.dataManager.saveFavorites(dataModel)
    }
}
