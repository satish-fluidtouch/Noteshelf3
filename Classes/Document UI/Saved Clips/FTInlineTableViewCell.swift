//
//  FTInlineTableViewCell.swift
//  Noteshelf3
//
//  Created by Siva on 22/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTInlineTableViewCell: UITableViewCell, UITextFieldDelegate {

    let textField = UITextField()

    // closure used to tell the controller that the text field has been edited
    var didEndEditing: ((String) ->())?
    var didBeginEditing: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Toggle the checkmark based on the cell selection
        accessoryType = selected ? .checkmark : .none
        self.backgroundColor = UIColor.appColor(.white60)
    }

    func commonInit() {
        textField.delegate = self
        textField.borderStyle = .none
        textField.returnKeyType = .done
        textField.attributedPlaceholder = attributedPlaceHolder()
        textField.backgroundColor = .clear

        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)

        let g = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: g.topAnchor, constant: 0.0),
            textField.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 0.0),
            textField.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: 0.0),
            textField.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: 0.0),
        ])

    }

    let attributedPlaceHolder = {
        return NSAttributedString(
            string: "New Category...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.appColor(.accent)]
        )
    }
    let lightAttributedPlaceHolder = {
        return NSAttributedString(
            string: "New Category...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.applePlaceholderGray]
        )
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.attributedPlaceholder = lightAttributedPlaceHolder()
        didBeginEditing?()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.attributedPlaceholder = attributedPlaceHolder()
        didEndEditing?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }

    // UITextFieldDelegate method to limit the number of characters
      func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
          // Check if the total length of the text after replacement will be less than or equal to 52
          let currentText = (textField.text ?? "") as NSString
          let newText = currentText.replacingCharacters(in: range, with: string) as NSString
          return newText.length <= 52
      }

}

extension UIColor {
    static var applePlaceholderGray: UIColor {
        return UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
    }
}

