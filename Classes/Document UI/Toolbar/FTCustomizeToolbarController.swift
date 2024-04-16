//
//  FTCustomizeToolbarController.swift
//  Noteshelf3
//
//  Created by Narayana on 23/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let notifyToolbarCustomization = "didCustomizeCenterPanelToolbar"

class FTCustomizeToolbarController: UITableViewController {
    private var dataSource = FTCustomizeToolbarDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        self.tableView.dragInteractionEnabled = true
        self.tableView.isEditing = true
        self.configNavigationTitle()
        self.configBarButtonItems()
        self.registerCells()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setUpFooterViewtoTableView()

    }
    
    private func registerCells() {
        tableView.register(UINib(nibName:"FTCustomizeToolbarCell", bundle: nil), forCellReuseIdentifier: "FTCustomizeToolbarCell")
    }
    
    private func setUpFooterViewtoTableView(){
        let footerView = Bundle.main.loadNibNamed("FTCustomToolbarFooterView", owner: nil)?[0] as? FTCustomToolbarFooterView
        footerView?.setUpUi()
        footerView?.delegate = self
        tableView.tableFooterView = footerView
    }

    private func configNavigationTitle() {
        self.title = NSLocalizedString("notebookSetting.customizeToolbar", comment: "Customize Toolbar")
        let attributes = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0)]
        self.navigationController?.navigationBar.titleTextAttributes = attributes
    }

    private func configBarButtonItems() {
        let font = UIFont.appFont(for: .regular, with: 15)

        let resetBtn = UIButton()
        configCustomButton(resetBtn, title: NSLocalizedString("reset", comment: "Reset"), color: UIColor.appColor(.destructiveRed))
        resetBtn.addTarget(self, action: #selector(resetTapped(sender:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: resetBtn)

        let doneBtn = UIButton()
        configCustomButton(doneBtn, title: NSLocalizedString("done", comment: "Done"), color: UIColor.appColor(.accent))
        doneBtn.addTarget(self, action: #selector(doneTapped(sender:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneBtn)

        func configCustomButton(_ btn: UIButton, title: String, color: UIColor) {
            let width = title.widthOfString(usingFont: font)
            btn.frame.size = CGSize(width: width + 10.0, height: 40.0)
            btn.titleLabel?.font = font
            btn.setTitleColor(color, for: .normal)
            btn.setTitle(title, for: .normal)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) { super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.tableView.reloadData()
        }
    }

    @objc func resetTapped(sender: UIButton) {
        let alertTitle = "customizeToolbar.resetConfirmation".localized
        let resetTitle = "reset".localized
        let cancelTitle = "cancel".localized
        let alertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        let emptyTrashAction = UIAlertAction(title: resetTitle, style: .destructive) { _ in
            self.dataSource.resetToDefaults()
            self.dataSource = FTCustomizeToolbarDataSource()
            self.tableView.reloadData()
            self.saveCurrentToolsAndNotify()
        }
        let cancelAction = UIAlertAction(title: cancelTitle, style: .default)
        alertController.addAction(cancelAction)
        alertController.addAction(emptyTrashAction)
        self.present(alertController, animated: true, completion: nil)
        // Track Event
        track(EventName.customizetoolbar_reset_tap)
    }

    @objc func doneTapped(sender: UIButton) {
        // Track Event
        let count = FTCurrentToolbarSection().displayTools.count
        track(EventName.customizetoolbar_done_tap, params: [EventParameterKey.count: count])
        self.dismiss(animated: true)
    }

    private func saveCurrentToolsAndNotify() {
        if let currentSection = self.dataSource.sections.first as? FTCurrentToolbarSection {
            FTCurrentToolbarSection.saveCurrentToolTypes(currentSection.displayTools)
            NotificationCenter.default.post(name: Notification.Name(notifyToolbarCustomization), object: self, userInfo: nil)
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.sections.count
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.appFont(for: .medium, with: 13.0)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataSource.sections[section].displayTitle
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let displaySection = self.dataSource.sections[section]
        return displaySection.displayTools.count
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var height: CGFloat = 18.0
        if section < self.dataSource.sections.count {
            if self.dataSource.sections[section].displayTools.isEmpty {
                height = 40.0
            }
        }
        return height
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTCustomizeToolbarCell", for: indexPath) as? FTCustomizeToolbarCell else {
              fatalError("Programming Error ")
        }
        
        let displaySection = self.dataSource.sections[indexPath.section]
        let displayableTools = displaySection.displayTools

        var config = cell.defaultContentConfiguration()
        let tool = displayableTools[indexPath.row]
        if !(tool == .sharePageAsPng || tool == .shareNotebookAsPDF || tool == .savePageAsPhoto) {
            config.imageProperties.tintColor = UIColor.label
        }
        cell.newBgView.isHidden = tool.toShowNewBadge
        cell.iconImg.image = UIImage(named: tool.iconName())
        config.imageProperties.reservedLayoutSize = CGSize(width: 24.0, height: 24.0)
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17.0)]
        cell.titleLbl.attributedText = NSAttributedString(string: displayableTools[indexPath.row].localizedString(), attributes: attributes)
        cell.backgroundColor = UIColor.appColor(.white60)
        return cell
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) ->
    UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return .delete
        }
        return .insert
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        if fromIndexPath.section == 0 && to.section == 0 {
            let reqSection = self.dataSource.sections[0]
            let reqSectionData = reqSection.displayTools
            let itemToMove = reqSectionData[fromIndexPath.row]
            self.dataSource.removeDisplayTool(itemToMove, from: reqSection)
            self.dataSource.insertTool(itemToMove, at: to.row, in: reqSection.type)
            self.saveCurrentToolsAndNotify()
            // Track Event
            track(EventName.customizetoolbar_tool_reorder, params: [EventParameterKey.tool: itemToMove.localizedEnglish()])
        } else {
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let editStartSection = self.dataSource.sections[indexPath.section]
        let editItem = editStartSection.displayTools[indexPath.row]

        let currentToolbarSection = self.dataSource.sections[0]
        var currentToolTypes = currentToolbarSection.displayTools

        if editingStyle == .insert && indexPath.section != 0 {
            currentToolTypes.append(editItem)
            self.dataSource.removeDisplayTool(editItem, from: editStartSection)
            self.dataSource.appendToolToCurrentToolbarSection(tool: editItem)

            // refresh UI
            tableView.performBatchUpdates {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [IndexPath(item: currentToolTypes.endIndex - 1, section: 0)], with: .automatic)
                if editStartSection.displayTools.isEmpty {
                    tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
                }
            }
            self.saveCurrentToolsAndNotify()
            // Track Event
            track(EventName.customizetoolbar_tool_add, params: [EventParameterKey.tool: editItem.localizedEnglish()])

        } else if editingStyle == .delete && indexPath.section == 0 {
            currentToolTypes.remove(at: indexPath.row)
            self.dataSource.removeDisplayTool(editItem, from: editStartSection)
            let destSectionType = self.dataSource.sectionType(for: editItem)
            let index = self.dataSource.insertTool(editItem, of: destSectionType)

            // refresh UI
            tableView.performBatchUpdates {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [IndexPath(item: index, section: destSectionType.rawValue)], with: .automatic)
            }
            self.saveCurrentToolsAndNotify()
            // Track Event
            track(EventName.customizetoolbar_tool_remove, params: [EventParameterKey.tool: editItem.localizedEnglish()])

        }
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        var toMove = false
        if indexPath.section == 0 {
            toMove = true
        }
        return toMove
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove".localized
    }
    
}

extension FTCustomizeToolbarController {
    class func showCustomizeToolbarScreen(controller: UIViewController) {
        let storyboard = UIStoryboard.init(name: "FTNotebookMoreOptions", bundle: nil);
        if let customizeToolbarVc = storyboard.instantiateViewController(withIdentifier: FTCustomizeToolbarController.className) as? FTCustomizeToolbarController {
            let navController = UINavigationController(rootViewController: customizeToolbarVc)
            navController.view.backgroundColor = UIColor.appColor(.formSheetBgColor)
            controller.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
        }
    }
}

extension FTCustomizeToolbarController :FTCustomToolbarFooterViewProtocal {
    func navigateToContactUsPage() {
        FTZenDeskManager.shared.showSupportContactUsScreen(controller: self, defaultSubject: "App Launch Delay", extraTags: ["ns3_app_launc_delay"])
    }
}
