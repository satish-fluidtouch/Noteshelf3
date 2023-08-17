//
//  FTCreateNotebookOptionsViewController.swift
//  Noteshelf
//
//  Created by Siva on 20/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTNewNotebookOptionType {
    case autoBackup(isEnabled: Bool)
    case evernoteSync(isEnabled: Bool, isBusiness: Bool)
    case passcodeLock(isEnabled: Bool)

    var isEnabled: Bool {
        switch self {
        case let .autoBackup(isEnabled):
            return isEnabled;
        case let .evernoteSync(isEnabled, _):
            return isEnabled;
        case let .passcodeLock(isEnabled):
            return isEnabled;
        }
    }

    mutating func updateEnable(_ status: Bool) {
        switch self {
        case .autoBackup(_):
            self = .autoBackup(isEnabled: status);
        case let .evernoteSync(_, isBusiness):
            self = .evernoteSync(isEnabled: status, isBusiness: isBusiness);
        case .passcodeLock(_):
            self = .passcodeLock(isEnabled: status);
        }
    }

    mutating func updateBusiness(_ status: Bool) {
        switch self {
        case .evernoteSync(isEnabled, _):
            self = .evernoteSync(isEnabled: isEnabled, isBusiness: status);
        default:
            break;
        }
    }


    var canDisable: Bool {
        switch self {
        case .autoBackup(_):
            return true;
        case .evernoteSync(_, _):
            return true;
        case .passcodeLock(_):
            return false;
        }
    }
}

class FTNewNoteBookSetting {
    var type: FTNewNotebookOptionType!
    var title: String!
    var selector: Selector;

    init(type: FTNewNotebookOptionType!, title: String, selector: Selector) {
        self.type = type;
        self.title = title;
        self.selector = selector;
    }
}

protocol FTCreateNotebookOptionsViewControllerDelegate: AnyObject {
    func createNotebookOptionsViewController(_ createNotebookOptionsViewController: FTCreateNotebookOptionsViewController, didUpdateOption option: FTNewNotebookOptionType);
}

class FTCreateNotebookOptionsViewController: UIViewController,UIPopoverPresentationControllerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableViewSettings: UITableView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var toolbarLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentTrailingConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var bottomMarginConstraint : NSLayoutConstraint!;

    //Arguments
    weak var delegate: FTCreateNotebookOptionsViewControllerDelegate?
    var settings: [[FTNewNoteBookSetting]]!
    weak var shelfItemCollection : FTShelfItemCollection?;

    fileprivate var currentSettingIndexPath = IndexPath.init(row: 0, section: 0)
    
    var pinForNewMode : FTDocumentPin?
    
    fileprivate var pinController : FTPasswordViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = NSLocalizedString("Notebook Options", comment: "Notebook Options")
        self.titleLabel.addCharacterSpacing(kernValue: 0.37)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleAutobackup), name: NSNotification.Name(rawValue: FTUpdateBackupStatusNotification), object: nil)
        self.tableViewSettings.alwaysBounceVertical = false
        self.tableViewSettings.tableHeaderView = UIView.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 1, height: 1)))
        self.tableViewSettings.register(UINib(nibName: "FTNewNotebookSettingTableViewCell", bundle: nil), forCellReuseIdentifier: "CellPDFSetting")
        self.tableViewSettings.tableFooterView = UIView(frame: .zero)
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    //MARK:- Segue
    @IBAction func prepareForUnwind(_ segue: UIStoryboardSegue) {
        //For dismissing .viewControllers using custom segue so that .view don't overlap because of transparent background
    }
    
    //MARK:- UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.settings.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings[section].count;
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
#if !targetEnvironment(macCatalyst)
            return 32
#else
            return 16
