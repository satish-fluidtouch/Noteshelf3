//
//  FTSelectNotebookForBackupViewController.swift
//  Noteshelf
//
//  Created by Matra on 21/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSelectNotebookForBackupViewController: UIViewController, FTSelectNotebookForBackupDelegate {

    @IBOutlet weak var containerView: UIView?
    var shelfViewController: FTShelfItemsViewController?
    var webdavFilesViewController : FTWebdavFileHierarchyViewController?
    var viewController : UIViewController?
    var mode = FTShelfItemsViewMode.dropboxBackUp
    weak var backupNBKShelItem : FTDocumentItemProtocol?
    var screenTitle = NSLocalizedString("Notebooks", comment: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mode == .webdavBackUp{
            screenTitle = NSLocalizedString("SelectBackupLocation", comment: "Select Backup Location")
        }
        if let controller = self.viewController as? FTShelfItemsViewController {
            if let title = controller.group?.displayTitle {
                let loctitle = NSLocalizedString(title, comment: "")
                screenTitle = loctitle
            } else if let title = controller.collection?.displayTitle {
                let loctitle = NSLocalizedString(title, comment: "")
                screenTitle = loctitle
            }
            addController(controller)
        } else if let controller = self.viewController as? FTWebdavFileHierarchyViewController{
            if !controller.webdavRelativepath.isEmpty{
                
                let locatitle = self.getDisplayNameForWebdavFile(withHref: controller.webdavRelativepath)
                if !locatitle.isEmpty {
                    screenTitle = locatitle
                }
                else{
                    screenTitle = NSLocalizedString("SelectBackupLocation", comment: "Select Backup Location")
                }
            }
            else{
                screenTitle = NSLocalizedString("SelectBackupLocation", comment: "Select Backup Location")
            }
            addController(controller)
        }
        else {
            let storyboard = UIStoryboard(name: "FTShelfItems", bundle: nil)
            if self.mode == .webdavBackUp{
                if let webdavFilesViewController = storyboard.instantiateViewController(withIdentifier: FTWebdavFileHierarchyViewController.className) as? FTWebdavFileHierarchyViewController{
                    webdavFilesViewController.selectNotebookDelegate = self
                    webdavFilesViewController.backupNBKShelItem = self.backupNBKShelItem
                    webdavFilesViewController.mode = self.mode
                    addController(webdavFilesViewController)
                }
            }else{
                if let shelfItemsViewController = storyboard.instantiateViewController(withIdentifier: FTShelfItemsViewController.className) as? FTShelfItemsViewController {
                    shelfItemsViewController.selectNotebookDelegate = self
                    shelfItemsViewController.mode = self.mode
                    addController(shelfItemsViewController)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNewNavigationBar(hideDoneButton: false,title: screenTitle)
        self.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
    }
    
    private func addController(_ controller: UIViewController) {
        if let container = self.containerView {
            self.containerView?.addSubview(controller.view)
            controller.view.frame = container.bounds
            self.addChild(controller)
        }
    }
    
    internal func pushToNextLevel(controller: UIViewController) {
        let storyboard = UIStoryboard(name: "FTSettings_Accounts", bundle: nil)
        if let selectNoteBookController = storyboard.instantiateViewController(withIdentifier: FTSelectNotebookForBackupViewController.className) as? FTSelectNotebookForBackupViewController {
            selectNoteBookController.viewController = controller
            selectNoteBookController.mode = self.mode
            self.navigationController?.pushViewController(selectNoteBookController, animated: true)
        }
    }
    
    private func getDisplayNameForWebdavFile(withHref path:String) -> String{
        let strings = path.split(separator: "/");
        var finalStrings = [String]()
        
        for item in strings {
            finalStrings.append(item.description)
        }
        return finalStrings.last ?? ""
    }
}
