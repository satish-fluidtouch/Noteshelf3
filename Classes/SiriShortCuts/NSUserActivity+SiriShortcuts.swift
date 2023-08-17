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

public let createNotebookActivityTypeIdentifier = "com.fluidtouch.noteshelf.createNotebook"
public let createAudioNoteActivityTypeIdentifier = "com.fluidtouch.noteshelf.createAudioNote"
public let openNotebookActivityTypeIdentifier = "com.fluidtouch.noteshelf.openNotebook"

extension NSUserActivity {
    
    public enum SiriShortcutActivity {
        case createNotebook
        case createAudioNotebook
        case openNotebook([String : AnyObject])
    }
    
    public convenience init(siriShortcutActivity: SiriShortcutActivity) {
        switch siriShortcutActivity {
        case .openNotebook(let notebook):
            self.init(activityType: openNotebookActivityTypeIdentifier)
            self.isEligibleForPrediction = true
            self.isEligibleForSearch = true
            let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
            let data = notebook["coverImage"] as! Data
            attributes.thumbnailData = data
            self.contentAttributeSet = attributes
            self.referrerURL = notebook["notebookURL"] as? URL
            userInfo = ["uuid" : notebook["uuid"] as! String]
            title = notebook["title"] as? String
            let persistentIdentifier = NSUserActivityPersistentIdentifier((notebook["uuid"] as? String)!)
            self.persistentIdentifier = persistentIdentifier
            requiredUserInfoKeys = NSSet(array: ["persistentIdentifier" ,"userInfo" , "notebookURL" ]) as! Set<String>
            suggestedInvocationPhrase = String.init(format: NSLocalizedString("OpenNotebook", comment: "Open %@"), notebook["title"] as! String)
            
        case .createNotebook:
            self.init(activityType: createNotebookActivityTypeIdentifier)
            self.title = NSLocalizedString("CreateANotebook", comment: "Create a notebook")
            suggestedInvocationPhrase = NSLocalizedString("CreateANotebook", comment: "Create a notebook")
            self.isEligibleForPrediction = true
        case .createAudioNotebook:
            self.init(activityType: createAudioNoteActivityTypeIdentifier)
            self.title = NSLocalizedString("CreateAudioNoteSiriMessage", comment: "Create a new audio note")
            suggestedInvocationPhrase = NSLocalizedString("CreateAudioNote", comment: "Record Audio")
            self.isEligibleForPrediction = true
        }
    }
    

    public var siriShortcutActivity: SiriShortcutActivity? {
        switch activityType {
        case openNotebookActivityTypeIdentifier:
//            guard let notebookURL = userInfo?["notebookURL"] as? String else {
//                return nil
//            }
            guard let notebookURL = referrerURL else {
                    return nil
                }
            return .openNotebook(["notebookURL" : notebookURL as AnyObject])
            
        case createNotebookActivityTypeIdentifier:
            return .createNotebook
            
        case createAudioNoteActivityTypeIdentifier:
            return .createAudioNotebook
        default:
            return nil
        }
    }
    
    
}
