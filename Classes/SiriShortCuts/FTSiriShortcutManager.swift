//
//  FTSiriShortcutManager.swift
//  Noteshelf
//
//  Created by Matra on 06/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import IntentsUI
import FTCommon


class FTSiriShortcutManager: NSObject {
    
    static let shared = FTSiriShortcutManager()
    
    func getShortcutForUUID(_ uuid : String , completion : @escaping ((Error? , INVoiceShortcut?) -> Void)) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcuts, error) in
            if voiceShortcuts != nil {
                let filteredData = voiceShortcuts!.filter{ $0.shortcut.userActivity?.userInfo!["uuid"] as? String == uuid }
                if !filteredData.isEmpty {
                    completion(error , filteredData.first)
                }else{
                    completion(error , nil)
                }
            }else{
                completion(error , nil)
            }
        }
    }
    
    func removeShortcutSuggestionForUUID(_ uuid : String) {
        let persistentIdentifier = NSUserActivityPersistentIdentifier(uuid)
        NSUserActivity.deleteSavedUserActivities(withPersistentIdentifiers: [persistentIdentifier]) {
            
        }
    }
}
extension FTSiriShortcutManager {
    func handleCreateSiriShortCut(for item: FTShelfItemProtocol, onController: UIViewController?) {
        FTSiriShortcutManager.isSiriShortcutAvailable(for: item) {[weak self] (voiceShortcut) in
            if let shortcut = voiceShortcut {
                self?.editSiriShortcut(for: shortcut, onController: onController)
            }
            else {
                self?.createSiriShortcut(for: item, onController: onController)
            }
        }

    }
    
    class func isSiriShortcutAvailable(for item: FTShelfItemProtocol ,completion:@escaping (_ voiceShortcut: INVoiceShortcut?) -> Void) {
        if let uuid = (item as? FTDocumentItemProtocol)?.documentUUID {
            FTSiriShortcutManager.shared.getShortcutForUUID(uuid) {  (_, voiceShortcut) in
                completion(voiceShortcut)
            }
        }
    }
    
    func createSiriShortcut(for item:FTShelfItemProtocol, onController: UIViewController?) {
        var currentID: String?;
        currentID = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item) { image,tokenID  in
            if tokenID == currentID
                , let shelfImage = image
                , let imageData = shelfImage.pngData()
                , let uuid = (item as? FTDocumentItemProtocol)?.documentUUID
            {
                runInMainThread {
                    let activity = NSUserActivity(siriShortcutActivity: .openNotebook(["coverImage" : imageData as AnyObject , "notebookURL" : item.URL as AnyObject , "title" : item.displayTitle as AnyObject , "uuid" : uuid as AnyObject]))
                    let shortcut = INShortcut(userActivity: activity)
                    #if !targetEnvironment(macCatalyst)
                    let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                    viewController.modalPresentationStyle = .overFullScreen
                    viewController.delegate = self
                    onController?.present(viewController, animated: true, completion: nil)
                    #endif
                }
            }
        }
    }
    
    func editSiriShortcut(for voiceShortcut: INVoiceShortcut, onController: UIViewController?) {
        runInMainThread {
            #if !targetEnvironment(macCatalyst)
            let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
            viewController.modalPresentationStyle = .overFullScreen
            viewController.delegate = self
            onController?.present(viewController, animated: true, completion: nil)
            #endif
        }
    }
}


extension FTSiriShortcutManager: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        }else if let shortcut = voiceShortcut{
            print("Shortcut added successfully", shortcut.invocationPhrase)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension FTSiriShortcutManager: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        } else if let shortcut = voiceShortcut {
            print("Shortcut edited successfully", shortcut.invocationPhrase)
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
