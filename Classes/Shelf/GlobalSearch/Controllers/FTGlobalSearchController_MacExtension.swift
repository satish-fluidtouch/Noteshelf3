//
//  FTGlobalSearchController_MacExtension.swift
//  Noteshelf3
//
//  Created by Narayana on 04/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if targetEnvironment(macCatalyst)
protocol FTMacGlobalSearchDelegate: AnyObject {
    // TODO: Narayana - will be un commented once focus issue in mac is resolved
//    func didTapOnSuggestion(_ suggestionItem: FTSuggestedItem, textField: UISearchTextField)
    func textFieldDidChangeSelection(textField: UISearchTextField)
    func textFieldDidBeginEditing(textField: UISearchTextField)
    func textFieldDidEndEditing(textField: UISearchTextField)
    func textFieldDidTapClearButton(textField: UISearchTextField)
}

extension FTGlobalSearchController: FTMacGlobalSearchDelegate {
    // TODO: Narayana - will be un commented once focus issue in mac is resolved
//    func didTapOnSuggestion(_ suggestionItem: FTSuggestedItem, textField: UISearchTextField) {
//        if suggestionItem.type == .tag {
//            let token = FTSearchSuggestionHelper.shared.searchToken(for: suggestionItem)
//            textField.text = ""
//            textField.insertToken(token, at:  textField.tokens.count)
//            self.searchKey = ""
//        } else {
//            self.searchKey = textField.text ?? ""
//            self.updateUICondictionally(with: self.searchKey, tokens: textField.tokens)
//        }
//        self.constructRecentItems()
//    }

    func textFieldDidBeginEditing(textField: UISearchTextField) {
        self.updateUICondictionally(with: textField.text ?? "", tokens: textField.tokens)
    }

    func textFieldDidEndEditing(textField: UISearchTextField) {
        self.constructRecentItems()
    }

    func textFieldDidChangeSelection(textField: UISearchTextField) {
        let key = textField.text ?? ""
        self.updateUICondictionally(with: key, tokens: textField.tokens)
// TODO: Narayana - Disabling suggestions for mac catalyst.(once focus issue is fixed, we need to uncomment below line and may need any necessary changes
//        if !isRecentSelected {
//            let tokens = key.isEmpty ? [] : FTSearchSuggestionHelper.shared.fetchSearchSuggestion(for: key, tags: self.allTags)
//            textField.searchSuggestions = tokens
//        }
    }

    func textFieldDidTapClearButton(textField: UISearchTextField) {
        self.delegate?.willExitFromSearch(self)
    }
}
#endif
