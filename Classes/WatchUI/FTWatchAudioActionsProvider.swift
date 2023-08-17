//
//  FTWatchAudioOptionsProvider.swift
//  Noteshelf
//
//  Created by Simhachalam on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc enum FTAudioActionContext:Int{
    case shelf
    case insideNotebook
}
//=========================================
@objc enum FTAudioActionType:Int{
    case createNotebook
    case addToNotebook
    case addToNewPage
    case addToCurrentPage
    case exportAudio
    case markAsUsed
    case markAsUnused
    case deleteRecording
}
//=========================================
@objc enum FTAudioActionStyle:Int{
    case regular
    case destructive
}
extension FTAudioActionStyle{

    func alertActionStyle()->UIAlertAction.Style{
        if(self == .regular){
            return UIAlertAction.Style.default
        }
        else if(self == .destructive){
            return UIAlertAction.Style.destructive
        }
        return UIAlertAction.Style.default
    }
}
//=========================================
class FTAudioAction:NSObject{
    var displayTitle:String!
    var actionStyle:FTAudioActionStyle!
    var actionType:FTAudioActionType!
    
    class func audioActionForType(_ actionType:FTAudioActionType) -> FTAudioAction{
        
        var newAudioAction : FTAudioAction!
        switch actionType {
            
        case .createNotebook:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("CreateNotebook", comment: "Create Notebook"), actionStyle: FTAudioActionStyle.regular, actionType: .createNotebook)
            break;
        case .addToNotebook:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("AddToNotebook", comment: "Add to Notebook"), actionStyle: FTAudioActionStyle.regular, actionType: .addToNotebook)
            break;
        case .addToNewPage:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("AddToNewPage", comment: "Add to New Page"), actionStyle: FTAudioActionStyle.regular, actionType: .addToNewPage)

            break;
        case .addToCurrentPage:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("AddToCurrentPage", comment: "Add to Current Page"), actionStyle: FTAudioActionStyle.regular, actionType: .addToCurrentPage)

            break;
        case .exportAudio:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("Export", comment: "Export"), actionStyle: FTAudioActionStyle.regular, actionType: .exportAudio)

            break;
        case .markAsUsed:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("MarkAsUsed", comment: "Mark as Used"), actionStyle: FTAudioActionStyle.regular, actionType: .markAsUsed)

            break;
        case .markAsUnused:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("MarkAsUnused", comment: "Mark as Unused"), actionStyle: FTAudioActionStyle.regular, actionType: .markAsUnused)

            break;
        case .deleteRecording:
            newAudioAction = FTAudioAction.init(displayTitle: NSLocalizedString("Delete", comment: "Delete"), actionStyle: FTAudioActionStyle.destructive, actionType: .deleteRecording)

            break;
        }
        return newAudioAction
    }
    public init(displayTitle: String, actionStyle:FTAudioActionStyle, actionType:FTAudioActionType) {
        self.displayTitle = displayTitle
        self.actionStyle = actionStyle
        self.actionType = actionType
        super.init()
    }
}
//=========================================
class FTWatchAudioActionsProvider: NSObject {
    func actionsForAudio(_ audioFile:FTWatchRecordedAudio?, actionContext:FTAudioActionContext) -> [FTAudioAction]{
        var audioActions:[FTAudioAction]! = []
        
        if(actionContext == .shelf){
            audioActions.append(FTAudioAction.audioActionForType(.createNotebook))
//            audioActions.append(FTAudioAction.audioActionForType(.addToNotebook))
            audioActions.append(FTAudioAction.audioActionForType(.exportAudio))

            if(audioFile != nil){
                if(audioFile?.audioStatus == .unread){
                    audioActions.append(FTAudioAction.audioActionForType(.markAsUsed))
                }
                else
                {
                    audioActions.append(FTAudioAction.audioActionForType(.markAsUnused))
                }
            }
            audioActions.append(FTAudioAction.audioActionForType(.deleteRecording))
        }
        else
        {
            audioActions.append(FTAudioAction.audioActionForType(.addToNewPage))
            audioActions.append(FTAudioAction.audioActionForType(.addToCurrentPage))
            audioActions.append(FTAudioAction.audioActionForType(.exportAudio))
            
            if(audioFile != nil){
                if(audioFile?.audioStatus == .unread){
                    audioActions.append(FTAudioAction.audioActionForType(.markAsUsed))
                }
                else
                {
                    audioActions.append(FTAudioAction.audioActionForType(.markAsUnused))
                }
            }
            audioActions.append(FTAudioAction.audioActionForType(.deleteRecording))
        }
        return audioActions
    }
}
