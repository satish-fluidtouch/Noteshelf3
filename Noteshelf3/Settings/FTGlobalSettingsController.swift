//
//  FTGlobalSettingsController.swift
//  Noteshelf3
//
//  Created by Narayana on 05/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
#if targetEnvironment(macCatalyst)
import Combine
#endif

class FTGlobalSettingsController: UITableViewController {
#if targetEnvironment(macCatalyst)
    static let macCatalystTopInset: CGFloat = 18.0;
    lazy var settingsSections: [[FTGlobalSettingsOptions]] = {
        var sections = [[FTGlobalSettingsOptions]]();
        if supportsHWRecognition {
            sections.append([.handwriting,.cloudAndBackup])
        }
        else {
            sections.append([.cloudAndBackup])
        }
        sections.append([.about,.noteshelfHelp])
        return sections;
    }();
    
    var premiumCancellableEvent: AnyCancellable?;
    
#else
    lazy var settingsSections: [[FTGlobalSettingsOptions]] = {
        var sections = [[FTGlobalSettingsOptions]]();
        var section1 : [FTGlobalSettingsOptions]  = [.appearance, .applePencil, .handwriting, .cloudAndBackup]
        if UIDevice.current.userInterfaceIdiom == .phone {
            section1 = [.appearance, .handwriting, .cloudAndBackup]
        }
#if DEBUG
        let section2 : [FTGlobalSettingsOptions] = [.about,.rateOnAppStore,.noteshelfHelp]
#else
        let section2 : [FTGlobalSettingsOptions] = [.about,.noteshelfHelp]
#endif
        sections.append(section1)
        sections.append(section2)
        return sections;
    }();
#endif

    override func viewDidLoad() {
        super.viewDidLoad()
#if DEBUG
        settingsSections.append([FTGlobalSettingsOptions.developerOptions])
#endif
        self.isModalInPresentation = true
        self.configureFooter()
        navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        tableView.separatorColor = UIColor.appColor(.black10)
        
#if targetEnvironment(macCatalyst)
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser.sink { [weak self] isPremium in
                self?.tableView.reloadData();
            }
        }
#endif
    }
#if targetEnvironment(macCatalyst)
    deinit{
        self.premiumCancellableEvent?.cancel();
        self.premiumCancellableEvent = nil;
    }
#endif
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if targetEnvironment(macCatalyst)
        self.configureNewNavigationBar(hideDoneButton: false, title:  "")
#else
        self.configureNewNavigationBar(hideDoneButton: false, title:  "Settings".localized)
