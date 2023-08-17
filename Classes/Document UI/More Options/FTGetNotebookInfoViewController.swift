//
//  FTGetNotebookInfoViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTGetNotebookInfoViewController: UIViewController, FTNotebookTitleDelegate {

    @IBOutlet weak var tblSettings: UITableView!
    weak var notebookShelfItem: FTShelfItemProtocol!
    weak var notebookDocument: FTDocumentProtocol!
    weak var page: FTPageProtocol!
    weak var getInfoDel: FTGetInfoDelegate?
    var sectionsList = [FTNotebookInfoSection]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: 464)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        let pageCreationDate = Date(timeIntervalSinceReferenceDate: page.creationDate.doubleValue)
        let pageUpdationDate = Date(timeIntervalSinceReferenceDate: page.lastUpdated.doubleValue)
        let bookCreatedDateString = notebookShelfItem.fileCreationDate.shelfShortStyleFormat()
        let bookUpdateDateString = notebookShelfItem.fileModificationDate.shelfShortStyleFormat()
        let pageCreatedDateString = pageCreationDate.shelfShortStyleFormat()
        let pageUpdateDateString = pageUpdationDate.shelfShortStyleFormat()
        let pageDimensionsString = "\(Int(page.pageReferenceViewSize().width))" + " x " + "\(Int(page.pageReferenceViewSize().height))" + " px"
        let pageNumberString = String(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), page.pageIndex() + 1, notebookDocument.pages().count)
        let goToPageString = "\(1) - \(notebookDocument.pages().count)"
        //***************************
        var firstSection = FTNotebookInfoSection()
        var properties = [FTNotebookInfoProperty]()
        properties.append(FTNotebookInfoTitle(description: notebookShelfItem.title))

        let relativePath = notebookDocument.URL.path;
        var notebookTitle = relativePath.collectionName()?.deletingPathExtension ?? "--";
        if let groupName = relativePath.relativeGroupPathFromCollection()?.lastPathComponent.deletingPathExtension {
            notebookTitle = "\(notebookTitle) / \(groupName)"
        }
//        properties.append(FTNotebookInfoCategory(description: notebookTitle))
        firstSection.properties = properties
        self.sectionsList.append(firstSection)
        //***************************

        var secondSection = FTNotebookInfoSection()
        properties = [FTNotebookInfoProperty]()
        properties.append(FTNotebookInfoCategory(description: notebookTitle))
        properties.append(FTNotebookInfoPageNumber(description: pageNumberString))
#if !targetEnvironment(macCatalyst)
        properties.append(FTNotebookInfoGotoPage(description: goToPageString))
#endif
        properties.append(FTNotebookInfoUpdated(description: bookUpdateDateString))
        properties.append(FTNotebookInfoCreated(description: bookCreatedDateString))
        properties.append(FTNotebookInfoPageUpdated(description: pageUpdateDateString))
        properties.append(FTNotebookInfoPageCreated(description: pageCreatedDateString))
//        properties.append(FTNotebookInfoPageDimensions(description: pageDimensionsString))
        secondSection.properties = properties
        self.sectionsList.append(secondSection)
        
        self.tblSettings.rowHeight = UITableView.automaticDimension;
        self.tblSettings.estimatedRowHeight = 55;
        self.configureCustomNavigation(title: "GetInfo".localized)
    }
    
    private func setupUI(){
        self.tblSettings?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationController?.preferredContentSize = CGSize(width: defaultPopoverWidth, height: 464)
    }
    
    func renameShelfItem(title: String, onCompletion: @escaping (Bool) -> ()) {
        let shelfCollection = self.notebookShelfItem.shelfCollection
        runInMainThread {
            shelfCollection?.renameShelfItem(self.notebookShelfItem, toTitle: title, onCompletion: {[weak self] (error, updatedShelfItem) in
                if(nil != error) {
                    UIAlertController.showConfirmationDialog(with: error!.description, message: "", from: self, okHandler: {
                    });
                    onCompletion(false)
                }
                else {
                    //**************************
                    if let documentItem = updatedShelfItem as? FTDocumentItemProtocol, let docUUID = documentItem.documentUUID {
                        let autoBackupItem = FTAutoBackupItem.init(URL: documentItem.URL, documentUUID: docUUID);
                        FTCloudBackUpManager.shared.startPublish();
                        
                        if let shelfItem = updatedShelfItem,
                            FTENPublishManager.shared.isSyncEnabled(forDocumentUUID: docUUID) {
                            FTENPublishManager.recordSyncLog("User renamed notebook: \(String(describing: shelfItem.displayTitle))");
                            
                            let evernotePublishManager = FTENPublishManager.shared;
                            evernotePublishManager.updateSyncRecord(forShelfItem: shelfItem,
                                                                    withDocumentUUID: docUUID);
                            evernotePublishManager.startPublishing();
                        }
                        onCompletion(true)
                    }
                }
            })
        }
    }
    
    func handleGoToPage(pageNumber: Int) {
        self.getInfoDel?.handleGoToPage(with: pageNumber)
    }
    
    func numberOfPages() -> Int {
        return self.notebookDocument.pages().count
    }

}

extension FTGetNotebookInfoViewController : UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionsList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionsList[section].properties.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeight = section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
        let sectionHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: sectionHeight))
        sectionHeaderView.backgroundColor = .clear
        return sectionHeaderView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.5))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 48
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        let section = self.sectionsList[indexPath.section].properties[indexPath.row]
        if section is FTNotebookInfoGotoPage {
            cell = tableView.dequeueReusableCell(withIdentifier: "FTNotebookTitleCell", for: indexPath)
        } else if section is FTNotebookInfoTitle {
            cell = tableView.dequeueReusableCell(withIdentifier: "FTNoteBookTexfieldCell", for: indexPath)
        } else {
             cell = tableView.dequeueReusableCell(withIdentifier: "FTNotebookMetadataCell", for: indexPath)
        }
        
        if let metaDataCell = cell as? FTNotebookMetadataCell {
            metaDataCell.configure(info: self.sectionsList[indexPath.section].properties[indexPath.row])
        } else if let titleCell = cell as? FTNotebookTitleCell {
            titleCell.configure(info: self.sectionsList[indexPath.section].properties[indexPath.row])
            titleCell.delegate = self
        } else if let textFieldCell = cell as? FTNoteBookTexfieldCell {
            textFieldCell.configure(info: self.sectionsList[indexPath.section].properties[indexPath.row])
            textFieldCell.delegate = self
        }
        
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
