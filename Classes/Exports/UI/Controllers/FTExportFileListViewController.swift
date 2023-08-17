//
//  FTExportFileListViewController.swift
//  Noteshelf
//
//  Created by Simhachalam on 23/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTExportFileListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var tableView: UITableView!
    var selectedItemsToExport:[FTItemToExport]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 52;
        
        let offset: CGFloat = self.exportControllerSafeAreaInset.bottom;
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.preferredContentSize = CGSize(width: 320, height: 485+offset)
    }
    
    //MARK:- ModifyTitle
    //ChangeTitle
    func openTitleChangeFormAtIndex(_ fileIndex:Int) {
        let headerTitle = NSLocalizedString("Filename", comment: "Filename");
        let alertController = UIAlertController(title: headerTitle, message: "", preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil));
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { [weak alertController] (action) in
            if let weakAlertController = alertController {
                if let textFieldTitle = weakAlertController.textFields?[0], let title = textFieldTitle.text, title != "" {
                    self.selectedItemsToExport[fileIndex].filename = title;
                    self.tableView.reloadData();
                }
            }
        }));
        
        alertController.addTextField { [weak self] (textField) in
            textField.delegate = self;
            textField.setDefaultStyle(.defaultStyle);
            textField.setStyledPlaceHolder(headerTitle, style: .defaultStyle);
            textField.setStyledText(self?.selectedItemsToExport[fileIndex].filename ?? "");

            textField.autocapitalizationType = .words;
            textField.autocorrectionType = .no;
        };
        self.present(alertController, animated: true, completion: nil);
        FTCLSLog("Export : Title");
    }
    
    //MARK:- UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return FTUtils.validateFileName(fromTextField: textField, shouldChangeCharactersIn: range, replacementString: string);
    }

    
    //MARK:- UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedItemsToExport.count;
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeight = section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
        let sectionHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: sectionHeight))
        sectionHeaderView.backgroundColor = .clear
        return sectionHeaderView
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellRightDetail", for: indexPath) as! FTRightDetailTableViewCell;
        
        cell.labelTitle.kernValue = -0.32
        cell.labelTitle.styleText = selectedItemsToExport[indexPath.row].filename;
        cell.textviewSubDetailEditable?.text = selectedItemsToExport[indexPath.row].filename
        cell.textviewSubDetailEditable?.tag = indexPath.row
        cell.textviewSubDetailEditable?.isUserInteractionEnabled = false
        if self.traitCollection.isRegular {
            cell.textviewSubDetailEditable?.delegate = self
            cell.textviewSubDetailEditable?.isUserInteractionEnabled = true
        }
        cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
        return cell;
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(74, UITableView.automaticDimension);
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.traitCollection.isRegular {
            self.openTitleChangeFormAtIndex(indexPath.row)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
extension FTExportFileListViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        return FTUtils.validateFileName(fromTextView: textView, shouldChangeCharactersIn: range, replacementString: text);
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text?.isEmpty ?? false {
            textView.text = selectedItemsToExport[textView.tag].filename
        }
        else{
            selectedItemsToExport[textView.tag].filename = textView.text
        }
    }
    
}

