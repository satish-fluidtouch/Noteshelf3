//
//  FTEmojiesManager.swift
//  FTAddOperations
//
//  Created by Siva on 10/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Combine
import SwiftUI
import UIKit
import FTCommon

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        let decoder = JSONDecoder()

        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(file) from bundle.")
        }

        return loaded
    }
}

protocol FTEmojiesManagerProtocol {
//    var categoriesList: [FTEmojiesCategory]? {set get}
    func emojiCategoryTitles() -> [String]
//    func emojiesCategoryByIndex(_ index: Int) -> FTEmojiesCategory?
    func lastUsedEmoji() -> String
}

class FTEmojiesManager: FTEmojiesManagerProtocol {
   
    private let EMOJI_RECENT_KEY = "emoji_recent"
//    static let shared = FTEmojiesManager()
    
    private var categoriesList = [FTEmojiesCategory]()
    
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        emojiCategories()
    }
    
    func getCategoryList() -> [FTEmojiesCategory] {
        let recent = recentEmojiesFromUserDefaults()
        if recent.items.count > 0 {
            categoriesList.insert(recent, at: 0)
        }
        return categoriesList
    }
    
    /// This function will give All Emojis by Category
    private  func emojiCategories() {
        
        guard let bundlePath = Bundle.main.path(forResource: "Emojies", ofType: "json") else {
            return
        }
        do {
            if let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                
                categoriesList = try JSONDecoder().decode([FTEmojiesCategory].self,
                                                          from: jsonData)
            }
            
        } catch {
            debugPrint(" parsing error \(error.localizedDescription)")
        }
    }
    
    /// Load Json data from Bundle
    private var readEmojisFromLocalJsonFile: [FTEmojiesCategory] {
        do {
            if let bundlePath = Bundle.main.path(forResource: "Emojies", ofType: "json"),
                let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                let decodedJson =  parse(jsonData: jsonData)
                return decodedJson
            }
        } catch {
            print(error)
        }
        return []
    }
    
    private func parse(jsonData: Data) -> [FTEmojiesCategory] {
        do {
            let fTEmojiesCategory = try JSONDecoder().decode([FTEmojiesCategory].self,
                                                             from: jsonData)
           
            return fTEmojiesCategory
        } catch {
            debugLog("decode error")
        }
        return []
    }
    
    /// This func will return recent emojies list from UserDefaults
    func recentEmojiesFromUserDefaults() -> FTEmojiesCategory {
        
        guard let data = UserDefaults.standard.data(forKey: EMOJI_RECENT_KEY) else {
            return FTEmojiesCategory(title: "Recents".localized, items: [])
        }
        
        do {
            let recentCategory = try JSONDecoder().decode(FTEmojiesCategory.self, from: data)
            return recentCategory
        } catch {
            return FTEmojiesCategory(title: "Recents".localized, items: [])
        }
    }
    
    /// Save selected Emoji into UserDefaults
    func saveEmojiItemIntoUserDefaults(emojiItem: FTEmojisItem)  {
        // self.addEmoji(toRecent: emojiItem.emojiSymbol)
        
        var recentCategory = recentEmojiesFromUserDefaults()
        var recentItems = recentCategory.items
        
        /// Chek whether selected Emoji item is in recents list remove it and Add
        if let index = recentItems.firstIndex(of: emojiItem) {
            recentItems.remove(at: index)
        }
        recentItems.insert(emojiItem, at: 0)
        recentCategory.items = recentItems
        categoriesList.insert(recentCategory, at: 0)
        //            categoriesList[0] = recentCategory
        if let encodedData = try? JSONEncoder().encode(recentCategory) {
            UserDefaults.standard.set(encodedData, forKey: EMOJI_RECENT_KEY)
        }
    }
 
    
    func emojiCategoryTitles() -> [String] {
        return categoriesList.map {$0.title.localized}
    }
 
    func lastUsedEmoji() -> String {
        let recentCategory = recentEmojiesFromUserDefaults()
            let recentItems = recentCategory.items
        return recentItems.first?.emojiSymbol ?? ""
    }
    func image(forEmojiString emojiString: String?, size: CGFloat) -> UIImage? {
        let label = FTStyledLabel()
        label.font = UIFont(name: "Apple Color Emoji", size: size)
        label.text = emojiString
        label.isOpaque = false
        label.backgroundColor = UIColor.clear
        let labelSize = CGSize(width: size, height: size)
        label.frame = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)

        return image(from: label)
    }

    func image(from view: UIView?) -> UIImage? {
        guard let _view = view,let context = FTImageContext.imageContext(_view.bounds.size) else {
            return nil;
        }
        _view.layer.render(in: context.cgContext);
        let image = context.uiImage();
        return image
    }

    // Migrate old recent data to New
   private func migrateOldRecentEmojiesToNew() -> [FTEmojisItem]? {
        
        if  let previousRecents = recentEmoji(), !previousRecents.isEmpty {
            let items = self.categoriesList.map {$0}.filter {$0.title.localized != "Recents".localized }.map {$0.items}.reduce([], +)
            let emojies =  items.filter({ (item) -> Bool in
                    return previousRecents.contains(item.emojiSymbol)
            })
            return emojies
        }
        return []
    }
        
   private func recentEmoji() -> [AnyHashable]? {
        return UserDefaults.standard.array(forKey: "RECENT_EMOJI") as? [AnyHashable]
    }
}



