//
//  FTUnsplashViewModel.swift
//  FTNewNotebook
//
//  Created by Narayana on 14/03/23.
//

import SwiftUI

class FTUnsplashViewModel: NSObject {
    private let networkManager: FTUnsplashAPI
    private(set) var unsplashItems: [FTUnSplashItem] = []
    private(set) var isFetching: Bool = false

    override init() {
        self.networkManager = FTUnsplashAPI()
        super.init()
    }

    func fetchUnsplash(with key: String, page: Int = 1, onCompletion: @escaping ((Bool, Error?) -> Void)) {
        let searchKey = key.isEmpty ? "wallpapers" : key
        Task {
            do {
                self.isFetching = true
                if let items = try await networkManager.fetchUnsplashData(with: searchKey, page: page) {
                    self.unsplashItems.append(contentsOf: items)
                    self.isFetching = false
                    onCompletion(true, nil)
                }
            } catch {
                self.isFetching = false
                onCompletion(false, error)
            }
        }
    }

    func clearUnsplashItems() {
        self.unsplashItems.removeAll()
    }
}
