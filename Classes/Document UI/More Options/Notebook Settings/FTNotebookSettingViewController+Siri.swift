//
//  FTNotebookSettingViewController+Siri.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 31/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import IntentsUI
import FTCommon

extension FTNoteBookSettingsViewController: INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {

     func updateSiriShortcutSetting(with shortcut: INVoiceShortcut?) {
        self.siriShortcut = shortcut
        tableView?.reloadData()
    }

     func handleSiriSetting() {
        #if NOTESHELF_RETAIL_DEMO
        UIAlertController.showDemoLimitationAlert(withMessageID: "SiriShortcutLimitation", onController: self)
        return;
        #endif
        FTPermissionManager.askForSiriPermission(onController: self, shouldForce: true, completion: { [weak self] isSuccess in
            if isSuccess {
                if let voiceShortcut = self?.siriShortcut {
                    self?.editSiriShortcut(shortcut: voiceShortcut)
                } else if let notebookDocument = self?.notebookDocument, let notebookShelfItem = self?.notebookShelfItem {
                    if let image = notebookDocument.shelfImage, let data = image.pngData() {
                        let activity = NSUserActivity(siriShortcutActivity:
                            .openNotebook(["coverImage": data as AnyObject,
                                           "notebookURL": notebookDocument.URL as AnyObject,
                                           "title": notebookShelfItem.displayTitle as AnyObject,
                                           "uuid": notebookDocument.documentUUID as AnyObject]))

                        self?.userActivity = activity
                        self?.userActivity?.becomeCurrent()
                        let shortcut = INShortcut(userActivity: activity)
                        #if !targetEnvironment(macCatalyst)
                        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                        viewController.modalPresentationStyle = .overFullScreen
                        viewController.delegate = self
                        self?.present(viewController, animated: true, completion: nil)
                        #endif
                    }
                }
            }
        })

    }

    func checkSiriAuthorizationStatus(completion:@escaping (_ isSuccess: Bool) -> Void) {
        let siriStatus = INPreferences.siriAuthorizationStatus()
        if siriStatus == .authorized {
            completion(true)
        } else if siriStatus == .notDetermined {
            INPreferences.requestSiriAuthorization { status in
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        } else {
            completion(false)
            let message = String(format: NSLocalizedString("SiriPermissionPopupMsg", comment: "Please allow to access..."), applicationName()!, applicationName()!);
            UIAlertController.showAlert(withTitle: "", message: message, from: self, withCompletionHandler: nil)
        }
    }

    func editSiriShortcut(shortcut: INVoiceShortcut) {
        #if !targetEnvironment(macCatalyst)
        let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: shortcut)
        viewController.modalPresentationStyle = .overFullScreen
        viewController.delegate = self
        self.present(viewController, animated: true, completion: nil)
        #endif
    }

    func isSiriShortcutAvailable(for item: FTShelfItemProtocol, completion:@escaping (_ voiceShortcut: INVoiceShortcut?) -> Void) {
        if let uuid = (item as? FTDocumentItemProtocol)?.documentUUID {
            FTSiriShortcutManager.shared.getShortcutForUUID(uuid) {  error, voiceShortcut in
                runInMainThread({
                    completion(voiceShortcut)
                })
            }
        }
    }

    // MARK: - Add To Siri
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error1 = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error1.debugDescription)")
        } else {
            updateSiriShortcutSetting(with: voiceShortcut)
        }

        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - Edit Siri
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        } else {
            updateSiriShortcutSetting(with: voiceShortcut)
        }

        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        updateSiriShortcutSetting(with: nil)
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
