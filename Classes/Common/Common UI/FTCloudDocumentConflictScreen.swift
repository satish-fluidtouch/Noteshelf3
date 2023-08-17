//
//  FTCloudDocumentConflictScreen.swift
//  Noteshelf
//
//  Created by Amar on 10/11/16.
//
//

import Foundation
import FTCommon

class FTCloudDocumentConflictScreen : UIViewController,UITableViewDataSource,UITableViewDelegate
{
    @IBOutlet weak var keepVersionsButton: UIButton?;
    @IBOutlet weak var cancelButton: UIButton?;
    @IBOutlet weak var tableView: UITableView?;
    @IBOutlet weak var conflictTitleLabel: FTStyledLabel?;
    @IBOutlet weak var conflictMessageLabel: FTStyledLabel?;
   
    @IBOutlet weak var topbarHeightConstraint: NSLayoutConstraint?;
    
    fileprivate var selectedIndexPaths = NSMutableSet();
    
    fileprivate weak var conflictDocument : FTDocumentProtocol?;
    fileprivate weak var documentItem : FTDocumentItemProtocol?;

    fileprivate var conflictVersions = NSArray();

    @objc class func conflictViewControllerForDocument(_ document : FTDocumentProtocol,
                                                 documentItem item : AnyObject) -> FTCloudDocumentConflictScreen
    {
     
        let conflictVC = FTCloudDocumentConflictScreen.init(nibName: "FTCloudDocumentConflictScreen", bundle: nil);
       
        conflictVC.conflictDocument = document;
        conflictVC.documentItem = item as? FTDocumentItemProtocol;
        
        conflictVC.modalPresentationStyle = UIModalPresentationStyle.formSheet;
        return conflictVC;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.updateConflictingVersions();
        self.cancelButton?.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal);
        self.conflictTitleLabel?.styleText = NSLocalizedString("ResolveConflict", comment: "ResolveConflict");
        self.conflictMessageLabel?.styleText = NSLocalizedString("ResolveConflictMessage", comment: "ResolveConflictMessage");
        self.tableView?.isEditing = true;
        #if targetEnvironment(macCatalyst)
            self.tableView?.allowsSelectionDuringEditing = true
        #endif
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        setScreenName("CloudConflict", screenClass: String(describing: type(of: self)));
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.view.isRegularClass() {
            self.topbarHeightConstraint?.constant = 44
        }
        else{
            let safeAreaInsets = self.view.safeAreaInsets
            self.topbarHeightConstraint?.constant = (safeAreaInsets.top + 44)
        }
    }
    //MARK: IBAction methods
    @IBAction func keepVersions(_ sender : AnyObject)
    {
        self.keepVersionsButton!.isEnabled = false;
        var versionsToKeep = [NSFileVersion]();
        let selectedIndex = self.tableView?.indexPathsForSelectedRows;
        if(nil != selectedIndex && selectedIndex!.count > 0)
        {
            for eachIndexPath in selectedIndex!
            {
                versionsToKeep.append(self.conflictVersions.object(at: eachIndexPath.row) as! NSFileVersion);
            }
            self.resolveConfilctsFor(versionsToKeep);
        }
        else {
            self.dismiss(animated: true, completion: nil);
        }
    }
    
    @IBAction func cancel(_ sender : AnyObject)
    {
        self.dismiss(animated: true, completion: nil);
    }

    @objc func updateConflictingVersions()
    {
        // Do any additional setup after loading the view from its nib.
        self.conflictVersions = self.conflictingVersions() as NSArray;
        self.updateKeepVersionsLabel();
        self.tableView?.reloadData();
    }

    //MARK: private methods
    fileprivate func updateKeepVersionsLabel()
    {
        var Buttontitle = NSLocalizedString("Done", comment: "Done")
        if (self.isRegularClass())
        {
            let indexPths = self.tableView!.indexPathsForSelectedRows;
            if(indexPths != nil)
            {
                Buttontitle = (self.tableView!.indexPathsForSelectedRows!.count > 1) ? NSLocalizedString("KeepVersions", comment: "KeepVersions") : NSLocalizedString("KeepVersion", comment: "KeepVersion");
            }
            else
            {
                Buttontitle = NSLocalizedString("KeepVersion", comment: "KeepVersion");
            }
        }
        self.keepVersionsButton?.setTitle(Buttontitle, for: .normal);
        let selectedIndices = self.tableView!.indexPathsForSelectedRows;
        if(nil != selectedIndices && selectedIndices!.count > 0) {
            self.keepVersionsButton?.isEnabled = true;
        }
        else {
            self.keepVersionsButton?.isEnabled = false;
        }
    }
    
    //MARK: UITableviewDatasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conflictVersions.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let fileVersion = self.conflictVersions.object(at: indexPath.row) as! NSFileVersion;
        var cell = tableView.dequeueReusableCell(withIdentifier: "ConflictCell2");
        if(nil == cell)
        {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "ConflictCell2");
            cell?.textLabel?.numberOfLines = 2;
            cell?.textLabel?.adjustsFontSizeToFitWidth = true;
            cell?.textLabel?.minimumScaleFactor = 16/12;
            cell?.textLabel?.textColor = UIColor.init(hexString: "3c3c3c");
            cell?.detailTextLabel?.textColor = UIColor.init(hexString: "a6a5a1");
        }
        
        let format = NSLocalizedString("ConflictDocModifiedOn", comment: "ConflictDocModifiedOn");
        cell?.setStyledText(String.init(format: format, fileVersion.localizedNameOfSavingComputer ?? "<unknown>"), style: .defaultStyle);

        let dateFormatter = DateFormatter();
        dateFormatter.doesRelativeDateFormatting = true;
        dateFormatter.timeStyle = DateFormatter.Style.medium;
        dateFormatter.dateStyle = DateFormatter.Style.medium;

        cell?.setStyledDetailText(dateFormatter.string(from: fileVersion.modificationDate!), style: .defaultStyle);

        return cell!;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100;
    }
    
    //MARK: UITableViewDelegate methods
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.init(rawValue: 3)!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.updateKeepVersionsLabel();
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.updateKeepVersionsLabel();
    }
    
    fileprivate func conflictingVersions() -> [NSFileVersion]! {
        var conflictVersions = [NSFileVersion]();
        let currentVersion = NSFileVersion.currentVersionOfItem(at: self.conflictDocument!.URL as URL);
        let otherVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.conflictDocument!.URL as URL);
        conflictVersions.append(currentVersion!);
        if(otherVersions != nil) {
            conflictVersions.append(contentsOf: otherVersions!);
        }
        return conflictVersions;
    }
    
    fileprivate func resolveConfilctsFor(_ conflictVersions : [NSFileVersion])
    {
        var versionToKeep = conflictVersions;
        
        guard let document = self.conflictDocument else { return  }

        let docURL = document.URL;
        
        let currentVersion = NSFileVersion.currentVersionOfItem(at: docURL as URL);

        var resolvedURLS = [URL]();
        
        let group = DispatchGroup();
        
        if(!versionToKeep.contains(currentVersion!)) {
            let versionToReplace = versionToKeep.first;
            versionToKeep.removeFirst();
            _ = try? versionToReplace!.replaceItem(at: docURL as URL, options: NSFileVersion.ReplacingOptions.byMoving);
        }

        // copy all remaining versions to a new file
        for eachVersion in versionToKeep {
            
            if(eachVersion != currentVersion!) {
                group.enter();
                let fileVersion = eachVersion;
                
                let tempURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
                do {
                    try fileVersion.replaceItem(at: tempURL, options: NSFileVersion.ReplacingOptions.byMoving);
                    FTDocumentFactory.prepareForImportingAtURL(tempURL, onCompletion: { (error, document) in
                        if(nil == error) {
                            resolvedURLS.append(document!.URL);
                        }
                        group.leave();
                    });
                }
                catch {
                    group.leave();
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            _ = try? NSFileVersion.removeOtherVersionsOfItem(at: docURL as URL);
            document.revert(toContentsOf: docURL, completionHandler: nil);
            // mark all (remaining) versions as resolved and remove them
            let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: docURL as URL);
            if(nil != conflictVersions) {
                for eachVersion in conflictVersions!
                {
                    eachVersion.isResolved = true;
                }
            }
            
            let documentName = self.documentItem!.displayTitle;
            let group = self.documentItem!.parent;
            let collection = self.documentItem!.shelfCollection;
            for eachURL in resolvedURLS {
                collection?.addShelfItemForDocument(eachURL, toTitle: documentName, toGroup: group, onCompletion: { (error, item) in
                    
                });
            }
            self.dismiss(animated: true, completion: nil);
        };
    }
}
