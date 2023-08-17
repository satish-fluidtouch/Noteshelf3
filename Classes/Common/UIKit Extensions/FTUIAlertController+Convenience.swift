//
//  UIAlertController+Convenience.swift
//  Noteshelf
//
//  Created by Paramasivan on 7/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension UIAlertController {
    static func showRenameDialog(with title: String, message: String, renameText: String, from viewController: UIViewController?, supportHandler: @escaping ((String) -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        weak var weakAlertController = alertController

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: "Rename"), style: .destructive, handler: { (action) in
            var text = weakAlertController?.textFields?.first?.text
            if(nil != text) {
                text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            if let enteredText = text,!enteredText.isEmpty {
                supportHandler(enteredText)
            }
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.addTextField(configurationHandler: { (textFiled) in
            textFiled.setDefaultStyle(.defaultStyle)
            textFiled.setStyledPlaceHolder(NSLocalizedString("RenameTag", comment: "Rename Tag"), style: .defaultStyle);
            textFiled.setStyledText(renameText)
        })
        viewController?.present(alertController, animated: true, completion: nil)
    }
}