#endif
    }
    private func openAppStore() {
        #if ENTERPRISE_EDITION
        let url = URL(string: "https://itunes.apple.com/us/app/noteshelf-3/id6471592545?mt=8")        
        #else
        let url = URL(string: "https://itunes.apple.com/us/app/noteshelf-3/id6458735203?mt=8")
        #endif
        if url != nil, UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
    private func configureFooter() {
        let footer = UILabel(frame: CGRect(origin: CGPoint(x: 24.0, y: 0.0), size: CGSize(width: 200.0, height: 40.0)))
        footer.text = FTUtils.getAppVersionInfo().lowercased().firstUppercased
        footer.font = UIFont.appFont(for: .regular, with: 13.0)
        self.tableView.tableFooterView = footer
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.settingsSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsSections[section].count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
#if targetEnvironment(macCatalyst)
        return  section == 0 ? FTGlobalSettingsController.macCatalystTopInset : .leastNonzeroMagnitude;
#else
        return CGFloat.leastNonzeroMagnitude
#endif
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.settingsSections.count - 1 { // Last Section
            return CGFloat.leastNonzeroMagnitude
        }
        return 18.0
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTGlobalSettingsTableViewCell") as? FTGlobalSettingsTableViewCell else { return UITableViewCell() }
        let setting = self.settingsSections[indexPath.section][indexPath.row]
        cell.globalSettingsimageView.image = UIImage(named: setting.imageName)
#if targetEnvironment(macCatalyst)
        if setting == .handwriting, let logo = UIImage(named: "premium_icon"), !FTIAPManager.shared.premiumUser.isPremiumUser {
            let attrTitle = setting.displayTitle.appendlogo(logo: logo
                                                            , font: cell.titleLabel.font
                                                            , capTo: CGSize(width: 20, height: 20));
            cell.titleLabel.attributedText = attrTitle;
        }
        else {
            cell.titleLabel.text  = setting.displayTitle
        }
#else
        cell.titleLabel.text  = setting.displayTitle
#endif
        cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let setting = self.settingsSections[indexPath.section][indexPath.row]
        switch setting{
//        case .general:
//            let childView = FTGeneralViewHostingController()
//            childView.title = NSLocalizedString(FTNewSettingsOptions.settingsGeneral.rawValue, comment: "General")
//            self.navigationController?.pushViewController(childView, animated: true)

        case .appearance:
            let childView = FTAppearanceViewHostingController()
            childView.title = "SettingOptionTheme".localized
            self.navigationController?.pushViewController(childView, animated: true)

        case .applePencil:
            let storyboard = UIStoryboard(name: "FTSettings_Stylus", bundle: nil)
            if let stylusController = storyboard.instantiateViewController(withIdentifier: "FTStylusesViewController") as? FTStylusesViewController {
                self.navigationController?.pushViewController(stylusController, animated: true);
            }

        case .handwriting:
#if targetEnvironment(macCatalyst)
            if FTIAPManager.shared.premiumUser.isPremiumUser {
                let storyboard = UIStoryboard(name: "FTNewSettings", bundle: nil);
                if let languageVc = storyboard.instantiateViewController(withIdentifier: FTRecognitionLanguageViewController.className) as? FTRecognitionLanguageViewController  {
                    self.navigationController?.pushViewController(languageVc, animated: true)
                }
            }
            else {
                FTIAPurchaseHelper.shared.showIAPAlertForFeature(feature: "HandWriting Recognition", on: self);
            }
#else
            let childView = FTHandWritingHostingController()
            childView.title = FTNewSettingsOptions.handwriting.rawValue.localized
            self.navigationController?.pushViewController(childView, animated: true)
#endif

        case .cloudAndBackup:
            let storyboard = UIStoryboard(name: "FTSettings_Accounts", bundle: nil);
            if let accountsController = storyboard.instantiateViewController(withIdentifier: FTAccountsViewController.className) as? FTAccountsViewController  {
                self.navigationController?.pushViewController(accountsController, animated: true)
            }

        case .noteshelfHelp:
            #if targetEnvironment(macCatalyst)
            FTDiagnosisHandler.sharedDiagnosisHandler().sendSystemLog(onViewController: self);
            FTCLSLog("UI: Send Log");
            #else
            FTZenDeskManager.shared.showSupportHelpCenterScreen(controller: self)
            FTCLSLog("UI: Knowledge Base");
            #endif

        case .about:
            let childView = FTAboutNoteShelfViewHostingController(aboutsettingsVm: FTSettingsAboutViewModel())
            childView.title = FTNewSettingsOptions.aboutNoteshelf.rawValue.localized
            self.navigationController?.pushViewController(childView, animated: true)

        case .whatsNew:
            FTWhatsNewViewController.showIfNeeded(on: self, source: FTSourceScreen.settings, placeOfSlideShow: .any, dismissBlock: nil);

        case .rateOnAppStore:
            openAppStore()
            
        case .developerOptions:
            let storyboard = UIStoryboard(name: "FTDeveloperOptions", bundle: nil)
            if let developerOptionsVC = storyboard.instantiateViewController(withIdentifier: "FTDeveloperOptionsViewController") as? FTDeveloperOptionsViewController {
                self.navigationController?.pushViewController(developerOptionsVC, animated: true);
            }
        }
    }
}
