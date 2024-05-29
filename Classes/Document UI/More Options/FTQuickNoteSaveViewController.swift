//
//  FTQuickNoteSaveViewController.swift
//  Noteshelf
//
//  Created by Narayana on 01/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTQuickNoteSaveDelegate: AnyObject {
    func didSaveQuickCreatedNote(quickNoteVc: FTQuickNoteSaveViewController, noteTitle: String)
    func didDeleteQuickCreatedNote(quickNoteVc: FTQuickNoteSaveViewController)
}

class FTQuickNoteSaveViewController: UIViewController, FTCustomPresentable {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var quickNoteTextField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var moveToTrashBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var quickNoteTitle: String = "Quick Note1"// will be assigned only from outside
    var editableTitle: String = ""
    weak var delegate: FTQuickNoteSaveDelegate!
    
    var customTransitioningDelegate: FTCustomTransitionDelegate = FTCustomTransitionDelegate(with: .interaction, supportsFullScreen: false)
    
    var isFromCentralPanel : Bool  = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUIComponents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isFromCentralPanel {
            if let window = self.view.window {
                NotificationCenter.default.post(name: .leftPanelPopupDismiss, object:window)
            }
        }
    }
    
    private func configureUIComponents() {
        self.headerLabel.text = NSLocalizedString("quickNoteSave.saveQuickNote", comment: "save quick note")
        self.headerLabel.addCharacterSpacing(kernValue: -0.41)
        self.saveBtn.setTitle(NSLocalizedString("Save", comment: "Save"), for: .normal)
        self.saveBtn.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        self.moveToTrashBtn.setTitle(NSLocalizedString("quickNoteSave.deleteQuickNote", comment: "Delete Quick Note"), for: .normal)
        self.moveToTrashBtn.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        self.cancelBtn.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal)
        self.cancelBtn.titleLabel?.addCharacterSpacing(kernValue: -0.41)
        
        self.quickNoteTextField.autocapitalizationType = UITextAutocapitalizationType.words
        self.quickNoteTextField.setStyledPlaceHolder(self.quickNoteTitle, style: .style9)
        self.editableTitle = self.quickNoteTitle
    }
    
    @IBAction func saveBtnTapped(_ sender: Any) {
        let finalText = self.editableTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if finalText.isEmpty {
            self.editableTitle = self.quickNoteTitle
        }
        self.delegate.didSaveQuickCreatedNote(quickNoteVc: self, noteTitle: self.editableTitle)
    }
    
    @IBAction func moveToTrashTapped(_ sender: Any) {
        self.delegate.didDeleteQuickCreatedNote(quickNoteVc: self)
    }
    
    @IBAction func cancelBtnTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension FTQuickNoteSaveViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = self.editableTitle
        let newPosition = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.handleEndEdit(textField: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            guard let textRange = Range(range, in: text) else { return false }
            if let fullText = textField.text?.replacingCharacters(in: textRange, with: string) {
                self.editableTitle = fullText
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.handleEndEdit(textField: textField)
        return true
    }
    
    private func handleEndEdit(textField: UITextField) {
        if let text = textField.text {
            let finalText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            self.editableTitle = finalText == "" ? self.quickNoteTitle : text
        }
    }
}
