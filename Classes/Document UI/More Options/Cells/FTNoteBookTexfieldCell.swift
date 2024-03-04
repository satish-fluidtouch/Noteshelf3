//
//  FTNoteBookTexfieldCell.swift
//  Noteshelf3
//
//  Created by Sameer on 10/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTNoteBookTexfieldCell: UITableViewCell {
    @IBOutlet weak var titleTextField: UITextField!
    weak var delegate: FTNotebookTitleDelegate?
    var actualTitle: String = ""
    var renamedTitle: String = ""
    
    override  func awakeFromNib() {
        super.awakeFromNib()
        titleTextField.delegate = self
    }
    
    func configure(info: FTNotebookInfoProperty) {
        self.titleTextField.text = info.description
        self.titleTextField.textAlignment = .center
        self.titleTextField.font = UIFont.appFont(for: .medium, with: 17)
        self.titleTextField?.textColor = UIColor.label
        #if targetEnvironment(macCatalyst)
        self.titleTextField?.isUserInteractionEnabled = false
        #endif
    }
}

extension FTNoteBookTexfieldCell : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let newPosition = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            guard let textRange = Range(range, in: text) else { return false }
            if let fullText = textField.text?.replacingCharacters(in: textRange, with: string) {
                self.renamedTitle = fullText
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.handleEndEdit(textField: textField)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_more_getinfo_title_tap)
        self.handleEndEdit(textField: textField)
    }
    
    private func handleEndEdit(textField: UITextField) {
        if let text = textField.text {
            let finalText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            self.renamedTitle = finalText == "" ? self.actualTitle : text
        }
        if self.renamedTitle != self.actualTitle {
            self.delegate?.renameShelfItem(title: self.renamedTitle, onCompletion: { _ in
            })
        }
    }
}
