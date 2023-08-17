//
//  FTImportedDocViewController.swift
//  Noteshelf
//
//  Created by Matra on 19/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTImportedDocViewControllerDelegate : AnyObject
{
    func importedDocumentController(_ controller : FTImportedDocViewController,didSelectShareAction action:FTSharedAction);
}

class FTImportedDocViewController: UIViewController, FTCustomPresentable,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var lblNoImports:UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var clearButton: UIButton?

    weak var delegate : FTImportedDocViewControllerDelegate?;
    
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .presentation, supportsFullScreen: false)

    private var arImportedFiles = [FTSharedAction]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel?.text = NSLocalizedString("importedFiles", comment: "Imported Files");
        self.clearButton?.setTitle(NSLocalizedString("Clear", comment: "Import"), for: .normal);
        
        self.arImportedFiles = FTImportStorageManager.getInProgressDownloads()

        self.lblNoImports?.text = NSLocalizedString("NoImportsKey", comment: "No Imports Available!")
        self.tableView?.register(UINib.init(nibName: FTImportListTableViewCell.className, bundle: nil),
                                forCellReuseIdentifier: FTImportListTableViewCell.className)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTImportActionManager.handleDidUpdateImportStatus(_:)),
                                               name: NSNotification.Name.actionImportStatusDidUpdate,
                                               object: nil)
    }

    @IBAction func clearClicked(_ sender: Any) {
        self.arImportedFiles = FTImportStorageManager.clearStorageAndGetUserActiveActions()
        tableView?.reloadData()
    }
    
    @IBAction func closeClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.arImportedFiles.isEmpty {
            self.lblNoImports?.isHidden = false
        }else{
            self.lblNoImports?.isHidden = true
        }
        return self.arImportedFiles.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FTImportListTableViewCell.className, for: indexPath) as? FTImportListTableViewCell
        
        let actionModel = arImportedFiles[indexPath.row]
        cell?.configureCell(actionModel);
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionModel = arImportedFiles[indexPath.row];
        if actionModel.importStatus == .importSuccess, actionModel.documentUrlHash.count > 0 {
            self.delegate?.importedDocumentController(self, didSelectShareAction: actionModel);
        }
        tableView.deselectRow(at: indexPath, animated: true);
    }
    
    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete;
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let actionModel = arImportedFiles[indexPath.row]
            FTImportStorageManager.removeImportAction(actionModel);
            self.arImportedFiles.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
}

//MARK: Notification Handling
private extension FTImportedDocViewController
{
    @objc func handleDidUpdateImportStatus(_ notification:Notification){
        let arPreviousActions = FTImportStorageManager.getInProgressDownloads()
        if(!arPreviousActions.isEmpty) {
            self.arImportedFiles = arPreviousActions
        }
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
}
