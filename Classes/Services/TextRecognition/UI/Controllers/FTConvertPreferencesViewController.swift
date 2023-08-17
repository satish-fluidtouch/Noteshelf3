//
//  FTConvertPreferencesViewController.swift
//  Noteshelf
//
//  Created by Naidu on 20/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import Reachability

class FTConvertPreferencesViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    private var isInSearchMode = false
    private var filteredLanguages = [FTRecognitionLangResource]()
    private var supportedLanguages: [FTRecognitionLangResource] = FTLanguageResourceManager.shared.languageResources

    var isLanguageSettings: Bool = true
    var convertPreferredLanguage: String {
        get {
            FTConvertToTextViewModel.convertPreferredLanguage
        }
        set {
            FTConvertToTextViewModel.convertPreferredLanguage = newValue
        }
    }

    var convertPreferredFont: String {
        get {
            FTConvertToTextViewModel.convertPreferredFont
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "convertPreferredFont")
            UserDefaults.standard.synchronize()
        }
    }

    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated")
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(UINib.init(nibName: "FTConvertPreferencesCell", bundle: nil), forCellReuseIdentifier: "FTConvertPreferencesCell")
        self.configureNavigationBar()
        self.addObservers()
        self.configSearchbar()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTResourceDownloadStatusDidChange), object: nil, queue: nil) { [weak self] (notification) in
            DispatchQueue.main.async {
                self?.supportedLanguages = FTLanguageResourceManager.shared.languageResources
                self?.tableView?.reloadData()
            }
        }
    }

    private func configureNavigationBar() {
        if(self.isLanguageSettings) {
            self.navigationItem.title = FTLanguageLocalizedString("Languages", comment: "Languages")
        } else {
            self.navigationItem.title = NSLocalizedString("FontSize",comment: "Font Size")
        }
        let navFont = UIFont.clearFaceFont(for: .medium, with: 20)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: navFont]
    }

    @IBAction func backButtonClicked(_ sender: UIButton){
        self.navigationController?.popViewController(animated: true)
    }
}

