//
//  NSUserActivity+SiriShortcuts.swift
//  Noteshelf
//
//  Created by Dev_Guest on 12/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import CoreSpotlight
import CoreServices

extension NSUserActivity {
    
    public enum SiriShortcutActivity {
        case createNotebook
        case createAudioNotebook
        case openNotebook([String : AnyObject])

        var identifier: String {
            guard let bundleId = Bundle.main.bundleIdentifier else {
                fatalError("Where's the bundle id?")
            }
            switch self {
            case .createNotebook:
                return bundleId+".createNotebook"
            case .createAudioNotebook:
                return bundleId+".createAudioNote"
            case .openNotebook(_):
                return bundleId+".openNotebook"
            }
        }

    }
    
    public convenience init(siriShortcutActivity: SiriShortcutActivity) {
        switch siriShortcutActivity {
        case .openNotebook(let notebook):
            self.init(activityType: siriShortcutActivity.identifier)
            self.isEligibleForPrediction = true
            self.isEligibleForSearch = true
            let attributes = CSSearchableItemAttributeSet(itemContentType: UTType.item.identifier)
            let data = notebook["coverImage"] as! Data
            attributes.thumbnailData = data
            self.contentAttributeSet = attributes
            self.referrerURL = notebook["notebookURL"] as? URL
            userInfo = ["uuid" : notebook["uuid"] as! String]
            title = notebook["title"] as? String
            let persistentIdentifier = NSUserActivityPersistentIdentifier((notebook["uuid"] as? String)!)
            self.persistentIdentifier = persistentIdentifier
            requiredUserInfoKeys = NSSet(array: ["persistentIdentifier" ,"userInfo" , "notebookURL" ]) as? Set<String>
            suggestedInvocationPhrase = String.init(format: NSLocalizedString("OpenNotebook", comment: "Open %@"), notebook["title"] as! String)
            
        case .createNotebook:
            self.init(activityType: siriShortcutActivity.identifier)
            self.title = NSLocalizedString("CreateANotebook", comment: "Create a notebook")
            suggestedInvocationPhrase = NSLocalizedString("CreateANotebook", comment: "Create a notebook")
            self.isEligibleForPrediction = true
        case .createAudioNotebook:
            self.init(activityType: siriShortcutActivity.identifier)
            self.title = NSLocalizedString("CreateAudioNoteSiriMessage", comment: "Create a new audio note")
            suggestedInvocationPhrase = NSLocalizedString("CreateAudioNote", comment: "Record Audio")
            self.isEligibleForPrediction = true
        }
    }
    

    public var siriShortcutActivity: SiriShortcutActivity? {
        switch activityType {
        case SiriShortcutActivity.openNotebook([:]).identifier:
            guard let notebookURL = referrerURL else {
                    return nil
                }
            return .openNotebook(["notebookURL" : notebookURL as AnyObject])
            
        case SiriShortcutActivity.createNotebook.identifier:
            return .createNotebook
            
        case SiriShortcutActivity.createAudioNotebook.identifier:
            return .createAudioNotebook
        default:
            return nil
        }
    }
    
    
}