#endif
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = self.settings[indexPath.section][indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellPDFSetting", for: indexPath) as? FTNewNotebookSettingTableViewCell else {
            fatalError("Programmer error - Couldnot find FTNewNotebookSettingTableViewCell")
        }
        cell.titleLabel?.text = setting.title
        cell.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        cell.switchToToggle?.isOn = setting.type.isEnabled
        cell.actionButton?.tag = indexPath.row
        cell.actionButton?.setTitle(String.init(format: "%ld", indexPath.section), for: UIControl.State.reserved)
        cell.enable(self.shelfItemCollection!.collectionType != .migrated || !setting.type.canDisable)
        if cell.switchToToggle != nil {
            cell.switchToToggle?.layer.borderWidth = cell.switchToToggle!.isOn ? 0.0:1.0
        }
        return cell
    }
    
    //MARK:- UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    //MARK:- Custom
    @IBAction func cancelClicked() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func settingClicked(_ sender: UIButton) {
        self.currentSettingIndexPath = IndexPath.init(row: sender.tag, section: Int(sender.title(for: .reserved)!)!)
        let setting = self.settings[self.currentSettingIndexPath.section][self.currentSettingIndexPath.row]
        self.perform(setting.selector)
    }
    
    private func showAutoBackUpONAlert() {
        let alertVc = UIAlertController(title: "", message: NSLocalizedString("AutoBackupONMessage", comment: "This will enable Auto-Backup for all your notebooks. Would you like to proceed?"), preferredStyle: .alert)
         alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: "Confirm"), style: .default, handler: { _ in
            self.showCloudLoginPage()
        }))
         self.present(alertVc, animated: false, completion: nil)
    }
    
    @objc func togglePasscodeLock()
    {
        //New notebook mode
        if ((self.pinForNewMode?.pin) != nil) {
            self.pinForNewMode!.pin = nil
            let setting = self.settings[self.currentSettingIndexPath.section][self.currentSettingIndexPath.row]
            setting.type.updateEnable(false)
            self.delegate?.createNotebookOptionsViewController(self, didUpdateOption: setting.type)
            self.tableViewSettings.reloadData()
            return
        }
        let storyboard = UIStoryboard(name: "FTPasswordSettings", bundle: Bundle.main)
        if let controller = storyboard.instantiateViewController(withIdentifier: "FTPasswordViewController") as? FTPasswordViewController {
            self.pinController = controller
            self.pinController?.delegate = self
            self.pinController?.passwordCreation = .newNotebook
            let navController = UINavigationController(rootViewController: controller)
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    @objc func toggleAutobackup()
    {
        let setting = self.settings[self.currentSettingIndexPath.section][self.currentSettingIndexPath.row]
        if(setting.type.isEnabled == false) {
            if(FTCloudBackUpManager.shared.currentBackUpCloudType() == FTCloudBackUpType.none) {
                self.showAutoBackUpONAlert()
                return
            }
        }
        if let isLoggedIn = FTCloudBackUpManager.shared.activeCloudBackUpManager?.isLoggedIn(), !isLoggedIn
        {
            FTCloudBackUpManager.shared.activeCloudBackUpManager?.login(with: self, completionHandler: { (success : Bool) in
                if(success)
                {
                    self.toggleAutobackup()
                }
            })
            return
        }
        setting.type.updateEnable(!setting.type.isEnabled)
        self.delegate?.createNotebookOptionsViewController(self, didUpdateOption: setting.type)
        self.tableViewSettings.reloadData()
    }
    
    @objc func toggleEvernote() {
        let evernotePublishManager = FTENPublishManager.shared
        evernotePublishManager.checkENSyncPrerequisite(from: self) { (success) in
            if success {
                let setting = self.settings[self.currentSettingIndexPath.section][self.currentSettingIndexPath.row]
                setting.type.updateEnable(!setting.type.isEnabled)
                self.delegate?.createNotebookOptionsViewController(self, didUpdateOption: setting.type)
                
                if setting.type.isEnabled == true {
                    FTENPublishManager.shared.showAccountChooser(self, withCompletionHandler: { (evernoteAccountType) in
                        if evernoteAccountType != EvernoteAccountType.evernoteAccountUnknown {
                            setting.type.updateEnable(true)
                            setting.type.updateBusiness((evernoteAccountType == EvernoteAccountType.evernoteAccountBusiness))
                        }
                        else {
                            setting.type.updateEnable(false)
                        }
                        self.delegate?.createNotebookOptionsViewController(self, didUpdateOption: setting.type)
                        self.tableViewSettings.reloadData()
                    });
                }
                else {
                    self.tableViewSettings.reloadData()
                }
            }
        }
    }
 
    func getPinForNewMode() -> FTDocumentPin? {
        return self.pinForNewMode
    }
}

extension FTCreateNotebookOptionsViewController: FTPasswordCallbackProtocol {
    func cancelButtonAction() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    func didFinishVerification(onController controller: UIViewController, currentPassword: String = "") {
        self.pinForNewMode = FTDocumentPin(pin: self.pinController!.getRequiredFieldText(field: .setPassword), hint: self.pinController!.getRequiredFieldText(field: .setHint), isTouchIDEnabled: self.pinController?.isTouchIDEnabled ?? false)
        self.presentedViewController?.dismiss(animated: true){() -> Void in
            let setting = self.settings[self.currentSettingIndexPath.section][self.currentSettingIndexPath.row]
            setting.type.updateEnable(true)
            self.delegate?.createNotebookOptionsViewController(self, didUpdateOption: setting.type)
            self.tableViewSettings.reloadData()
        }
    }
}