extension FTConvertPreferencesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isLanguageSettings {
            return FTLanguageSection.all.rawValue
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.isLanguageSettings {
            return FTConvertFontSize.allCases.count
        }
        guard let ftSection = FTLanguageSection(rawValue: section) else {
            return 0
        }
        let rows: Int;
        switch ftSection {
        case .general:
            rows = self.contentsToDisplay.count;
        case .noResults:
            rows = (isInSearchMode && self.contentsToDisplay.isEmpty) ? 1: 0
        default:
            rows = 0;
        }
        return rows;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.isLanguageSettings {
            guard let section = FTLanguageSection(rawValue: indexPath.section),
                  section == .general else {
                      return 50.0
            }
            if self.contentsToDisplay[indexPath.row].languageCode == languageCodeNone {
                return 0
            }
        }
        return 64.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTConvertPreferencesCell") as? FTConvertPreferencesCell else {
            fatalError("Programmer error - Couldnot find FTConvertPreferencesCell")
        }
        let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .medium, with: 16))
        let checkMarkImg = UIImage(systemName: "checkmark")?.withConfiguration(configuration)
        cell.downloadButton?.tintColor = .label

        if !self.isLanguageSettings, indexPath.section == 0 {
            let fontPreference = FTConvertFontSize(rawValue: indexPath.row)
            cell.labelSubTitle?.text = fontPreference?.preferenceDetails
            cell.titleLabel?.text = fontPreference?.displayTitle
            if (self.convertPreferredFont == fontPreference?.displayTitle) {
                cell.downloadButton?.isHidden = false
                cell.downloadButton?.setImage(checkMarkImg, for: .normal)
            } else {
                cell.downloadButton?.isHidden = true
            }
            cell.activityIndicator?.isHidden = true
        } else {
            guard let ftSection = FTLanguageSection(rawValue: indexPath.section),
                  ftSection != FTLanguageSection.all else {
                fatalError("FTRecognitionLanguageViewController should not enter here");
            }
            
            if ftSection == FTLanguageSection.noResults {
                let cell = ftSection.noResultsCell(for: tableView)
                return cell
            }

            let language = self.contentsToDisplay[indexPath.row]
            cell.labelSubTitle?.text = language.displayName
            cell.downloadButton?.isHidden = false
            cell.activityIndicator?.isHidden = true
            cell.labelSubTitle?.isHidden = false

            if language.resourceStatus == .downloaded {
                cell.downloadButton?.isHidden = true
                cell.activityIndicator?.isHidden = true
                cell.activityIndicator?.stopAnimating()
            } else if language.resourceStatus == .downloading{
                cell.downloadButton?.isHidden = true
                cell.activityIndicator?.isHidden = false
                cell.activityIndicator?.startAnimating()
            } else {
                cell.downloadButton?.isHidden = false
                cell.activityIndicator?.isHidden = true
                cell.activityIndicator?.stopAnimating()
            }
            if(language.languageCode == self.convertPreferredLanguage && language.resourceStatus == .downloaded){
                cell.downloadButton?.isHidden = false
                cell.downloadButton?.setImage(checkMarkImg, for: UIControl.State.normal)
            } else {
                let config = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .medium, with: 16))
                let image = UIImage(systemName: "icloud.and.arrow.down")?.withConfiguration(config)
                cell.downloadButton?.setImage(image, for: .normal)
                cell.downloadButton?.tintColor = UIColor.appColor(.accent)
            }
            cell.titleLabel?.text = language.nativeDisplayName
            if (language.displayName == language.nativeDisplayName){
                cell.labelSubTitle?.isHidden = true
            } else {
                cell.labelSubTitle?.isHidden = false
            }
        }
        cell.selectionStyle = .none
        cell.accessoryType = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if !self.isLanguageSettings, indexPath.section == 0 {
            if let fontPreference = FTConvertFontSize(rawValue: indexPath.row) {
                self.convertPreferredFont = fontPreference.displayTitle
                self.tableView?.reloadData()
            }
        } else {
            guard let ftSection = FTLanguageSection(rawValue: indexPath.section),
                  ftSection == FTLanguageSection.general else {
                return
            }
            let language = self.contentsToDisplay[indexPath.row]
            if language.resourceStatus == .downloaded {
                self.convertPreferredLanguage = language.languageCode;
                self.tableView?.reloadData()
            } else if language.resourceStatus == .none{
                let reachability:Reachability = Reachability.forInternetConnection()
                let status:NetworkStatus = reachability.currentReachabilityStatus();
                if (status == NetworkStatus.NotReachable) {
                    UIAlertController.showAlert(withTitle: "NoInternetHeader".localized, message: "MakeSureYouAreConnected".localized, from: self, withCompletionHandler: nil)
                    return
                }

                language.downloadCompletionCallback = {[weak self] in
                    self?.convertPreferredLanguage = language.languageCode
                    self?.tableView?.reloadData()
                }
                language.downloadResourceOnDemand()
            }
        }
    }
}

extension FTConvertPreferencesViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder();
        self.isInSearchMode = false;
        searchBar.text = nil;
        self.filteredLanguages.removeAll();
        self.tableView?.reloadData();
        self.tableView?.scrollToRow(at: IndexPath(row: 0, section: FTLanguageSection.general.rawValue), at: .top, animated: false);
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder();
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.isInSearchMode = !(searchText.isEmpty);
        self.filter(for: searchText);
        self.tableView?.reloadData();
    }
}

private extension FTConvertPreferencesViewController {
    func configSearchbar(){
        if self.isLanguageSettings {
            self.tableView.reloadData()
            self.searchBar.isHidden = false
            self.searchBar.backgroundImage = UIImage()
            self.searchBar.placeholder = "Search".localized
            self.searchBar.layoutMargins = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
            self.searchBar.showsCancelButton = false
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: FTLanguageSection.general.rawValue), at: .top, animated: false)
        }
        else {
            self.searchBar?.frame = CGRect.zero
        }
    }
    
    func filter(for searchText: String) {
        self.filteredLanguages.removeAll();
        if self.isInSearchMode {
            let lowersCased = searchText.lowercased();
            self.filteredLanguages = self.supportedLanguages.filter { eachItem in
                if eachItem.languageCode != languageCodeNone,
                   (eachItem.nativeDisplayName.lowercased().contains(lowersCased)
                || eachItem.displayName.lowercased().contains(lowersCased)) {
                    return true;
                }
                return false;
            }
        }
    }
    
    var contentsToDisplay: [FTRecognitionLangResource] {
        if isInSearchMode {
            return self.filteredLanguages;
        }
        else {
            return self.supportedLanguages;
        }
    }
}
