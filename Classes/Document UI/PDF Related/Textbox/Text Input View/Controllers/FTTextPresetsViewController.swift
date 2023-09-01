//
//  FTTextPresetsViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 27/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

enum FTPresetStyleMode: String {
    case select
    case edit
    case reorder
}

protocol FTTextPresetSelectedDelegate: NSObjectProtocol {
    func didSelectedPresetStyleId(_ style: FTTextStyleItem)
    func reloadStylesStackView()
    func rootViewController() -> UIViewController?
    func dismissKeyboard()
}

class FTTextPresetsViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    @IBOutlet weak var presetTableView: UITableView?
    
    var textStyle = FTTextStyleManager.shared.fetchTextStylesFromPlist()
    weak var delegate: FTTextPresetSelectedDelegate?
    var lastSelectedIndex: Int?
    var attributes: [NSAttributedString.Key: Any]?
    var scale: CGFloat = 1.0
    private let viewmodel = FTTextPresetViewModel()

    private var presetMode: FTPresetStyleMode = .select {
        didSet {
            self.configureUIItems(with: presetMode)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presetTableView?.allowsSelectionDuringEditing = true;
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.backgroundColor = UIColor.appColor(.popoverBgColor)
        self.didHighLightSelectedStyle(attr: self.attributes, scale: scale)
        let shadowColor = UIColor(hexString: "#000000")
        self.view.layer.applySketchShadow(color: shadowColor, alpha: 0.2, x: 0.0, y: 10.0, blur: 60.0, spread: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(didTextAnnotationBoxResign), name: ftDidTextAnnotationResignNotifier, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTextStylesList()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func didTextAnnotationBoxResign() {
        self.dismiss(animated: true)
    }

    class func showAsPopover(fromSourceView sourceView: UIView,
                             overViewController viewController: UIViewController,
                             delegate: FTTextPresetSelectedDelegate,
                             attributes: [NSAttributedString.Key: Any]?,
                             scale: CGFloat) {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil)
        guard let textPresetsVC = storyboard.instantiateViewController(withIdentifier: "FTTextPresetsViewController") as? FTTextPresetsViewController else {
            fatalError("FTTextPresetsViewController not found")
        }
        textPresetsVC.ftPresentationDelegate.source = sourceView
        textPresetsVC.delegate = delegate
        textPresetsVC.scale = scale
        textPresetsVC.attributes = attributes
        textPresetsVC.presetMode = .select
        let textToolBarVC = (delegate as? FTTextToolBarViewController)
        textToolBarVC?.textHighLightSyleDelegate = textPresetsVC
        viewController.ftPresentPopover(vcToPresent: textPresetsVC, contentSize: CGSize(width: 320, height: 416))
    }
    
    func updateTextStylesList() {
        textStyle = FTTextStyleManager.shared.fetchTextStylesFromPlist()
        self.presetTableView?.reloadData()
    }
}

extension FTTextPresetsViewController {
    private func fetchPreparedNewStyleVcToSow() -> FTNewTextStyleViewController {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil)
        guard let textPresetsVC = storyboard.instantiateViewController(withIdentifier: "FTNewTextStyleViewController") as? FTNewTextStyleViewController else {
            fatalError("FTTextPresetsViewController not found")
        }
        textPresetsVC.delegate = delegate as? any FTEditStyleDelegate
        textPresetsVC.scale = scale
        textPresetsVC.attributes = attributes
        let textToolBarVC = (delegate as? FTTextToolBarViewController)
        textToolBarVC?.textHighLightSyleDelegate = textPresetsVC as? any FTStyleSelectionDelegate
        let shadowColor = UIColor(hexString: "#000000")
        textPresetsVC.view.layer.applySketchShadow(color: shadowColor, alpha: 0.2, x: 0.0, y: 10.0, blur: 60.0, spread: 0)
        return textPresetsVC
    }

    private func handleNewStyleVcPresentation(style: FTTextStyleItem? = nil, mode: FTTextStyleScreenMode) {
        let newStyleVc = self.fetchPreparedNewStyleVcToSow()
        newStyleVc.textStyleMode = mode
        if let txtSTyle = style {
            newStyleVc.textFontStyle = txtSTyle
        }
        if let navVc = self.navigationController {
            if navVc.modalPresentationStyle == .formSheet {
                navVc.pushViewController(newStyleVc, animated: true)
            } else { // popover
                var presentingVc = self.presentingViewController ?? self
                if let rootVc = self.delegate?.rootViewController() {
                    presentingVc = rootVc
                }
                self.dismiss(animated: true) {
                    self.delegate?.dismissKeyboard()
                    self.navigationController?.pushViewController(newStyleVc, animated: false) // silent push
                    let navVc = self.navigationController
                    presentingVc.ftPresentFormsheet(vcToPresent: navVc!,hideNavBar: false, completion: {
                        self.presetMode = .edit
                    })
                }
            }
        }
    }

    @objc func didTappedOnEdit(sender: UIBarButtonItem) {
        if self.presetMode == .select {
            var presentingVc = self.presentingViewController ?? self
            if let rootVc = self.delegate?.rootViewController() {
                presentingVc = rootVc
            }
            self.dismiss(animated: true) {
                self.delegate?.dismissKeyboard()
                self.presetMode = .reorder
                presentingVc.ftPresentFormsheet(vcToPresent: self,animated: false, hideNavBar: false)
            }
        } else if self.presetMode == .edit {
            self.presetMode = .reorder
            self.presetTableView?.reloadData()
        }
    }

    private func configureUIItems(with mode: FTPresetStyleMode) {
        self.navigationItem.rightBarButtonItems = []
        self.navigationItem.leftBarButtonItems = []
        if mode == .select {
            self.title = viewmodel.navPresettitle
            self.presetTableView?.isEditing = true
            self.presetTableView?.dragInteractionEnabled = true
            // nav items
            let editBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(didTappedOnEdit(sender:)))
            let resetBarButtonItem = UIBarButtonItem(title: viewmodel.reset, style: .plain, target: self, action: #selector(didTappedOnResetButton(sender:)))
            resetBarButtonItem.tintColor = UIColor.appColor(.darkRed)
            self.navigationItem.leftBarButtonItem = editBarButtonItem
            self.navigationItem.rightBarButtonItem = resetBarButtonItem
        } else {
            self.title = self.viewmodel.navReordertitle
            self.presetTableView?.isEditing = true
            self.presetTableView?.dragInteractionEnabled = true
            // nav items
            let doneButtonItem  = UIBarButtonItem(title: self.viewmodel.done, style: .plain, target: self, action: #selector(self.tappedOnDoneBtn(sender:)))
            doneButtonItem.tintColor = UIColor.appColor(.accent)
            self.navigationItem.rightBarButtonItems = [doneButtonItem]
        }
    }

    @objc func tappedOnDoneBtn(sender: UIBarButtonItem) {
        self.delegate?.reloadStylesStackView()
        self.dismiss(animated: true)
    }
    
    @objc func didTappedOnResetButton(sender: UIBarButtonItem) {
        UIAlertController.showConfirmationAlert(with: viewmodel.resetAlertdes, message: "", from: self.parent, okButtonTitle: viewmodel.resetAlert, cancelButtonTitle: viewmodel.alertCancel) {
            FTTextStyleManager.shared.resetPresetTextStyles()
            self.updateTextStylesList()
            self.delegate?.reloadStylesStackView()
        }
    }
}

extension FTTextPresetsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? textStyle.styles.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FTPresetsStyleCell", for: indexPath)
            if let presetCell = cell as? FTPresetsStyleCell {
                let style = textStyle.styles[indexPath.row]
                presetCell.updatePresetWithStyle(style)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FTAddNewTextStyleCell", for: indexPath)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if textStyle.styles.count < indexPath.row {
            return
        }
        if indexPath.section == 1, tableView.cellForRow(at: indexPath) is FTAddNewTextStyleCell { // Add New Preset
            self.handleNewStyleVcPresentation(mode: .presetAdd)
        } else if !tableView.isEditing { // in popover mode(selection mode)
            let selectedStyle = textStyle.styles[indexPath.row]
            if self.presetMode == .select {
                self.delegate?.didSelectedPresetStyleId(selectedStyle)
                self.dismiss(animated: true)
            } else {
                self.handleNewStyleVcPresentation(style: selectedStyle, mode: .presetEdit)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 48.0 : 44.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0, indexPath.row < textStyle.styles.count {
            let style = textStyle.styles[indexPath.row]
            if style.isDefault {
                return .none
            }
            return .delete
        }
        return .none
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 && self.presetMode == .reorder {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if destinationIndexPath.section == 0 &&  sourceIndexPath.section == 0 {
            let style = textStyle.styles[sourceIndexPath.row]
            textStyle.styles.remove(at: sourceIndexPath.row)
            textStyle.styles.insert(style, at: destinationIndexPath.row)
            FTTextStyleManager.shared.updateOrderOfStyles(textStyle)
        }else{
            presetTableView?.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let style = textStyle.styles[indexPath.row]
            FTTextStyleManager.shared.deleteTextStyle(style)
            self.textStyle.styles.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.delegate?.reloadStylesStackView()
        }
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let selectedStyle = textStyle.styles[indexPath.row]
        if selectedStyle.isDefault {
            return nil
        }
        let editAction = UIContextualAction(style: .normal, title: viewmodel.editpreset) { action, vw, success in
            self.handleNewStyleVcPresentation(style: selectedStyle, mode: .presetEdit)
        }
        editAction.backgroundColor = UIColor.appColor(.accent)
       
        let deleteAction = UIContextualAction(style: .destructive, title:  viewmodel.deletepreset) { action, vw, success in
            FTTextStyleManager.shared.deleteTextStyle(selectedStyle)
            self.textStyle.styles.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.delegate?.reloadStylesStackView()
        }
        deleteAction.backgroundColor =  UIColor.appColor(.destructiveRed)
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
}


//Update selection for textStyle in tableview
extension FTTextPresetsViewController: FTStyleSelectionDelegate {
    func didHighLightSelectedStyle(attr: [NSAttributedString.Key : Any]?, scale: CGFloat) {
        guard let attributes = attr else { return }
        let style = FTTextStyleItem().textStyleFromAttributes(attributes, scale: scale)
        if let index =  textStyle.styles.firstIndex(where: {$0.isEqual(style)}) {
            if let idx = lastSelectedIndex {
                if let cell = self.presetTableView?.cellForRow(at: IndexPath(item: idx, section: 0)) {
                    cell.isSelected = false
                }
            }
            
            let idxPath = IndexPath(item: index, section: 0)
            if let cell = self.presetTableView?.cellForRow(at: idxPath) {
                lastSelectedIndex = index
                cell.isSelected = true
                self.presetTableView?.scrollToRow(at: idxPath, at: .none, animated: true)
            }
        }
    }
}
