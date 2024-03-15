//
//  FTNotebookMoreOptionsViewController.swift
//  Noteshelf
//
//  Created by Akshay on 08/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import IntentsUI
import UIKit
import FTCommon

enum FTNotebookBasicOption: String {
    case bookMark
    case saveAsTemplate
    case present
    case zoomBox
    case gestures
    case help
    case customizeToolBar
    case goToPage
}

protocol FTGetInfoDelegate: AnyObject {
    func handleGoToPage(with page: Int)
}

protocol FTNotebookMoreOptionsDelegate: AnyObject, FTShareBeginnerDelegate {
    func presentChangeTemplateScreen(settingsController: FTNotebookMoreOptionsViewController)
    func rotatePage(by angle: UInt)
    func handleGotoPage(_ pageNumber: Int, controller: UIViewController)
    func presentGestureUI(settingsController: FTNotebookMoreOptionsViewController)
    func switchToPresentMode(settingsController: FTNotebookMoreOptionsViewController)
    func switchToReadOnlyMode(settingsController: FTNotebookMoreOptionsViewController)
    func presentFinderScreen(settingsController: FTNotebookMoreOptionsViewController)
    func presentHelpScreen(settingsController: FTNotebookMoreOptionsViewController)
    func presentCustomizeToolbarScreen(settingsController: FTNotebookMoreOptionsViewController)
    func didTapBasicOption(option: FTNotebookBasicOption, with page: FTPageProtocol, controller: FTNotebookMoreOptionsViewController)
    func presentPasswordScreen(settingsController: FTNotebookMoreOptionsViewController)
    func getShareInfo(completion: @escaping (FTShareOptionsInfo) -> Void)
}

class FTNotebookMoreOptionsViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    @IBOutlet var tblSettings: UITableView?
    weak var notebookShelfItem: FTShelfItemProtocol!
    weak var notebookDocument: FTDocumentProtocol!
    weak var page: FTPageProtocol!
    weak var delegate: FTNotebookMoreOptionsDelegate?
    fileprivate var settings:[[FTNotebookMoreOption]] = [[FTNotebookMoreOption]]()
    var pinController: FTPasswordViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard notebookShelfItem != nil, page != nil, notebookDocument != nil else {
            fatalError("Settings must be presented with FTDocumentProtocol object")
        }
        self.normalDeskToolBarSettingsOptions()
        self.navigationItem.title = "more".localized
        self.tblSettings?.tableFooterView = UIView(frame: .zero)
        self.addTableHeaderview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tblSettings?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.tblSettings?.reloadData()
        self.navigationController?.navigationBar.isHidden = false
        self.preferredContentSize = self.fetchSize()
    }
    
    private func fetchSize() -> CGSize {
        var height: CGFloat = 652.0
#if targetEnvironment(macCatalyst)
        height -= 170.0
#endif
        return CGSize(width: defaultPopoverWidth, height: height)
    }
    
    private func normalDeskToolBarSettingsOptions() {
        let sectionsFetcher = FTMorePopoverSections()
        settings = sectionsFetcher.moreSections(page);
    }

    class func showAsPopover(fromSourceView sourceView: AnyObject,
                             overViewController viewController: UIViewController,
                             notebookShelfItem: FTShelfItemProtocol,
                             notebookDocument: FTDocumentProtocol,
                             page: FTPageProtocol,
                             delegate: FTNotebookMoreOptionsDelegate) {
        
        if let settingsNavController = UIStoryboard(name: "FTNotebookMoreOptions", bundle: nil).instantiateInitialViewController() as? UINavigationController, let settingsController = settingsNavController.viewControllers.first as? FTNotebookMoreOptionsViewController {
            
            settingsController.notebookShelfItem = notebookShelfItem
            settingsController.notebookDocument = notebookDocument
            settingsController.page = page
            settingsController.delegate = delegate
            let size = settingsController.fetchSize()
            settingsController.ftPresentationDelegate.source = sourceView
            viewController.ftPresentPopover(vcToPresent: settingsController, contentSize: size)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let rotationVC = segue.destination as? FTRotatePageViewController {
            rotationVC.rotationAngleChanged = { [weak self] angle in
                self?.delegate?.rotatePage(by: angle)
            }
        }   else if let getInfoVC = segue.destination as? FTGetNotebookInfoViewController {
            getInfoVC.notebookShelfItem = self.notebookShelfItem
            getInfoVC.notebookDocument = self.notebookDocument
            getInfoVC.page = self.page
            getInfoVC.getInfoDel = self
        }  else if let tagsVc = segue.destination as? FTTagsViewController, let tagPage = page as? FTPageTagsProtocol {
            let pageTags = FTTagsProvider.shared.getTagsfor(tagPage.tags(),shouldCreate: true);
            let tagItems = FTTagsProvider.shared.getTags()
            let allTagsModel = tagItems.map{FTTagModel(id: $0.id, text: $0.tagName, image: nil, isSelected: pageTags.contains($0))};
            tagsVc.setTagsList(allTagsModel)
        }
    }

    fileprivate func toggleSettingTapped(isOn: Bool, setting: FTNotebookMoreOption) {
        if let _setting = setting as? FTNotebookStatusBarSetting {
            _setting.updateToggleStatus(with: isOn)
            FTUserDefaults.defaults().showStatusBar = !isOn
            let value = FTUserDefaults.defaults().showStatusBar ? "on" : "off"
            track("nbk_statusbar_toggle", params: ["toggle": value], screenName: FTScreenNames.notebook)
        }
    }
    
    private func addTableHeaderview() {
        guard let view = Bundle.main.loadNibNamed("FTNoteBookToolsHeaderView", owner: nil, options: nil)?.first as? FTNotebookToolsHeaderView else {
            fatalError("Progarammer error, unable to find FTRecentSectionHeader")
        }
#if targetEnvironment(macCatalyst)
        view.frame.size.height = 116 * 0.5
#else
        view.frame.size.height = 116
#endif
        view.confiure(with: self.page)
        view.del = self
        self.tblSettings?.tableHeaderView = view
    }
}

