//
//  UIAlertController+Extension.swift
//  FTCommon
//
//  Created by Narayana on 02/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public extension UIAlertController {
    static func showAlertForNoCamera(from viewController: UIViewController?) {
        let alertController = UIAlertController(title: NSLocalizedString("NoCameraInfo", comment: "Unable to access camera..."), message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil));
        viewController?.present(alertController, animated: true, completion: nil)
    }

    @objc static func showAlert(withTitle title: String, message: String, from viewController: UIViewController?, withCompletionHandler completionHandler: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { (action) in
            if(completionHandler != nil) {
                completionHandler!();
            }
        }));
        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func showConfirmationDialog(with title: String, message: String, from viewController: UIViewController?, okHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { (action) in
            okHandler()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        viewController?.present(alertController, animated: true, completion: nil)
    }
    static func showSupportDialog(with title: String, message: String, from viewController: UIViewController?, supportHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Support", comment: "Support"), style: .default, handler: { (action) in
            supportHandler()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        viewController?.present(alertController, animated: true, completion: nil)
    }
    static func showSetupBackupDialog(with title: String, message: String, from viewController: UIViewController?, completionHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Later", comment: "Later"), style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Setup", comment: "Setup"), style: .default, handler: { (action) in
            completionHandler()
        }))
        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func showSetupAutoBackupDialog(with title: String, message: String, from viewController: UIViewController?, completionHandler: @escaping ((_ isSelecte:Bool) -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Later", comment: "Later"), style: .default, handler: { _ in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Setup", comment: "Setup"), style: .default, handler: { _ in
            completionHandler(true)
        }))
        viewController?.present(alertController, animated: true, completion: nil)
    }

    @objc static func showAlertForImageAnnotationMigration(from viewController: UIViewController?, onCompletion : @escaping (Bool) -> (Void))
    {
        let alertController = UIAlertController(title: NSLocalizedString("ImageEditMigrationAlert", comment: "changes made in earlier version will be lost"), message: "", preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: "Continue"), style: .default, handler: { (_) in
            onCompletion(true)
        }));

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: { (_) in
            onCompletion(false)
        }));

        viewController?.present(alertController, animated: true, completion: nil)
    }

    @objc static func showAlertForiOS12TextAttachmentIssue(from viewController: UIViewController?)
    {
        let alertController = UIAlertController(title: "There is a bug in iOS 12 that is causing the checkbox feature to not function correctly. We are working with Apple to address this. Please refrain from using checkboxes until further notice.", message: nil, preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            UserDefaults.standard.set(true, forKey: "IOS12_Text_Issue_alerted");
            UserDefaults.standard.synchronize();
        }));

        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func showRecoverDialog(with title: String, message: String, from viewController: UIViewController?, okHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Move", comment: "Move"), style: .default, handler: { (action) in
            okHandler()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func showDeleteDialog(with title: String, message: String, from viewController: UIViewController?, supportHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "sidebar.allTags.removeTags.alert.delete".localized, style: .destructive, handler: { (action) in
            supportHandler()
        }))
        alertController.addAction(UIAlertAction(title: "sidebar.allTags.removeTags.alert.cancel".localized, style: .cancel, handler: nil))
        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func showRemoveTagsDialog(with title: String, message: String, from viewController: UIViewController?, supportHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "sidebar.allTags.removeTags.alert.removeTags".localized, style: .destructive, handler: { (action) in
            supportHandler()
        }))
        alertController.addAction(UIAlertAction(title: "sidebar.allTags.removeTags.alert.cancel".localized, style: .cancel, handler: nil))
        viewController?.present(alertController, animated: true, completion: nil)
    }

    static func showTextFieldAlertOn(viewController: UIViewController,
                                      title: String,
                                      message: String = "",
                                      textfieldPlaceHolder: String,
                                      textfieldText: String = "",
                                      submitButtonTitle : String,
                                      cancelButtonTitle: String,
                                      submitAction: @escaping (_ title:String?) -> (),
                                      cancelAction: @escaping () -> ()){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField) in
            textField.placeholder = textfieldPlaceHolder
            textField.text = textfieldText
        }
        let mainAction = UIAlertAction(title: submitButtonTitle, style: .default) { _ in
            let textField = alertController.textFields![0] as UITextField
            submitAction(textField.text)
        }
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .default) { _ in
            cancelAction()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(mainAction)
        viewController.present(alertController, animated:true)
    }

    static func showConfirmationAlert(with title: String, message: String, from viewController: UIViewController?,okButtonTitle: String, cancelButtonTitle: String, okHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { (action) in
            okHandler()
        }))
        alertController.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil))
        viewController?.present(alertController, animated: true, completion: nil)
    }
    static func showNavigateToTemplatesAlert(with title: String, message: String, from viewController: UIViewController?, continueHandler: @escaping (() -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let continueAction = UIAlertAction(title: NSLocalizedString("continue", comment: "continue"), style: .default, handler: { (action) in
            continueHandler()
        })
        alertController.addAction(continueAction)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.preferredAction = continueAction
        viewController?.present(alertController, animated: true, completion: nil)
    }
}
