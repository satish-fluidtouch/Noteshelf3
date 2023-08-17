//
//  FTExportSettingsViewController.swift
//  Noteshelf
//
//  Created by Siva on 6/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc enum FTShareSettingCellType: Int {
    case rightDetail
    case rightSwitch
    case rightTextField
}

class FTExportSettingsViewController: UIViewController, UITextFieldDelegate,FTSelectExportFormatDelegate, FTCustomPresentable {
    var customTransitioningDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: false)
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var buttonShareNow: UIButton?
    @IBOutlet weak var backbutton: UIButton?
    
    var targetShareButton:UIView?

    var exportManager : FTExportProgressManager?
    var exportTarget : FTExportTarget!
    var arraySettings = [FTExportOptions]();
    
    var properties: FTExportProperties!
    
    var canUpdateFolderName = true;
    weak var delegate : FTExportSettingsDelegate?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView?.reloadData();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.buttonShareNow?.setTitle(NSLocalizedString("ShareNow", comment: "Share Now"), for: .normal);

        self.tableView?.rowHeight = UITableView.automaticDimension;
        self.tableView?.estimatedRowHeight = 52;

        titleLabel?.text = NSLocalizedString("Share", comment: "Share")
        self.loadSettings();
        self.tableView?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.buttonShareNow?.accessibilityIdentifier = "ExportSettingShareNow";
    }

    static func requiredContentSize() -> CGSize {
        var contentSize: CGSize;
        let exportFormat = RKExportFormat(rawValue: UInt32(FTUserDefaults.exportFormat()))
        switch exportFormat {
        case kExportFormatNBK:
            contentSize = CGSize(width: 320, height: 300)
        case kExportFormatPDF:
            contentSize = CGSize(width: 320, height: 425)
        case kExportFormatImage:
            contentSize = CGSize(width: 320, height: 416)
        default:
            contentSize = CGSize(width: 320, height: 485)
        }
        return contentSize;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        let offset: CGFloat = self.exportControllerSafeAreaInset.bottom;
        var contentSize = FTExportSettingsViewController.requiredContentSize();
        contentSize.height += offset;
        self.preferredContentSize = contentSize;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.backbutton?.isHidden = self.isRootViewController;
    }
    
    @IBAction func shareNowButtonClicked(_ sender:UIButton){
        self.dismiss(animated: true) {
            self.delegate?.didShareWith(exportTarget: self.exportTarget, and: self.targetShareButton)
            track("Share_Now", params: [:],screenName: FTScreenNames.share)
        }
    }
    
    //MARK:- Custom
    
    func loadSettings() {
        self.arraySettings.removeAll();
        self.arraySettings.append(FTExportOptions.exportFormat)
        self.arraySettings.append(contentsOf: self.exportTarget.supportedOptions(forExportFormat: self.exportTarget.properties.exportFormat));
        
        self.tableView?.reloadData();
    }
    
    @IBAction func closeClicked() {
        self.navigationController?.popViewController(animated: true)
        FTCLSLog("Export : Close Button");
    }
    
    @IBAction func chooseExportFormat(_ sender: FTExportSettingsButton) {
        self.exportTarget.properties.exportFormat = RKExportFormat(rawValue: UInt32(sender.tag));
        self.updateFormatAndLoadSettings()
    }
    
    func updateFormatAndLoadSettings() {
        self.updateExportFormat(Int(self.exportTarget.properties.exportFormat.rawValue));
        
        self.loadSettings();
    }
    
    func updateExportFormat(_ formatIndex: Int) {
        FTUserDefaults.setExportFormat(formatIndex);
    }
    
    //MARK:- ModifyTitle
    //ChangeTitle
    func openTitleChangeForm() {
        let headerTitle = NSLocalizedString("Filename", comment: "Filename");
        let alertController = UIAlertController(title: headerTitle, message: "", preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil));
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { [weak alertController] (action) in
            if let weakAlertController = alertController {
                if let textFieldTitle = weakAlertController.textFields?[0], let title = textFieldTitle.text, title != "" {
                    self.exportTarget.itemsToExport[0].filename = title;
                    self.tableView?.reloadData();
                }
            }
        }));
        
        alertController.addTextField { [weak self] (textField) in
            textField.delegate = self;
            textField.setDefaultStyle(.defaultStyle);
            textField.setStyledPlaceHolder(headerTitle, style: .defaultStyle);
            textField.setStyledText(self?.exportTarget.itemsToExport[0].filename ?? "");

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
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? false {
            textField.text = exportTarget.itemsToExport.first?.filename
        }
        else{
            exportTarget.itemsToExport.first?.filename = textField.text
        }
    }
    func navigateToFormatSelection() {

        let storyBoard = UIStoryboard.init(name: "FTExport", bundle: nil)
        let formatSelectController:FTSelectExportFormatViewController = storyBoard.instantiateViewController(withIdentifier: "FTSelectExportFormatViewController") as! FTSelectExportFormatViewController
        formatSelectController.exportFormats = self.exportTarget.supportingExportFormats
        formatSelectController.currentFormat = self.exportTarget.properties.exportFormat
        formatSelectController.delegate = self
        self.navigationController?.pushViewController(formatSelectController, animated: true)
        FTCLSLog("Export : Format");
    }
    
    //MARK:- FTSelectExportFormatDelegate
    func exportFormatDidSelect(format newFormat: RKExportFormat) {
        self.exportTarget.properties.exportFormat = newFormat;
        self.updateFormatAndLoadSettings()
        var eventName = ""
        var format = "png";
        switch self.exportTarget.properties.exportFormat {
        case kExportFormatImage:
            format = "png";
            eventName = "ShareFormat_Png"
        case kExportFormatPDF:
            format = "pdf";
            eventName = "ShareFormat_Pdf"
        case kExportFormatNBK:
            format = "noteshelf";
            eventName = "ShareFormat_Noteshelf"
        default:
            break;
        }
        FTCLSLog("Export : Format Changed : \(format)");
        if eventName != "" {
            track(eventName, params: [:], screenName: FTScreenNames.share)
        }
    }

    //MARK:- ModifyExportAsSingleNote
    @objc func toggleExportAsSingleNote(_ switchExportAsSingleNote: UISwitch) {
        let status = switchExportAsSingleNote.isOn;
        switchExportAsSingleNote.layer.borderWidth = status ? 0.0:1.0
        let userDefaults = UserDefaults.standard;
        userDefaults.set(status, forKey: EVERNOTE_EXPORT_AS_SINGLE_NOTE)
        userDefaults.synchronize();
        let value = status ? "Yes" : "No";
        FTCLSLog("Export : As SingleNote : \(value)");
    }
    
    //MARK:- ModifyTransparentBackground
    @objc func toggleTransparentBackground(_ switchTransparentBackground: UISwitch) {
        let status = switchTransparentBackground.isOn;
        switchTransparentBackground.layer.borderWidth = status ? 0.0:1.0

        self.exportTarget.properties.hidePageTemplate = !status;
        FTUserDefaults.hidePageTemplate = !status;
        let value = status ? "No" : "Yes";
        FTCLSLog("Export : Show Page Background : \(value)");
        track("Share_HideTemplate", params: ["toogle":value],screenName: FTScreenNames.share)
    }

    @objc func toggleExportPageFooter(_ switchbutton : UISwitch) {
        let status = switchbutton.isOn;
        switchbutton.layer.borderWidth = status ? 0.0:1.0

        self.exportTarget.properties.includesPageFooter = status
        FTUserDefaults.exportPageFooter = status
        let value = status ? "Yes" : "No";
        FTCLSLog("Export : Page Footer : \(value)");
        track("Share_IncludeTitle&Page", params: ["toogle":value],screenName: FTScreenNames.share)
    }

}

