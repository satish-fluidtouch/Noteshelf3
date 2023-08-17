//
//  FTWebdavFileHierarchyViewController.swift
//  Noteshelf
//
//  Created by Ramakrishna on 10/03/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTWebdavFileHierarchyViewController: UIViewController , UITableViewDelegate,UITableViewDataSource{
    private var webdavFileItems : [FTWebdavFileProperties] = []
    var webdavRelativepath : String = ""
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var webdavServerPathPickButton: UIButton!
    weak var selectNotebookDelegate: FTSelectNotebookForBackupDelegate?
    weak var backupNBKShelItem : FTDocumentItemProtocol?
    var mode = FTShelfItemsViewMode.webdavBackUp
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.setupUI()
        self.fetchWebdavServerFolderStructureWith(relativePath: self.webdavRelativepath)
    }
    func setupUI(){
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 200;
        self.webdavServerPathPickButton.isHidden  = false
        self.view.bringSubviewToFront(self.webdavServerPathPickButton)
        let folderName = FTWebdavManager.getDisplayNameForWebdavFile(withHref: self.webdavRelativepath)
        if !folderName.isEmpty{
            self.webdavServerPathPickButton.setTitle(String(format: NSLocalizedString("BackupTo", comment: "Backup to location"),folderName), for: UIControl.State.normal)
        }else{
            self.webdavServerPathPickButton.setTitle(NSLocalizedString("BackupToWebDAV", comment: "Backup to WebDAV"), for: UIControl.State.normal)
        }
        self.webdavServerPathPickButton.layer.cornerRadius = 5
    }
    //MARK:- DataFetch
    private func fetchWebdavServerFolderStructureWith(relativePath path:String){
        var loadingIndicatorViewController : FTLoadingIndicatorViewController?
        runInMainThread {
            loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: "");
        }
        
        FTWebdavManager.shared.getFileHierarchyAt(relativePath: path) { [weak self] (fileItems) in
            loadingIndicatorViewController?.hide()
            guard let strongSelf = self else {return};
            if !fileItems.isEmpty {
                strongSelf.webdavFileItems = fileItems
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData();
                }
            }
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return webdavFileItems.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard  let cell = tableView.dequeueReusableCell(withIdentifier: "CellShelfItem") as? FTShelfItemTableViewCell else{
            return UITableViewCell()
        }
        cell.labelSubTitle.textColor = UIColor.appColor(.black50);
        cell.labelTitle.textColor = UIColor.label;

        cell.cellAccessoryType = .none;
        cell.accessoryView = nil;
        cell.imageViewIcon.image = nil;
        cell.imageViewIcon2.image = nil;
        cell.imageViewIcon3.image = nil;

        cell.shadowImageView.isHidden = true;
        cell.shadowImageView2.isHidden = true;
        cell.shadowImageView3.isHidden = true;
        cell.passcodeLockStatusView.isHidden = true;
        #if !targetEnvironment(macCatalyst)
        cell.imageViewIcon.contentMode = .left;
        cell.imageViewIcon.tintColor = UIColor.init(hexString: "#383838")
        cell.imageIconLeadingConstraint?.constant = 14
        let icon = self.webdavFileItems[indexPath.row].isCollection ? UIImage(named:"category_single") :(self.webdavFileItems[indexPath.row].displayName.contains(".noteshelf") ? UIImage(named: "covergray") : UIImage(named:"category_single"))
        cell.imageViewIcon.image = icon;
        #else
        cell.imageViewIcon.contentMode = .center;
        cell.imageViewIcon.image = UIImage(named: "popoverCategory");
        #endif
        cell.labelSubTitle.isHidden = true;
        cell.cellAccessoryType = self.webdavFileItems[indexPath.row].isCollection ? UITableViewCell.AccessoryType.disclosureIndicator : UITableViewCell.AccessoryType.none
//        cell.labelTitle.style = 24
//        cell.labelSubTitle.style = 5
        let displayTitle = self.webdavFileItems[indexPath.row].displayName
        cell.labelTitle.text = displayTitle;
        cell.contentView.isAccessibilityElement = true;
        cell.contentView.accessibilityTraits = UIAccessibilityTraits.none;
        if !cell.labelSubTitle.isHidden , let subTitle = cell.labelSubTitle.text , subTitle.count > 0 {
            cell.contentView.accessibilityLabel = displayTitle.appending(subTitle);
        }
        else {
            cell.contentView.accessibilityLabel = displayTitle;
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001;
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil;
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        self.webdavRelativepath = self.webdavFileItems[indexPath.row].href
        if self.webdavFileItems[indexPath.row].isCollection {
            pushToNextLevel()
        }else{
            return
        }
    }
    func pushToNextLevel() {
        let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
        if let webdavFileHierarchyVC = storyboard.instantiateViewController(withIdentifier: FTWebdavFileHierarchyViewController.className) as? FTWebdavFileHierarchyViewController {
            webdavFileHierarchyVC.webdavRelativepath = self.webdavRelativepath
            webdavFileHierarchyVC.selectNotebookDelegate = self.selectNotebookDelegate
            self.selectNotebookDelegate?.pushToNextLevel(controller: webdavFileHierarchyVC)
        }
    }
    @IBAction func setWebdavServerPath(_ sender: UIButton) {
        FTCloudBackupPublisher.recordSyncLog("Webdav server backup location set :\(self.webdavRelativepath)")
        FTWebdavManager.setWebdavBackupLocation(withPath: self.webdavRelativepath)
        FTCloudBackUpManager.shared.setUpCloudBackup(FTCloudBackUpType.webdav)
        let shouldDismissWebdavServerPathSelectionScreen = FTWebdavManager.shouldShowWebdavServerPathSelectionScreenAndDismiss()
        if shouldDismissWebdavServerPathSelectionScreen{
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: FTUpdateBackupStatusNotification), object: self, userInfo: nil)
            self.navigationController?.dismiss(animated: true, completion: nil)
        }else{
            self.turnOnBackupForShelfItem(self.backupNBKShelItem)
            if let viewControllers = self.navigationController?.viewControllers{
                #if !targetEnvironment(macCatalyst)
                let accountsControllerClassName = FTAccountsViewController.className
                #else
                let accountsControllerClassName = FTAccountsViewController.className()
                #endif
                for controller in viewControllers where controller.className == accountsControllerClassName {
                    self.navigationController?.popToViewController(controller, animated:false)
                }
            }
        }
    }
    private func turnOnBackupForShelfItem(_ item : FTDocumentItemProtocol?){
        self.backupNBKShelItem = nil
    }
}
