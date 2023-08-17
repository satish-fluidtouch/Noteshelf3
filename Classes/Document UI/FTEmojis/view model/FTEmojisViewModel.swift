//
//  FTEmojisViewModel.swift
//  Noteshelf
//
//  Created by srinivas on 10/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import Combine

class FTEmojisViewModel {
    
    var emojis = CurrentValueSubject<[FTEmojisItem], Never>([FTEmojisItem]())
    var selectedSegment = CurrentValueSubject<Int, Never>(0) // Default is All
    
    var sections: [String: [FTEmojisItem]] = [:]
    
    let emojiManager = FTEmojiesManager()
    
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        
        loadAllCategoryEmojies()
        
    }
    
    func loadEmojies(by index: Int) {
        emojiManager.fetchCategoryByIndex(index) { [weak self] items in
            self?.emojis.value = items
        }
    }
    
    func loadAllCategoryEmojies() {
//        emojiManager.fetchAllCategoryEmojies { [weak self] items in
//            self?.emojis.value = items
//        }
    }
    
    func loadRecentEmojies() {
        emojiManager.fetchRecentItems { [weak self] items in
            self?.emojis.value = items
        }
    }
    
//    func fetchEmojis() {
//        debugPrint("selectedSegment :  \(selectedSegment.value)")
//        selectedSegment
//            .map { index in
//                return self.emojiManager.fetchCategoryByIndex(index)
//            }
//            .switchToLatest()
//            .sink { [weak self] items in
//                debugPrint("received category ")
//                self?.emojis.value = items
//            }.store(in: &subscriptions)
//    }
    
    func searchEmojis(with keyword: String){
        self.emojiManager.searchResultsFor(searchText: keyword)
            .sink { _ in
                debugPrint("received completion ")
            } receiveValue: { [weak self] emojis in
                self?.emojis.value = emojis
            }.store(in: &subscriptions)
    }
    
    
    func saveSelectedEmoji(emoji: FTEmojisItem) {
        emojiManager.saveEmojiItemIntoUserDefaults(emojiItem: emoji)
    }
    
    /// fetch category titles
//    func fetchCategories() -> [String?] {
//        return emojiManager.emojiCategoryTitles()
//    }
    
    func fetchSections() -> [FTEmojiesCategory] {
        emojiManager.getCategoryList()
    }

}