extension FTExportSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    //MARK:- UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeight = section == 0 ? CGFloat.leastNonzeroMagnitude : 16.0
        let sectionHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: sectionHeight))
        sectionHeaderView.backgroundColor = .clear
        return sectionHeaderView
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arraySettings.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = self.arraySettings[indexPath.row];
        
        if setting.cellType == .rightSwitch {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellRightSwitch", for: indexPath) as! FTRightSwitchTableViewCell;
            
            cell.labelTitle.kernValue = -0.32
            cell.labelTitle.styleText = setting.title ;
            if setting == .pageTemplate {
                cell.switchToToggle.isOn = FTUserDefaults.showPageTemplate;
                cell.switchToToggle.removeTarget(nil, action: nil, for: .allTouchEvents);
                cell.switchToToggle.addTarget(self, action: #selector(self.toggleTransparentBackground(_:)), for: .valueChanged);
            } else if setting == .pageFooter {
                cell.switchToToggle.isOn = FTUserDefaults.exportPageFooter
                cell.switchToToggle.removeTarget(nil, action: nil, for: .allTouchEvents);
                cell.switchToToggle.addTarget(self, action: #selector(self.toggleExportPageFooter(_:)), for: .valueChanged);
            }

            cell.switchToToggle.layer.borderWidth = cell.switchToToggle.isOn ? 0.0:1.0
            cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
            return cell;
        }
        else if setting.cellType == .rightTextField {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellRightTextField", for: indexPath) as! FTRightTextFieldTableViewCell;
            cell.labelTitle.kernValue = -0.32
            cell.labelTitle.styleText = setting.title
            cell.fileNameTextfield?.isUserInteractionEnabled = false
            cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
            if(self.exportTarget.itemsToExport.count == 1) {
                if self.traitCollection.isRegular {
                    cell.fileNameTextfield?.isUserInteractionEnabled = true
                    cell.fileNameTextfield?.delegate = self
                }
                cell.fileNameTextfield?.attributedText = NSAttributedString(string: self.exportTarget.itemsToExport.first?.filename ?? "", attributes: [NSAttributedString.Key.kern: -0.32, NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17), NSAttributedString.Key.foregroundColor: UIColor.appColor(.black50)])
            }
            else
            {
                cell.fileNameTextFieldWidthConstarint?.constant = 0
                cell.labelTitle.text = NSLocalizedString("Filenames", comment: "Filenames")
                cell.labelTitle.addCharacterSpacing(kernValue: -0.32)
                cell.fileNameTextfield?.text =  "";
                let accessoryImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 13, height: 16))
                accessoryImageView.image = UIImage(named: "iconChevron")
                cell.accessoryView = accessoryImageView
            }
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellRightDetail", for: indexPath) as! FTRightDetailTableViewCell;
            
            cell.labelTitle.kernValue = -0.32
            cell.labelTitle.styleText = setting.title ;
            if setting == .exportFormat {
                cell.hideAccessoryView(false)
                cell.labelSubTitle?.font = UIFont.regularFont(with: 17)
            }
            cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
            return cell;
        }
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52.0;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = self.arraySettings[indexPath.row];
        if setting == .fileName {
            if(self.exportTarget.itemsToExport.count == 1) && !self.traitCollection.isRegular {
                self.openTitleChangeForm();
            }
            else if (self.exportTarget.itemsToExport.count > 1)
            {
                let storyBoard = UIStoryboard.init(name: "FTExport", bundle: nil)
                let exportFilesListController = storyBoard.instantiateViewController(withIdentifier: "FTExportFileListViewController") as! FTExportFileListViewController
                exportFilesListController.selectedItemsToExport = self.exportTarget.itemsToExport
                self.navigationController?.pushViewController(exportFilesListController, animated: true)
            }
        }
        else if setting == .exportFormat {
            self.navigateToFormatSelection();
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60.0
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 16, y: 0, width: self.view.frame.width-32, height: 60))
        let shareNowButton = UIButton(frame: CGRect(x: 0, y: 16, width: footerView.frame.width, height: 44))
        shareNowButton.backgroundColor = UIColor.appColor(.accent)
        shareNowButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        shareNowButton.setTitleColor(UIColor.white, for: UIControl.State.selected)
        shareNowButton.setTitle(NSLocalizedString("ShareNow", comment: "Share Now"), for: UIControl.State.normal)
        shareNowButton.setTitle(NSLocalizedString("ShareNow", comment: "Share Now"), for: UIControl.State.selected)
        shareNowButton.titleLabel?.font = UIFont.regularFont(with: 16)
        shareNowButton.layer.cornerRadius = 10.0
        shareNowButton.addTarget(self, action: #selector(shareNowButtonClicked(_:)), for: UIControl.Event.touchUpInside)
        footerView.addSubview(shareNowButton)
        
        return footerView
    }
}
