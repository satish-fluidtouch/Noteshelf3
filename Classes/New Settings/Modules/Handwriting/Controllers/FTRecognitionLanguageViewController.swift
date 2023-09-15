//
//  FTRecognitionLanguageTableViewController.swift
//  Noteshelf
//
//  Created by Matra on 17/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//


import Reachability
import UIKit

enum FTLanguageSection: Int {
    case general,noResults,all;
    
    func noResultsCell(for tableView: UITableView) -> UITableViewCell {
        guard self == .noResults else {
            fatalError("should not call this");
        }
        let tbcell = tableView.dequeueReusableCell(withIdentifier: "noResults") ?? UITableViewCell(style: .default, reuseIdentifier: "noResults");
        tbcell.textLabel?.font = UIFont.appFont(for: .regular, with: 16)
        tbcell.textLabel?.textColor = UIColor.appColor(.black50);
        tbcell.textLabel?.textAlignment = .center;
        tbcell.textLabel?.text = NSLocalizedString("NoResultFound", comment: "Search");
        tbcell.selectionStyle = .none;
        tbcell.contentView.backgroundColor = UIColor.appColor(.formSheetBgColor)
        return tbcell;
    }
}

class FTRecognitionLanguageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var supportedLanguages: [FTRecognitionLangResource] = []
    private var backButton: UIButton?
    @IBOutlet weak var tableView: UITableView?

    @IBOutlet private weak var seachBar: UISearchBar?;
    private var filteredLanguages = [FTRecognitionLangResource]();
    private var isInSearchMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.seachBar?.isHidden = true
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FTResourceDownloadStatusDidChange), object: nil, queue: nil) { [weak self] (_) in
            DispatchQueue.main.async {
                self?.supportedLanguages = FTLanguageResourceManager.shared.languageResources
                self?.tableView?.reloadData()
            }
        }
        self.supportedLanguages = FTLanguageResourceManager.shared.languageResources
        self.loadTableView()
        self.configSearchbar()
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        self.tableView?.separatorColor = UIColor.appColor(.black10)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false, title: FTLanguageLocalizedString("Languages", comment: ""))
        self.tableView?.contentOffset = CGPoint(x: self.tableView?.contentOffset.x ?? 0.0, y: 50.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.seachBar?.isHidden = false
    }
    
    private func loadTableView() {
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
    }
    // MARK: - Table view data source

     func numberOfSections(in tableView: UITableView) -> Int {
        return FTLanguageSection.all.rawValue;
    }
    
     func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         return section == 0 ? 27.0 : .leastNonzeroMagnitude
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let ftSection = FTLanguageSection(rawValue: section) else {
            return 0;
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
    
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return 56.0
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let ftSection = FTLanguageSection(rawValue: indexPath.section),
              ftSection != FTLanguageSection.all else {
            fatalError("FTRecognitionLanguageViewController should not enter here");
        }
        
        if ftSection == FTLanguageSection.noResults {
            let cell = ftSection.noResultsCell(for: tableView);
            return cell;
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FTLanguageSelectionTableViewCell.className, for: indexPath) as? FTLanguageSelectionTableViewCell;
        cell?.prepareCell()
        let language = self.contentsToDisplay[indexPath.row];
        cell?.populateCellWith(language)
        cell?.downloadButton?.addTarget(self, action: #selector(FTRecognitionLanguageViewController.downloadButtonClicked(_:)), for: UIControl.Event.touchUpInside)
        cell?.downloadButton?.tag = indexPath.row
        return cell!;
    }

    @objc private func downloadButtonClicked(_ sender: UIButton) {
        //User interaction disabled to download on clicking anywhere in cell
        let language = self.contentsToDisplay[sender.tag];
        language.downloadCompletionCallback = {

        }
        language.downloadResourceOnDemand()
    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        guard let ftSection = FTLanguageSection(rawValue: indexPath.section),
              ftSection == FTLanguageSection.general else {
            return;
        }

        let language = self.contentsToDisplay[indexPath.row];
        if language.resourceStatus == .downloaded {
            FTLanguageResourceManager.shared.currentLanguageCode = language.languageCode;
            FTLanguageResourceManager.shared.isPreferredLanguageChosen = true
            FTLanguageResourceManager.shared.lastSelectedLangCode = "" //To stop automatic language selection which has "activateWhenDownloaded = true"
            self.tableView?.reloadData()
            
            if language.languageCode == languageCodeNone {
                 track("Shelf_Settings_HandWriteRecg_Disable", params: [:], screenName: FTScreenNames.shelfSettings)
            } else {
                track("Shelf_Settings_HandWriteRecg_\(language.languageEventName!)", params: [:], screenName: FTScreenNames.shelfSettings)
            }
        } else if language.resourceStatus == .none {
            let reachability: Reachability = Reachability.forInternetConnection()
            let status: NetworkStatus = reachability.currentReachabilityStatus();
            if status == NetworkStatus.NotReachable {
                UIAlertController.showAlert(withTitle: "NoInternetHeader".localized, message: "MakeSureYouAreConnected".localized, from: self, withCompletionHandler: nil)
                return
            }

            language.activateWhenDownloaded = true
            FTLanguageResourceManager.shared.lastSelectedLangCode = language.languageCode
            language.downloadResourceOnDemand()
        }
    }
}

private extension FTRecognitionLanguageViewController {
    func configSearchbar(){
        self.tableView?.reloadData()
        self.seachBar?.placeholder = NSLocalizedString("Search", comment: "Search")
        self.seachBar?.backgroundImage = UIImage()
        self.seachBar?.tintColor = .appColor(.accent)
        self.seachBar?.isHidden = true
        self.tableView?.scrollToRow(at: IndexPath(row: 0, section: FTLanguageSection.general.rawValue), at: .top, animated: false)
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

extension FTRecognitionLanguageViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder();
        self.isInSearchMode = false;
        searchBar.text = nil;
        self.filteredLanguages.removeAll();
        self.tableView?.reloadData();
        self.tableView?.scrollToRow(at: IndexPath(row: 0, section: FTLanguageSection.general.rawValue), at: .top, animated: false);
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
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
