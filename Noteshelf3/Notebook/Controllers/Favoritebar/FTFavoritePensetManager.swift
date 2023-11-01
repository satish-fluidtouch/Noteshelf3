//
//  FTFavoritebarManager.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritePensetManager: NSObject {
    let dataManager = FTFavoritePensetDataManager.shared

    func fetchFavorites() -> [FTPenSetProtocol] {
        let favorites = dataManager.fetchFavorites().favorites
        var favs = favorites.compactMap(({$0.getPenset()}))
        let reqFavs = favs + favs
        return reqFavs
    }

    func saveFavorites() {

    }

    func addPenset(_ penset: FTPenSetProtocol) {

    }

    func deletePenset(_ penset: FTPenSetProtocol) {

    }

    func updatePenset(_ penset: FTPenSetProtocol) {

    }
}
