//
//  FTSearchSuggestionHelper.swift
//  Noteshelf3
//
//  Created by Narayana on 30/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTSearchSuggestionHelper: NSObject {
    static let shared = FTSearchSuggestionHelper()

    func fetchTags() -> [FTTagModel] {
        let allTagStrs = FTCacheTagsProcessor.shared.cachedTags()
        var tags = allTagStrs.map { FTTagModel(text: $0, isSelected: false) }
        tags.sort { (tag1, tag2) -> Bool in
            (tag1.text.compare(tag2.text, options: [.caseInsensitive, .numeric], range: nil, locale: nil) == .orderedAscending)
        }
        return tags
    }

    func fetchCurrentSelectedTagsText(using tokens: [UISearchToken]) -> [String] {
        var currentTags = [String]()
        tokens.forEach { eachToken in
            if let item = eachToken.representedObject as? FTSuggestedItem, let tag = item.tag {
                tag.isSelected = true
                currentTags.append(tag.text)
            }
        }
        return currentTags
    }

     func fetchSearchSuggestion(for query: String, tags: [FTTagModel]) ->[UISearchSuggestionItem] {
        let helper = FTSearchSuggestionHelper.shared
        let sugItems = helper.fetchSuggestions(for: query, tags: tags)
        var items = [UISearchSuggestionItem]()
        sugItems.forEach { eachSuggestion in
            let item = helper.suggestionItem(with: eachSuggestion)
            items.append(item)
        }
       return items
    }

     func searchToken(for suggestionItem: FTSuggestedItem) -> UISearchToken {
        let tokenColor = UIColor.white
        let image = UIImage(systemName: suggestionItem.type.image())?.withTintColor(tokenColor, renderingMode: .alwaysOriginal)
        let string = suggestionItem.suggestion.string
        let searchToken = UISearchToken(icon: image, text: string)
        searchToken.representedObject = suggestionItem
        return searchToken
    }
}

private extension FTSearchSuggestionHelper {
    private func suggestionItem(with item: FTSuggestedItem)  -> UISearchSuggestionItem {
        let image = UIImage(systemName: item.type.image())
        let suggestionItem = UISearchSuggestionItem(localizedAttributedSuggestion: item.suggestion, localizedDescription: item.suggestion.string, iconImage: image)
        suggestionItem.representedObject = item
        return suggestionItem
    }

    private func mutableString(for string: String,  type: FTSuggestionType, query: String) -> NSMutableAttributedString {
        let mutableString = NSMutableAttributedString(string: string)
        mutableString.addAttribute(.foregroundColor, value: UIColor.label.withAlphaComponent(0.5), range: NSRange(location: 0, length: mutableString.length))
        var range = (mutableString.string.lowercased() as NSString).range(of: query.lowercased())
        if !query.isEmpty, type == .text, let _range = mutableString.rangesOfOccurance(of: "\"")?.first as? NSRange {
            range = NSRange(location: _range.location + 1, length: query.count )
        }
        mutableString.addAttribute(.foregroundColor, value: UIColor.label, range:  range)
        return mutableString
    }

    private func fetchSuggestions(for query: String, tags: [FTTagModel]) -> [FTSuggestedItem] {
        var items = [FTSuggestedItem]()
        var filteredTags = [FTTagModel]()
        filteredTags = tags.filter({
            $0.text.lowercased().hasPrefix(query.lowercased()) == true
        })
        let containsQuery = "finder.search.contains".localized + " \"\(query)\""
        let textItem = FTSuggestedItem(tag: nil, type: .text, suggestion: self.mutableString(for: containsQuery, type: .text, query: query))
        items.append(textItem)
        filteredTags.forEach { eachTag in
            let suggestionItem = FTSuggestedItem(tag: eachTag, type: .tag, suggestion: self.mutableString(for: eachTag.text, type: .tag, query: query))
            items.append(suggestionItem)
        }
        return items
    }
}
