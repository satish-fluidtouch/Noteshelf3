//
//  FTNoteshelfDocumentProvider_MacExtension.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 03/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTFavoritedStatus: Int {
    case none
    case all
    case mixed
}
extension FTNoteshelfDocumentProvider {
    func favoritedStatus(forItems items: [URL]) -> FTFavoritedStatus {
        var favoritedState: FTFavoritedStatus = .none
        let favoriteItems = self.favoritesShelfItems(.none, parent: nil, searchKey: nil)
        let favoriteURLs = favoriteItems.map { $0.URL.urlByDeleteingPrivate() }
        let newURLs = items.map { $0.urlByDeleteingPrivate()}
            
        //***********************
        let itemSet = Set.init(newURLs)
        let commonItems = itemSet.intersection(favoriteURLs)
        if commonItems.isEmpty {
           favoritedState = .none
        }
        else if commonItems.count == newURLs.count {
            favoritedState = .all
        }
        else {
            favoritedState = .mixed
        }
        //***********************
        return favoritedState
    }
    func favoriteSelectedItems(_ itemsToFavorite: [FTShelfItemProtocol], isToPin: Bool, onController: UIViewController?){
        if isToPin {
            self.favoriteShelfItems(itemsToFavorite, onController: onController)
        }
        else {
            self.removeShelfItemFromList(itemsToFavorite, mode: .favorites)
        }
    }
    private func favoriteShelfItems(_ items: [FTShelfItemProtocol], onController: UIViewController?){
        var selectedItems = items
        if(!selectedItems.isEmpty) {
            let itemToFavorite = selectedItems.removeFirst()
            self.addShelfItemToList(itemToFavorite, mode: .favorites)
            self.favoriteShelfItems(selectedItems, onController: onController)
        }
    }
}
