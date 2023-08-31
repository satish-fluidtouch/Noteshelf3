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

protocol FTTextPresetSelectedDelegate: NSObjectProtocol {
    func didSelectedPresetStyleId(_ style: FTTextStyleItem)
    func reloadStylesStackView()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        addItemsInNavigationBar()
        updateTextStylesList()
        self.presetTableView?.allowsSelectionDuringEditing = true;
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.backgroundColor = UIColor.appColor(.popoverBgColor)
        self.didHighLightSelectedStyle(attr: self.attributes, scale: scale)
        let shadowColor = UIColor(hexString: "#000000")
        self.view.layer.applySketchShadow(color: shadowColor, alpha: 0.2, x: 0.0, y: 10.0, blur: 60.0, spread: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(didTextAnnotationBoxResign), name: ftDidTextAnnotationResignNotifier, object: nil)
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
        let textToolBarVC = (delegate as? FTTextToolBarViewController)
        textToolBarVC?.textHighLightSyleDelegate = textPresetsVC
        viewController.ftPresentPopover(vcToPresent: textPresetsVC, contentSize: CGSize(width: 320, height: 416))
    }
    
    func updateTextStylesList() {
        textStyle = FTTextStyleManager.shared.fetchTextStylesFromPlist()
        self.presetTableView?.reloadData()
    }
    
    private func addItemsInNavigationBar() {
        self.title = viewmodel.navPresettitle
        if self.presentingViewController?.isRegularClass() ?? false {
            let editBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(didTappedOnEdit(sender:)))

            let resetBarButtonItem = UIBarButtonItem(title: viewmodel.reset, style: .plain, target: self, action: #selector(didTappedOnResetButton(sender:)))
            resetBarButtonItem.tintColor = UIColor.appColor(.darkRed)
            
            navigationItem.leftBarButtonItem = editBarButtonItem
            navigationItem.rightBarButtonItem = resetBarButtonItem
        }
    }
}

extension FTTextPresetsViewController {
    private func navigateToNewStyleVC(_ textStyle: FTTextStyleItem? = nil, mode: FTTextStyleScreenMode) {
        let textPresetsVC = self.fetchPreparedNewStyleVcToSow()
        textPresetsVC.textStyleMode = mode
        if let style = textStyle {
            textPresetsVC.textFontStyle = style
        }
        self.navigationController?.pushViewController(textPresetsVC, animated: true)
    }

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

    private func presentNewStyleVcAsFormsheet(mode: FTTextStyleScreenMode) {
        let textPresetsVC = self.fetchPreparedNewStyleVcToSow()
        textPresetsVC.textStyleMode = mode
        let presentingVc = self.presentingViewController ?? self
        self.dismiss(animated: true) {
            self.delegate?.dismissKeyboard()
            presentingVc.ftPresentFormsheet(vcToPresent: textPresetsVC,hideNavBar: false)
        }
    }

    @objc func didTappedOnEdit(sender: UIBarButtonItem) {
        let presentingVc = self.presentingViewController ?? self
        self.dismiss(animated: true) {
            self.presetTableView?.isEditing = true
            self.presetTableView?.dragInteractionEnabled = true
            self.title = self.viewmodel.navReordertitle

            let doneButtonItem  = UIBarButtonItem(title: self.viewmodel.done, style: .plain, target: self, action: #selector(self.tappedOnDoneBtn(sender:)))
            doneButtonItem.tintColor = UIColor.appColor(.accent)
            self.navigationItem.rightBarButtonItems = [doneButtonItem]
            self.navigationItem.leftBarButtonItems = []
            self.delegate?.dismissKeyboard()
            presentingVc.ftPresentFormsheet(vcToPresent: self,hideNavBar: false)
        }
    }

    @objc func tappedOnDoneBtn(sender: UIBarButtonItem) {
        self.addItemsInNavigationBar()
        self.delegate?.reloadStylesStackView()
        self.presetTableView?.isEditing = false
        self.presetTableView?.dragInteractionEnabled = false
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

        var selectedStyle = textStyle.styles[indexPath.row]
        var isAddMode = false
        if tableView.cellForRow(at: indexPath) is FTAddNewTextStyleCell {
            isAddMode = true
            if let index = lastSelectedIndex {
                selectedStyle = textStyle.styles[index]
            }
        }

        if tableView.isEditing {
            if indexPath.section == 0 {
                self.navigateToNewStyleVC(selectedStyle, mode: .presetEdit)
            } else if isAddMode {
                self.navigateToNewStyleVC(selectedStyle, mode: .presetEditAdd)
            }
        } else {
            if indexPath.section == 0 {
                self.delegate?.didSelectedPresetStyleId(selectedStyle)
                self.dismiss(animated: true)
            } else if isAddMode {
                self.presentNewStyleVcAsFormsheet(mode: .presetXclusiveAdd)
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
            self.navigateToNewStyleVC(selectedStyle, mode: .presetEdit)
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
