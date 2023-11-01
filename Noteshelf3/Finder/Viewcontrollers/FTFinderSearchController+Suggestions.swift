//
//  FTFinderSearchController+Suggestions.swift
//  Noteshelf3
//
//  Created by Sameer on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTFinderSearchController: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            perfromSearchCancel()
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == recentsTableView {
            return FTFilterRecentsStorage.shared.availableRecents().count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == recentsTableView {
            if let cell = tableView.dequeueReusableCell(withIdentifier: kRecentSearchCell, for: indexPath) as? FTRecentSearchCell {
                let items = FTFilterRecentsStorage.shared.availableRecents()[indexPath.row]
                cell.configureCell(with: items)
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == recentsTableView && FTFilterRecentsStorage.shared.availableRecents().count > 0 {
            let header = FTRecentSectionHeader.recentSectionHeader(with: self)
            header.updateSectionTitle("Recents")
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == recentsTableView && FTFilterRecentsStorage.shared.availableRecents().count > 0  {
            return 40
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == recentsTableView {
            hideSuggestions = true
            let items = FTFilterRecentsStorage.shared.availableRecents()[indexPath.row]
            var searchTokens = [UISearchToken]()
            var searchableText = ""
            items.forEach { eachItem in
                if eachItem.type == .tag {
                    let tag = FTTagModel(text: eachItem.name, isSelected: true)
                    let suggestedItem = FTSuggestedItem(tag: tag, type: .tag, suggestion: NSMutableAttributedString(string: eachItem.name))
                    let token = searchToken(for: suggestedItem)
                    searchTokens.append(token)
                } else {
                    searchableText += "\(eachItem.name)"
                }
            }
            if !searchTokens.isEmpty  {
                self.searchBar?.searchTextField.tokens = searchTokens
                constructSelectedTags()
            }
            if !searchableText.isEmpty {
                self.searchBar?.searchTextField.text = ""
                self.searchBar?.searchTextField.text = searchableText
                self.searchOptions.searchedKeyword = searchableText
            }
            self.searchText = self.searchBar?.searchTextField.text ?? ""
            self.initiateSearch()
            runInMainThread { [weak self] in
                guard let self = self else {
                    return
                }
                if !(self.searchBar?.searchTextField.isFirstResponder ?? false) {
                    self.hideSuggestions = false
                }
            }
           
        }
    }
}

extension FTFinderSearchController: FTRecentSectionDelegate {
    func didTapClearAllButton() {
        UIAlertController.showConfirmationDialog(with: "finder.clear.recents".localized, message: "", from: self) {
            FTFilterRecentsStorage.shared.clear()
            self.recentsTableView.reloadData()
        }
    }
}
