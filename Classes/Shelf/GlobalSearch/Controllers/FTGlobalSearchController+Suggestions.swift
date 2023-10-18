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
            searchInputInfo.textKey = ""
            self.updateUICondictionally(with: "", tokens: textField.tokens)
        } else {
            let text = searchController.searchBar.searchTextField.text ?? ""
            self.updateUICondictionally(with: text)
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
        self.cancelSearch();
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
        let currentTags = FTSearchSuggestionHelper.shared.fetchCurrentSelectedTagsText(using: self.searchController.searchTokens)
        if keyWord.isEmpty && searchTokens.isEmpty {
            self.searchInputInfo.textKey = keyWord
            self.searchInputInfo.tags = currentTags

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
            self.cancelSearch()
        } else {
            self.recentsTableView.isHidden = true
            self.segmentInfoStackView.isHidden = false
            self.collectionView.isHidden = false
            if self.searchInputInfo.textKey != text || self.searchInputInfo.tags != currentTags {
                self.searchInputInfo.textKey = text
                self.searchInputInfo.tags = currentTags
                self.searchForNotebooks(with: self.searchInputInfo)
            }
        }
    }
}
