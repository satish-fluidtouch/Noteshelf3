//
//  FTGlobalSearchController+Suggestions.swift
//  Noteshelf3
//
//  Created by Narayana on 12/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTGlobalSearchController: FTUISearchDelegate {
    func didTapOnSuggestion(_ suggestionItem: FTSuggestedItem) {
        if suggestionItem.type == .tag {
            let textField = searchController.searchBar.searchTextField
            let token = FTSearchSuggestionHelper.shared.searchToken(for: suggestionItem)
            textField.text = ""
            textField.insertToken(token, at:  textField.tokens.count)
            self.searchKey = ""
        } else {
            self.searchKey = searchController.searchBar.searchTextField.text ?? ""
            self.updateUICondictionally(with: self.searchKey)
        }
        self.constructRecentItems()
    }

    func textFieldDidBeginEditing(key: String) {
        self.updateUICondictionally(with: key)
    }

    func textFieldDidEndEditing(key: String) {
        self.constructRecentItems()
    }

    func textFieldDidChangeSelection(key: String) {
        self.updateUICondictionally(with: key)
        if !isRecentSelected {
            self.searchController.populateSuggestionsIfNeeded(for: key, tags: self.allTags)
        }
    }

    func didTapOnCancelButton() {
        self.delegate?.willExitFromSearch(self)
    }
}

// UI instant updates, helpers
extension FTGlobalSearchController {
    internal func updateUICondictionally(with text: String, tokens: [UISearchToken] = []) {
        let keyWord = text.trimmingCharacters(in: CharacterSet.whitespaces)
        var searchTokens = self.searchController.searchTokens
        if !tokens.isEmpty {
            searchTokens = tokens
        }
        if keyWord.isEmpty && searchTokens.isEmpty {
            if !self.recentSearchList.isEmpty {
                self.segmentInfoStackView.isHidden = true
                self.collectionView.isHidden = true
                self.progressView?.isHidden = true
                self.recentsTableView.isHidden = false
                self.recentsTableView.reloadData()
            } else {
                self.recentsTableView.isHidden = true
                self.segmentInfoStackView.isHidden = true
                self.collectionView.isHidden = true
            }
        } else {
            self.recentsTableView.isHidden = true
            self.segmentInfoStackView.isHidden = false
            self.collectionView.isHidden = false
            let currentTags = FTSearchSuggestionHelper.shared.fetchCurrentSelectedTagsText(using: self.searchController.searchTokens)
            self.searchForNotebooks(with: text, tags: currentTags)
        }
    }
}
