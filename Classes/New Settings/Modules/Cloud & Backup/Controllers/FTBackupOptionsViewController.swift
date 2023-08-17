//
//  FTBackupOptionsViewController.swift
//  Noteshelf
//
//  Created by Matra on 15/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//


import UIKit
import FTCommon

class FTBackupOptionsViewController: FTCloudBackUpViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView?
    
    var shouldDismissAfterLogin: Bool = false
    weak var backupNBKShelfItem : FTDocumentItemProtocol?
    var hideDoneButton: Bool = true
    var hideBackButton: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(UINib(nibName: FTSettingsCommonTableViewCell.className, bundle: nil), forCellReuseIdentifier: FTSettingsCommonTableViewCell.className)
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
        self.tableView?.separatorColor = UIColor.appColor(.black10)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: "BackUpTo".localized)
        
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
#if targetEnvironment(macCatalyst)
        return FTGlobalSettingsController.macCatalystTopInset;
#else
        return .leastNonzeroMagnitude;
#endif
    }
   
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 92 : .leastNonzeroMagnitude
   }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            guard let footerView = Bundle.main.loadNibNamed("FTBackUpOptionsFooterView", owner: nil, options: nil)?.first as? FTBackUpOptionsFooterView else {
                return nil
            }
            footerView.backUpOptionsVc = self
            let cloudBackUp =  self.getCloudBackupIfAny()
            if cloudBackUp == "" {
                footerView.isHidden = true
            } else {
                footerView.isHidden = false
                footerView.signoutBtn.setTitle("Sign Out from \(cloudBackUp)", for: .normal)
            }
            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FTSettingsCommonTableViewCell.className, for: indexPath) as? FTSettingsCommonTableViewCell else {
            fatalError("Programmer error - Couldnot find FTSettingsCommonTableViewCell")
        }
        var imageIcon = UIImage()
        var titleValue = ""
        var hasAccessory = false
        switch indexPath.row {
        case 0:
            imageIcon = FTAccount.googleDrive.image
            titleValue = FTAccount.googleDrive.rawValue
            hasAccessory = FTCloudBackUpManager.shared.currentBackUpCloudType() == FTCloudBackUpType.googleDrive
        case 1:
            imageIcon = FTAccount.dropBox.image
            titleValue = FTAccount.dropBox.rawValue
            hasAccessory = FTCloudBackUpManager.shared.currentBackUpCloudType() == FTCloudBackUpType.dropBox
        case 2:
            imageIcon = FTAccount.oneDrive.image
            titleValue = FTAccount.oneDrive.rawValue
            hasAccessory = FTCloudBackUpManager.shared.currentBackUpCloudType() == FTCloudBackUpType.oneDrive
        case 3:
            imageIcon = FTAccount.webdav.image
            titleValue = FTAccount.webdav.rawValue
            hasAccessory = FTCloudBackUpManager.shared.currentBackUpCloudType() == FTCloudBackUpType.webdav

        default:
            break
        }
        cell.populateCell(image: imageIcon, name: titleValue, showLinkView: false)
        cell.hideAccessoryIcon = true
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        cell.tintColor = UIColor.appColor(.black1)
        cell.accessoryType = hasAccessory ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var cloudBackupType = FTCloudBackUpType.none
        var account: FTAccount?
        var eventName: String = ""
        
        switch indexPath.row {
        case 0:
            cloudBackupType = FTCloudBackUpType.googleDrive
            account = FTAccount.googleDrive
            eventName = "Shelf_Settings_Cloud_Backup_Google"
        case 1:
            cloudBackupType = FTCloudBackUpType.dropBox
            account = FTAccount(rawValue: FTAccount.dropBox.rawValue)
            eventName = "Shelf_Settings_Cloud_Backup_Dropbox"
        case 2:
            cloudBackupType = FTCloudBackUpType.oneDrive
            account = FTAccount.oneDrive
            eventName = "Shelf_Settings_Cloud_Backup_OneDrive"
        case 3:
            cloudBackupType = FTCloudBackUpType.webdav
            account = FTAccount.webdav
            eventName = "Shelf_Settings_Cloud_Backup_WebDAV"
        default:
            break
        }
        
        if(account != nil) {
            let accountInfoRequest = FTAccountInfoRequest.accountInfoRequestForType(account!);
            let isLoggedIn = accountInfoRequest.isLoggedIn()
            
            if isLoggedIn {
                if cloudBackupType == FTCloudBackUpType.webdav {
                    FTWebdavManager.setStatusForWebdavServerPathSelectionScreenDismiss(self.shouldDismissAfterLogin)
                    self.performSegue(withIdentifier: "SegueSelectWebdavServerLocation", sender: self)
                }
                else{
                    FTCloudBackUpManager.shared.setCurrentBackUpCloud(cloudBackupType)
                    self.tableView?.reloadData()
                    self.turnOnBackupForShelfItem(self.backupNBKShelfItem)
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                accountInfoRequest.showLoginView(withViewController: self, completion: { success in
                    runInMainThread {
                        if success {
                            if cloudBackupType == FTCloudBackUpType.webdav {
                                FTWebdavManager.setStatusForWebdavServerPathSelectionScreenDismiss(self.shouldDismissAfterLogin)
                                self.performSegue(withIdentifier: "SegueSelectWebdavServerLocation", sender: self)
                            } else {
                                FTCloudBackUpManager.shared.setCurrentBackUpCloud(cloudBackupType)
                                self.tableView?.reloadData()
                                if self.shouldDismissAfterLogin {
                                    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: FTUpdateBackupStatusNotification), object: self, userInfo: nil)
                                    self.navigationController?.dismiss(animated: true, completion: nil)
                                } else {
                                    self.turnOnBackupForShelfItem(self.backupNBKShelfItem)
                                }
                                self.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            FTLogError("UI:Cloud auth failed");
                            UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("UnableToauthenticate", comment: "Unable to authenticate"), from: self, withCompletionHandler: nil);
                        }
                    }
                });
            }
        } else {
            FTWebdavManager.removeWebdavBackupLocation()
            FTCloudBackUpManager.shared.setCurrentBackUpCloud(cloudBackupType)
        }
        
        if eventName != "" {
            track(eventName, params: [:], screenName: FTScreenNames.shelfSettings)
        }
        
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
#if targetEnvironment(macCatalyst)
        if (indexPath.row == 0) {
            return 0 //Mask google drive option for Mac catalyst
        }
#endif
        return 44.0
    }

    func turnOnBackupForShelfItem(_ item : FTDocumentItemProtocol?){
        self.backupNBKShelfItem = nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "SegueSelectWebdavServerLocation", let destinationVC = segue.destination as? FTSelectNotebookForBackupViewController {
            destinationVC.mode = .webdavBackUp
            destinationVC.backupNBKShelItem = self.backupNBKShelfItem
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