// MARK: - UITableViewDelegate
extension FTNotebookMoreOptionsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Page".localized.uppercased()
        } else if section == 1 {
            return "Settings".localized.uppercased()
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.appFont(for: .medium, with: 13.0)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == settings.count - 1 ? 16.0 : CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let setting = settings[indexPath.section][indexPath.row]
        if setting is FTCustomizeToolbarSetting {
            return 48
        }
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "FTNotebookMoreOptionsCell", for: indexPath)
        let setting = settings[indexPath.section][indexPath.row]
        if let settingCell = cell as? FTNotebookMoreOptionsCell {
            settingCell.shoudlHighlightDotView = false
            settingCell.configure(with: setting)
            if setting.type == .toggleAccessory {
                settingCell.toggleTapped = { [weak self] isOn, setting in
                    self?.toggleSettingTapped(isOn: isOn, setting: setting)
                }
            } else {
                settingCell.toggleTapped = nil
            }
            if setting is FTCustomizeToolbarSetting {
                settingCell.backgroundColor = .appColor(.black5)
            } else {
                settingCell.backgroundColor = .appColor(.white60)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //************
        //https://www.notion.so/fluidtouch/App-is-crashing-by-tapping-with-two-fingers-1e2cc8910bbd4749beccd3257684b037
        guard notebookShelfItem != nil, page != nil, notebookDocument != nil else {
            self.dismiss(animated: false, completion: nil)
            return
        }
        //************
        
        var setting = settings[indexPath.section][indexPath.row]
        switch setting {
        case is FTNotebookOptionChangeTemplate:
            self.delegate?.presentChangeTemplateScreen(settingsController: self)
        case is FTNotebookOptionShare:
            self.delegate?.getShareInfo(completion: { [weak self] shareinfo in
                guard let self = self else { return }
                let shareHostingVc = FTShareHostingController.pushShareVc(from: self,info: shareinfo)
                shareHostingVc.delegate = self.delegate
            })
        case is FTNotebookOptionRotate:
            self.performSegue(withIdentifier: "showRotationOptions", sender: nil)
        case is FTNotebookOptionGesture:
            self.delegate?.didTapBasicOption(option: .gestures, with: page, controller: self)
        case is FTNotebookOptionGetInfo:
            self.performSegue(withIdentifier: "showGetInfo", sender: nil)
        case is FTNotebookOptionPresentMode:
            self.delegate?.didTapBasicOption(option: .present, with: page, controller: self)
        case is FTNotebookOptionHelp:
            self.delegate?.didTapBasicOption(option: .help, with: page, controller: self)
        case is FTCustomizeToolbarSetting:
            self.delegate?.didTapBasicOption(option: .customizeToolBar, with: page, controller: self)
        case is FTNotebookOptionTag:
            self.performSegue(withIdentifier: "showTags", sender: nil)
        case is FTNotebookOptionPresentMode:
            self.delegate?.didTapBasicOption(option: .present, with: page, controller: self)
        case is FTNotebookOptionSettings:
            let settingsVc = FTNoteBookSettingsViewController.instantiate(fromStoryboard: .notebookSettings)
            settingsVc.notebookDocument = self.notebookDocument
            settingsVc.notebookShelfItem = self.notebookShelfItem
            settingsVc.delegate = self
            self.navigationController?.pushViewController(settingsVc, animated: true)
        case is FTNotebookOptionGoToPage:
            self.showGoToPageAlert()
        case is FTNotebookOptionZoomBox:
            self.delegate?.didTapBasicOption(option: .zoomBox, with: page, controller: self)
        case is FTNotebookOptionSaveAsTemplate:
            self.delegate?.didTapBasicOption(option: .saveAsTemplate, with: page, controller: self)
        default:
#if DEBUG
            print("Setting", setting.localizedTitle)
#endif
        }
        setting.isViewed = true
        FTNotebookEventTracker.trackNotebookEvent(with: setting.eventName)
    }
    
    func showGoToPageAlert() {
        let headerTitle = NSLocalizedString("GoToPage", comment: "Go To Page");
        let alertController = UIAlertController.init(title: headerTitle, message: nil, preferredStyle: .alert);
        weak var weakAlertController = alertController;
        weak var weakSelf = self;
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: {[weak self] (_) in
            guard let self = self else { return }
            if let text = weakAlertController?.textFields?.first?.text {
                let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                if !trimmedText.isEmpty {
                    var pageNumber = (trimmedText as NSString).integerValue
                    if pageNumber < 0 {
                        pageNumber = 0
                    }
                    self.delegate?.handleGotoPage(pageNumber, controller: self)
                }
            }
        });
        alertController.addAction(okAction);
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil);
        alertController.addAction(cancelAction);
        
        alertController.addTextField(configurationHandler: { (textFiled) in
            textFiled.delegate = weakSelf;
            textFiled.autocapitalizationType = UITextAutocapitalizationType.none;
            textFiled.keyboardType = .phonePad
            textFiled.setDefaultStyle(.defaultStyle);
            let enterPageNumberString = String(format: NSLocalizedString("EnterBetweenNandN", comment: "Enter between %d and %d"), 1, self.notebookDocument.pages().count)
            textFiled.setStyledPlaceHolder(enterPageNumberString, style: .defaultStyle);
            textFiled.minimumFontSize = 10
            textFiled.adjustsFontSizeToFitWidth = true
        })
        self.present(alertController, animated: true, completion: nil);
    }
}

extension FTNotebookMoreOptionsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let aSet = CharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined()
        var isValid = (string == numberFiltered)
        if isValid, !string.isEmpty, let numberText = textField.text {
            guard let textRange = Range(range, in: numberText) else { return false }
            let numberText = textField.text?.replacingCharacters(in: textRange, with: string)
            if let pageNumber = (numberText as NSString?)?.integerValue, (pageNumber < 1 || pageNumber > self.notebookDocument.pages().count) {
                isValid = false
            }
        }
        return isValid
    }
}

extension FTNotebookMoreOptionsViewController: FTShareBeginnerDelegate, FTGetInfoDelegate {
    func didSelectShareOption(option: FTShareOption) {
        self.dismiss(animated: true) {
            self.delegate?.didSelectShareOption(option: option)
        }
        let eventName : String
        switch option {
        case .allPages:
            eventName = FTNotebookEventTracker.nbk_more_share_allpages_tap
        case .selectPages:
            eventName = FTNotebookEventTracker.nbk_more_share_selectpages_tap
        case .currentPage:
            eventName = FTNotebookEventTracker.nbk_more_share_currentpage_tap
        case .notebook:
            eventName = ""
        }
        FTNotebookEventTracker.trackNotebookEvent(with: eventName)
    }
    
    func handleGoToPage(with page: Int) {
        self.delegate?.handleGotoPage(page, controller: self)
    }
}
extension FTNotebookMoreOptionsViewController: FTNoteBookSettingsVCDelegate {
    func presentPasswordScreen() {
        self.delegate?.presentPasswordScreen(settingsController: self)
    }
}


extension FTNotebookMoreOptionsViewController: FTNotebookToolDelegate {
    func didTapTool(type: FTNotebookTool) {
        switch type {
        case .share:
            self.delegate?.getShareInfo(completion: { [weak self] shareinfo in
                guard let self = self else { return }
                let shareHostingVc = FTShareHostingController.pushShareVc(from: self,info: shareinfo)
                shareHostingVc.delegate = self.delegate
            })
        case .present:
            self.delegate?.didTapBasicOption(option: .present, with: page, controller: self)
        case .gotoPage:
            self.showGoToPageAlert()
        case .zoomBox:
            self.delegate?.didTapBasicOption(option: .zoomBox, with: page, controller: self)
        }
        type.trackEvent()
    }
}
