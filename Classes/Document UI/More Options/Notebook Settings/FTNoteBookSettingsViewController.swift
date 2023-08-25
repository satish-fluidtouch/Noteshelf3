//
//  FTNoteBookSettingsViewController.swift
//  Noteshelf3
//
//  Created by Sameer on 10/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import IntentsUI
import FTNewNotebook

protocol FTNoteBookSettingsVCDelegate : NSObject {
    func presentPasswordScreen()
}

class FTNoteBookSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView?
    var settings = [[FTNoteBookSettings]]()
    var siriShortcut: INVoiceShortcut?
    weak var notebookDocument: FTDocumentProtocol!
    weak var notebookShelfItem: FTShelfItemProtocol!
    weak var delegate: FTNoteBookSettingsVCDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var height: CGFloat = 448.0
#if targetEnvironment(macCatalyst)
        height -= 44.0
#endif
        self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: height)
    }
    
    override func viewDidLoad() {
        var firstSection: [FTNoteBookSettings] = [.password]
#if !targetEnvironment(macCatalyst)
        firstSection.append(.addToSiri)
#endif
        var secondSection : [FTNoteBookSettings] = [.scrolling, .hideUiInPresentMode, .allowHyperLinks, .autoLock]
        if UIDevice.current.userInterfaceIdiom == .pad {
            secondSection.append(.stylus)
        }
        settings.append(firstSection)
        settings.append(secondSection)
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "standardCell")
        self.tableView?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView?.sectionHeaderTopPadding = 0
        configureFooter()
        self.tableView?.estimatedRowHeight = UITableView.automaticDimension
        isSiriShortcutAvailable(for: self.notebookShelfItem) {[weak self] shortCut in
            self?.siriShortcut = shortCut
            self?.tableView?.reloadData()
        }
        self.configureCustomNavigation(title: "notebook.settings.moresettings".localized)
    }
    
    private func configureFooter() {
        let footer = UILabel(frame: CGRect(origin: CGPoint(x: 32.0, y: 0.0), size: CGSize(width: 280, height: 50.0)))
        footer.text = "more.settings.footer".localized
        footer.font = UIFont.appFont(for: .regular, with: 15.0)
        footer.textColor = UIColor.appColor(.black50)
        footer.numberOfLines = 2
        self.tableView?.tableFooterView = footer
    }
   
    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "more.globalsettings.caps".localized
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 24.0
    }

#if targetEnvironment(macCatalyst)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
#endif

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settings = settings[indexPath.section]
        let eachSetting = settings[indexPath.row]
        let cell: UITableViewCell
        if eachSetting.cellType() == .custom {
            cell = tableView.dequeueReusableCell(withIdentifier: "FTNoteBookSegmentCell", for: indexPath)
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
            var content = cell.defaultContentConfiguration()
            if let siriShortcut,  eachSetting == .addToSiri {
                let phrase = "\(siriShortcut.invocationPhrase)"
                content.secondaryAttributedText = NSAttributedString(string: phrase, attributes: [.font: UIFont.appFont(for: .regular, with: 15), .foregroundColor: UIColor.appColor(.black50)])
            }
            let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17.0)]
            content.attributedText = NSAttributedString(string: eachSetting.title(), attributes: attributes)
#if targetEnvironment(macCatalyst)
            content.directionalLayoutMargins.leading = 16.0
            content.directionalLayoutMargins.trailing = 16.0
#endif
            cell.contentConfiguration = content
        }
        cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        if eachSetting.cellType() == .toggle {
            cell.accessoryType = .none
            let toggleSwitch = UISwitch(frame: CGRect.zero)
            toggleSwitch.preferredStyle = .sliding
            updateToggleSwitch(uiSwitch: toggleSwitch, for: eachSetting)
            toggleSwitch.addAction(UIAction(handler: {[weak self] action in
                self?.switchvalueChanged(for: eachSetting)
            }), for: .touchUpInside)
            cell.accessoryView = toggleSwitch
        } else if eachSetting.cellType() == .disclosure {
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func updateToggleSwitch(uiSwitch: UISwitch, for setting: FTNoteBookSettings) {
        if setting == .allowHyperLinks {
            uiSwitch.isOn = !FTUserDefaults.isHyperlinkDisabled()
        } else if setting == .hideUiInPresentMode {
            uiSwitch.isOn = !FTUserDefaults().shouldPresentAppUIOnPresentation
        } else if setting == .autoLock {
            uiSwitch.isOn = FTUserDefaults.disableAutoLock
            self.updateIdleTimerDisabledStatus()
        }
    }
    
    fileprivate func switchvalueChanged(for setting: FTNoteBookSettings) {
        if setting == .allowHyperLinks {
            let hyperlinkDisabled = FTUserDefaults.isHyperlinkDisabled()
            FTUserDefaults.disableHyperlink(!hyperlinkDisabled)
        } else if setting == .hideUiInPresentMode {
            let presentUI = FTUserDefaults().shouldPresentAppUIOnPresentation
            FTUserDefaults().shouldPresentAppUIOnPresentation = !presentUI
            NotificationCenter.default.post(name: NSNotification.Name.FTDidChangeWhiteBoardScreenValue, object: nil);
        } else if setting == .autoLock {
            let disableAutoLock = FTUserDefaults.disableAutoLock
            FTUserDefaults.disableAutoLock = !disableAutoLock
            self.updateIdleTimerDisabledStatus()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let settings = settings[indexPath.section]
        let eachSetting = settings[indexPath.row]
        if eachSetting == .stylus {
            let storyboard = UIStoryboard(name: "FTSettings_Stylus", bundle: nil)
            if let stylusController = storyboard.instantiateViewController(withIdentifier: "FTStylusesViewController") as? FTStylusesViewController {
                stylusController.contentSize = CGSize(width: defaultPopoverWidth, height: 210)
                stylusController.hideNavButtons = true
                self.navigationController?.pushViewController(stylusController, animated: true)
            }
        } else if eachSetting == .addToSiri {
            self.handleSiriSetting()
        } else if eachSetting == .password {
            self.delegate?.presentPasswordScreen()
        }
    }

    private func updateIdleTimerDisabledStatus(){
        FTDeviceAutoLockHelper.share.autoLockUsingDisableAutoLockStatus()
    }
}
