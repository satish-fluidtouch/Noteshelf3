//
//  FTGlobalSearchController+Recents.swift
//  Noteshelf3
//
//  Created by Narayana on 01/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTGlobalSearchController {
    internal func constructRecentItems() {
        let tagsText = FTSearchSuggestionHelper.shared.fetchCurrentSelectedTagsText(using: searchController.searchTokens)

        var items = [FTRecentSearchedItem]()
        tagsText.forEach { tagText in
            let item =  FTRecentSearchedItem(type: .tag, name: tagText)
            items.append(item)
        }
        if !searchInputInfo.textKey.isEmpty {
            let recentTextItem = FTRecentSearchedItem(type: .text, name: searchInputInfo.textKey)
            items.append(recentTextItem)
        }
        FTRecentSearchStorage.shared.addNewSearchItem(items)
        self.updateRecentSearchList()
    }

    internal func updateRecentSearchList() {
        self.recentSearchList = FTRecentSearchStorage.shared.availableRecents().filter { !$0.isEmpty }
    }
}

extension FTGlobalSearchController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recentSearchList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: kRecentSearchCell, for: indexPath) as?
            FTRecentSearchCell {
            let items = self.recentSearchList[indexPath.row]
            cell.configureCell(with: items)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.isRecentSelected = true
        let items = self.recentSearchList[indexPath.row]
        var searchTokens = [UISearchToken]()
        var searchableText = ""
        items.forEach { eachItem in
            if eachItem.type == .tag {
                let tag = FTTagModel(text: eachItem.name, isSelected: true)
                let suggestedItem = FTSuggestedItem(tag: tag, type: .tag, suggestion: NSMutableAttributedString(string: eachItem.name))
                let token = FTSearchSuggestionHelper.shared.searchToken(for: suggestedItem)
                searchTokens.append(token)
            } else {
                searchableText += "\(eachItem.name)"
            }
        }
        if !searchTokens.isEmpty  {
            self.searchController.updateSearchTokens(searchTokens)
        }
        let searchbar = self.searchController.searchBar
        if !searchableText.isEmpty {
            searchbar.searchTextField.text = searchableText
        }
        if let reqText = searchbar.searchTextField.text {
#if targetEnvironment(macCatalyst)
            if let toolbar = self.view.toolbar as? FTShelfToolbar, !reqText.isEmpty {
                toolbar.updateSearchText(reqText)
            }
#else
            self.updateUICondictionally(with: reqText, tokens: searchTokens)
#endif
        }
        self.isRecentSelected = false
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !self.recentSearchList.isEmpty {
            let header = FTRecentSectionHeader.recentSectionHeader(with: self)
            header.updateSectionTitle("globalSearch.recentlySearched".localized)
            return header
        }
        return nil
    }
}

extension FTGlobalSearchController: FTRecentSectionDelegate {
    func didTapClearAllButton() {
        UIAlertController.showConfirmationDialog(with: "finder.clear.recents".localized, message: "", from: self) {
            FTRecentSearchStorage.shared.clear()
            self.updateRecentSearchList()
            self.recentsTableView.reloadData()
        }
    }
}
