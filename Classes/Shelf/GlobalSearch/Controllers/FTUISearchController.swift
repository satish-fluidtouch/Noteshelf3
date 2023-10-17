//
//  FTUISearchController.swift
//  Noteshelf3
//
//  Created by Narayana on 01/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import Combine

protocol FTUISearchDelegate: AnyObject {
    func didTapOnSuggestion(_ suggestionItem: FTSuggestedItem)
    func textFieldDidBeginEditing(key: String)
    func textFieldDidChangeSelection(key: String)
    func textFieldDidEndEditing(key: String)
    func didTapOnCancelButton()
}

final class FTUISearchController: UISearchController {
    private var handler: FTUISearchBarHandler?

    private(set) var searchTokens: [UISearchToken] {
        get {
            return self.handler?.searchTokens ?? []
        } set {
            self.self.handler?.searchTokens = newValue
        }
    }

    init() {
        super.init(searchResultsController: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureSearch(with del: FTUISearchDelegate?) {
        self.handler = FTUISearchBarHandler(searchbar: self.searchBar)
        self.handler?.delegate = del
        self.searchBar.searchTextField.delegate = handler
        self.searchBar.delegate = handler
        self.searchResultsUpdater = handler
    }

    func populateSuggestionsIfNeeded(for key: String, tags: [FTTagModel]) {
        let tokens = key.isEmpty ? [] : FTSearchSuggestionHelper.shared.fetchSearchSuggestion(for: key, tags: tags)
        self.searchSuggestions = tokens
    }

    func bringSearchBarResponder() {
        self.searchBar.searchTextField.becomeFirstResponder()
    }

    func resignSearchbarResponder() {
        self.searchBar.searchTextField.resignFirstResponder()
    }

    func updateSearchTokens(_ tokens: [UISearchToken]) {
        self.searchTokens = tokens
    }
}

final class FTUISearchBarHandler: NSObject {
    weak var delegate: FTUISearchDelegate?
    let searchbar: UISearchBar
    private var cancellables: Set<AnyCancellable> = []

    var searchTokens: [UISearchToken] {
        get {
            return searchbar.searchTextField.tokens
        } set {
            searchbar.searchTextField.tokens = newValue
        }
    }

    init(searchbar: UISearchBar) {
        self.searchbar = searchbar
        super.init()
        let textPublisher = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: searchbar.searchTextField)
            .compactMap { $0.object as? UITextField }
            .map { $0.text }
        let debouncedPublisher = textPublisher
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .removeDuplicates()
        debouncedPublisher
            .sink { [weak self] text in
                if let keyWord = text {
                    self?.delegate?.textFieldDidChangeSelection(key: keyWord)
                }
            }
            .store(in: &cancellables)
    }
}

extension FTUISearchBarHandler: UISearchBarDelegate, UISearchTextFieldDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }

    func updateSearchResults(for searchController: UISearchController, selecting searchSuggestion: UISearchSuggestion) {
        if let suggestion = searchSuggestion.representedObject as? FTSuggestedItem {
            self.delegate?.didTapOnSuggestion(suggestion)
        }
    }

     func searchTextField(_ searchTextField: UISearchTextField, didSelect suggestion: UISearchSuggestion) {
         if let suggestion = suggestion.representedObject as? FTSuggestedItem {
             self.delegate?.didTapOnSuggestion(suggestion)
         }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let keyWord = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        self.delegate?.textFieldDidBeginEditing(key: keyWord)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let keyWord = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !keyWord.isEmpty {
            self.delegate?.textFieldDidEndEditing(key: keyWord)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.delegate?.didTapOnCancelButton()
    }
}
