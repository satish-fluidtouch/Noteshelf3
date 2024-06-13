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
    func presentGesturesScreen()
    func presentNoteShelfHelpScreen()
}

class FTNoteBookSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView?
    var settings = [[FTNoteBookSettings]]()
    var siriShortcut: INVoiceShortcut?
    weak var notebookDocument: FTDocumentProtocol!
    weak var notebookShelfItem: FTShelfItemProtocol!
    weak var delegate: FTNoteBookSettingsVCDelegate?
    weak var page: FTPageProtocol!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var height: CGFloat = 342
#if targetEnvironment(macCatalyst)
        height -= 100.0
#endif
        self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: height)
    }
    
    override func viewDidLoad() {
        var firstSection : [FTNoteBookSettings] = [ .hideUiInPresentMode, .allowHyperLinks, .autoLock]
        var secondSection : [FTNoteBookSettings] = []
#if !targetEnvironment(macCatalyst)
        secondSection.append(.gestures)
#endif
        secondSection.append(.noteShelfHelp)
        if !FTFeatureConfigHelper.shared.isFeatureEnabled(.Allow_hyperlinks) {
            firstSection = firstSection.filter{$0 != .allowHyperLinks}
        }
        
        settings.append(firstSection)
        settings.append(secondSection)
        
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "standardCell")
        self.tableView?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView?.sectionHeaderTopPadding = 0
        //  configureFooter()
        self.tableView?.estimatedRowHeight = UITableView.automaticDimension
        //        isSiriShortcutAvailable(for: self.notebookShelfItem) {[weak self] shortCut in
        //            self?.siriShortcut = shortCut
        //            self?.tableView?.reloadData()
        //        }
        self.navigationController?.navigationBar.isHidden = false
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
            //return "more.globalsettings.caps".localized
            return "Help".localized
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
            if eachSetting == .noteShelfHelp {
                content.image = UIImage(named:"questionmark.circle")
            } else if eachSetting == .gestures {
                content.image = UIImage(named:"hand.tap")
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
                if eachSetting == .evernoteSync {
                    self.updateEvernoteToggleSwitch(uiSwitch: toggleSwitch, withStatus: FTENPublishManager.shared.isSyncEnabled(forDocumentUUID: notebookDocument.documentUUID))
                } else {
                    updateToggleSwitch(uiSwitch: toggleSwitch, for: eachSetting)
                }
                toggleSwitch.addAction(UIAction(handler: {[weak self] action in
                    self?.switchvalueChanged(for: eachSetting, toggleSwitch)
                }), for: .valueChanged)
                cell.accessoryView = toggleSwitch
            } else if eachSetting.cellType() == .disclosure {
                cell.accessoryType = .disclosureIndicator
                cell.accessoryView = nil
            }else if eachSetting.cellType() == .defaultCell {
                cell.accessoryType = .none
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
        func updateEvernoteToggleSwitch(uiSwitch: UISwitch, withStatus status:Bool){
            uiSwitch.isOn = status
        }
        
        fileprivate func switchvalueChanged(for setting: FTNoteBookSettings,_ uiSwitch:UISwitch) {
            if setting == .allowHyperLinks {
                let hyperlinkDisabled = FTUserDefaults.isHyperlinkDisabled()
                FTUserDefaults.disableHyperlink(!hyperlinkDisabled)
                let str = !hyperlinkDisabled ? "off" : "on"
                FTNotebookEventTracker.trackNotebookEvent(with: setting.eventName, params: ["toggle": str])
            } else if setting == .hideUiInPresentMode {
                let presentUI = FTUserDefaults().shouldPresentAppUIOnPresentation
                FTUserDefaults().shouldPresentAppUIOnPresentation = !presentUI
                let str = !presentUI ? "off" : "on"
                FTNotebookEventTracker.trackNotebookEvent(with: setting.eventName, params: ["toggle": str])
                NotificationCenter.default.post(name: NSNotification.Name.FTDidChangeWhiteBoardScreenValue, object: nil);
            } else if setting == .autoLock {
                let disableAutoLock = FTUserDefaults.disableAutoLock
                FTUserDefaults.disableAutoLock = !disableAutoLock
                self.updateIdleTimerDisabledStatus()
                let str = !disableAutoLock ? "on" : "off"
                FTNotebookEventTracker.trackNotebookEvent(with: setting.eventName, params: ["toggle": str])
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
                //self.handleSiriSetting()
            } else if eachSetting == .password {
                self.delegate?.presentPasswordScreen()
            } else if eachSetting == .gestures {
                self.delegate?.presentGesturesScreen()
            } else if eachSetting == .noteShelfHelp {
                self.delegate?.presentNoteShelfHelpScreen()
            }
            FTNotebookEventTracker.trackNotebookEvent(with: eachSetting.eventName)
        }
        
        private func updateIdleTimerDisabledStatus(){
            FTDeviceAutoLockHelper.share.autoLockUsingDisableAutoLockStatus()
        }
    }
    

