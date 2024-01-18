//
//  FTLinkTextTableViewCell.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTLinkTextTableViewCell: UITableViewCell {
    static let linkTextCellId = "FTLinkTextTableViewCell"

    @IBOutlet private weak var linkTextLabel: UILabel!
    @IBOutlet private weak var linkTextTf: UITextField!

    var textEntryChangeHandler: ((_ text: String?) -> Void)?
    var textEntryDoneHandler: ((_ text: String?) -> Void)?

    func configureCell(with option: FTLinkToOption, linkText: String) {
        self.linkTextLabel.text = option.rawValue
        self.linkTextTf.text = linkText

        if option == .url {
            self.linkTextTf.textColor = UIColor.appColor(.accent)
        } else {
            self.linkTextTf.textColor = UIColor.appColor(.black50)
        }
    }
}

extension FTLinkTextTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textEntryDoneHandler?(textField.text)
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        self.textEntryChangeHandler?(updatedText)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.textEntryDoneHandler?(textField.text)
    }
}
