//
//  FTApplePencilDoubleTapViewController.swift
//  Noteshelf
//
//  Created by Matra on 01/11/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

let FTPencilActionChangedNotification = "FTPencilActionChangedNotification"

class FTApplePencilDoubleTapViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var tableView: UITableView?
    var contentSize = CGSize.zero
    var hideNavButtons = false
    @IBOutlet weak var gotoApplePencilSettings: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        gotoApplePencilSettings.addTarget(self, action: #selector(gotoApplePencilSettingsTapped), for: .touchUpInside)
        self.tableView?.separatorColor = UIColor.appColor(.black10)
        tableView?.estimatedRowHeight = UITableView.automaticDimension
        if hideNavButtons {
            self.view.backgroundColor = UIColor.appColor(.popoverBgColor)
            self.configureCustomNavigation(title: "DoubleTapAction".localized)
        } else {
            self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
            self.configureNewNavigationBar(hideDoneButton: false, title: "DoubleTapAction".localized)
        }
        gotoApplePencilSettings.setTitle("stylus.goto.settings".localized, for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.contentSize != .zero {
            self.navigationController?.preferredContentSize = contentSize
        }
    }
    // MARK: - UITableViewDelegate
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FTApplePencilInteractionType.allCases.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
#if targetEnvironment(macCatalyst)
        return  FTGlobalSettingsController.macCatalystTopInset;
#else
        return  .leastNonzeroMagnitude
#endif
   }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
   }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTDoubleTapPencilCell", for: indexPath) as? FTDoubleTapPencilCell else {
            fatalError("Programmer error - couldnot find FTDoubleTapPencilCell")
        }
        if let actionToShow = FTApplePencilInteractionType(rawValue: indexPath.row) {
            cell.titleLabel?.text = NSLocalizedString(actionToShow.localizedString(), comment: "Action Name");
            if actionToShow == .systemDefault {
                let _: NSMutableAttributedString = systemDefaultDescription()
                cell.titleLabel?.text = NSLocalizedString(actionToShow.localizedString(), comment: "Action Name") + ": \(applePencilMessageDefaultOption())"
            }
            cell.checkMarkImageView.isHidden = true
            let storedAction = FTUserDefaults.applePencilDoubleTapAction();
            if storedAction == actionToShow {
                cell.checkMarkImageView.isHidden = false
            }
            cell.tintColor = UIColor.label
            cell.updateConstraintsIfNeeded()
        }
        return cell
    }
    
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        if let actionToShow = FTApplePencilInteractionType(rawValue: indexPath.row) {
            if FTUserDefaults.applePencilDoubleTapAction() == FTApplePencilInteractionType.systemDefault
                && actionToShow != FTApplePencilInteractionType.systemDefault {
                let alertController = UIAlertController.init(title: "", message: NSLocalizedString("PencilActionAlert", comment: "This action will override the system default only for this app. Would you like to Proceed?"), preferredStyle: UIAlertController.Style.alert)
                
                let action = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: nil)
                alertController.addAction(action)
                
                let action2 = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: { (_) in
                    self.updateDoubleTapValueTo(actionToShow)
                })
                alertController.addAction(action2)
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                updateDoubleTapValueTo(actionToShow)
            }
            trackEventsForSelectedAction(actionToShow)
        }
    }
    
    fileprivate func updateDoubleTapValueTo(_ value: FTApplePencilInteractionType) {
        UserDefaults.standard.set(true, forKey: "APPLE_PENCIL_DOUBLE_TAP_ALERT_SHOWN");
        UserDefaults.standard.synchronize();
        
        FTUserDefaults.setApplePencilDoubleTapAction(value);
        let notification = Notification(name: Notification.Name(rawValue: FTPencilActionChangedNotification), object: nil)
        NotificationCenter.default.post(notification)
        self.tableView?.reloadData()
    }
    
    func systemDefaultDescription() -> NSMutableAttributedString {
        let partTwo = NSMutableAttributedString(string: "\(applePencilMessageDefaultOption())", attributes: [
            NSAttributedString.Key.font: UIFont(name: "SFProText-Semibold", size: 14) ?? UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.7)
        ])
        
        return partTwo
    }
    
    func applePencilMessageDefaultOption() -> String {
        switch UIPencilInteraction.preferredTapAction {
        case .switchEraser:
            return NSLocalizedString("OptionEraser", comment: "Eraser")
        case .switchPrevious:
            return NSLocalizedString("OptionLastUsedTool", comment: "Previous Tool")
        case .showColorPalette:
            return NSLocalizedString("OptionColorPalette", comment: "Show Colors")
        default:
            return NSLocalizedString("BackupOff", comment: "Off")
        }
    }
    @objc func gotoApplePencilSettingsTapped(_ sender : UIButton) {
        if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
            UIApplication.shared.open(url)
        }
    }
    private func trackEventsForSelectedAction(_ action: FTApplePencilInteractionType) {
        var eventName: String = ""
        switch action {
        case .systemDefault:
            eventName = "Shelf_Settings_Stylus_DoubTap_Default"
        case .previousTool:
            eventName = "Shelf_Settings_Stylus_DoubTap_CurrLast"
        case .eraser:
            eventName = "Shelf_Settings_Stylus_DoubTap_CurrEraser"
        case .showColors:
            eventName = "Shelf_Settings_Stylus_DoubTap_ShowColor"
        case .distractionFree:
            eventName = "Shelf_Settings_Stylus_DoubTap_ShowFav"
        }
        if eventName != "" {
            track(eventName, params: [:], screenName: FTScreenNames.shelfSettings)
        }
    }
}

class FTDoubleTapPencilCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkMarkImageView: UIImageView!
}
