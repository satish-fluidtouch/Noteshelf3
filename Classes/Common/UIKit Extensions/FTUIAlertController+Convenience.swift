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

    static func showAlertForPageNotAvailable(from controller: UIViewController, completionHandler: ((Bool) -> Void)?) {
        let alertController = UIAlertController(title: "textLink_pageDeleted_title".localized, message: "textLink_pageNotAvailable".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok".localized, style: .default) { _ in
            completionHandler?(true)
        }
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }

    static func showAlertForPageNotAvailableAndSuggestToFirstPage(from controller: UIViewController, notebookTitle: String, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "textLink_pageDeleted_title".localized, message: "textLink_otherbook_firstPageConfirmation_message".localized , preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes".localized, style: .default) { _ in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in
            completionHandler(false)
        }
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        controller.present(alertController, animated: true, completion: nil)
    }

    static func showDocumentNotAvailableAlert(from controller: UIViewController) {
        let alertController = UIAlertController(title: "textLink_documentDeleted_title".localized, message: "textLink_documentItselfNotAvailable_message".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok".localized, style: .default) { _ in
        }
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }

    static func showDeletedOrUndownloadedAlert(for url: URL, from controller: UIViewController) {
        let alertController = UIAlertController(title: "textLink_notebookUnavailable".localized, message: "textLink_notebookDeletedOrUndownloaded".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok".localized, style: .default) { _ in
        }
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }

    static func showDocumentNotDownloadedAlert(for url: URL, from controller: UIViewController) {
        let alertController = UIAlertController(title: "textLink_notebookUnavailable".localized, message: "textLink_notebookNotDownloadedMessage".localized, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok".localized, style: .default) { _ in
            do {
                try FileManager().startDownloadingUbiquitousItem(at: url)
            }
            catch let nserror as NSError {
                FTCLSLog("Book url: \(url): Download Failed :\(nserror.description)")
                FTLogError("Notebook download failed", attributes: nserror.userInfo)
            }
        }
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }

    static func handleNewDocumentOpenAlert(title: String, pageNumber: Int, from controller: UIViewController, onCompletion: @escaping ((Bool) -> Void)) {
        let title = String(format: "textLink_continueConfirmation".localized, title)
        let alertController = UIAlertController(title: title, message: "textLink_closingCurrentDocument_title".localized, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes".localized, style: .default) { _ in
            onCompletion(true)
        }
        let noAction = UIAlertAction(title: "No".localized, style: .cancel) { _ in
            onCompletion(false)
        }
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        controller.present(alertController, animated: true, completion: nil)
    }

    static func showBrokenLinkAlert(from controller: UIViewController) {
        let alertController = UIAlertController(title: "textLink_brokenLink_message".localized, message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok".localized, style: .cancel) { _ in
        }
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }
}
