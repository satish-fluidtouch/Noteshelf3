//
//  FTAudioPlayerController_Extension.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/12/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
#if targetEnvironment(macCatalyst)
extension FTAudioPlayerController: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider : ([UIMenuElement]) -> UIMenu? = {[weak self] _ in
            return self?.getContextMenu()
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}
#endif

extension FTAudioPlayerController {
    @objc func configureMoreButton(_ button : UIButton) {
        var actions = [UIMenuElement]()
        let speedAction = FTAudioMoreOption.speed.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        let jumpToPageAction = FTAudioMoreOption.jumpToPage.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        let renameAction = FTAudioMoreOption.rename.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        let goToRecordingAction = FTAudioMoreOption.goToRecording.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        let shareAction = FTAudioMoreOption.share.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        let deleteAction = FTAudioMoreOption.delete.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        let closeAction = FTAudioMoreOption.close.actionElment {[weak self] action in
            self?.didTapOption(identifier: action.identifier.rawValue, button: button)
        }
        if isRegularClass() && isExpanded {
            actions.append(contentsOf: [jumpToPageAction, renameAction, goToRecordingAction, shareAction, deleteAction])
        } else {
            actions.append(UIMenu(options: .displayInline, children: [speedAction,jumpToPageAction, renameAction, goToRecordingAction, shareAction, deleteAction]))
            actions.append(UIMenu(options: .displayInline, children: [closeAction]))
        }
        
        button.menu = UIMenu(children: actions)
        button.showsMenuAsPrimaryAction = true
        self.updateSpeedIcon(button)
    }
    
    func didTapOption(identifier: String, button: UIButton) {
        let option = FTAudioMoreOption(rawValue: identifier)
        switch option {
        case .jumpToPage:
            self.delegate.audioPlayer?(self, navigateTo: self.annotation)
        case .rename:
            if let parent = self.parent {
                UIAlertController.showTextFieldAlertOn(viewController: parent, title: "Audio Title", textfieldPlaceHolder: "Title", textfieldText: self.annotation.audioName, submitButtonTitle: "Rename", cancelButtonTitle: "Cancel") { title in
                    let text = title?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
                    if self.annotation.audioName != title {
                        self.delegate.audioPlayer?(self, didChangeTitle: text, for: self.annotation)
                    }
                } cancelAction: {
                    
                }
            }
        case .goToRecording:
            if let page = annotation.associatedPage {
                var audioAnnotations = [FTAudioAnnotation]()
                let annotations = page.audioAnnotations().map { eachAnn in
                    return eachAnn as! FTAudioAnnotation
                }
                audioAnnotations.append(contentsOf: annotations)
                FTAudioTrackController.showAsPopover(fromSourceView: button, overViewController: self, with: CGSize(width: 330, height: 290),  annotations: audioAnnotations, mode: .notebook, selectedAnnotation: self.annotation)
            }
            
        case .share:
            let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
            if(self.recordingModel == audioSession?.audioRecording) {
                audioSession?.resetSession();
            }
            if let audioAnnotation = self.annotation {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: FTAudioAnnotationExportNotification)
                    , object: nil
                    , userInfo: [
                        "annotation" : audioAnnotation
                        , "frame" : NSValue.init(cgRect: self.view.frame)
                    ]
                )
            }
        case .delete:
            let audioSession = FTAudioSessionManager.sharedSession()?.activeSession()
            if(self.recordingModel == audioSession?.audioRecording) {
                audioSession?.resetSession();
            }
            self.delegate.audioPlayer?(self, delete: self.annotation)
        case .close:
            self.stopPlayOrRecording()
            self.delegate.audioPlayerDidClose?(self)
        case .speed:
            self.applyRate()
            self.updateSpeedIcon(button)
        case .none:
            print("None")
        }
    }
    
    @objc func updateSpeedIcon(_ button: UIButton) {
        if let menu = button.menu?.children.first as? UIMenu {
            let elements = menu.children
            if let speedAction = elements.first(where: { eachElement in
                if let element = eachElement as? UIAction, element.identifier.rawValue == FTAudioMoreOption.speed.rawValue
                {
                    return true
                } else {
                    return false
                }
            }) as? UIAction {
                speedAction.image = imageForSpeed()
            }
        }
    }
    
     func imageForSpeed() -> UIImage? {
        var image = UIImage(named: "normal")
        if self.playbackRate == KSlowRate {
            image = UIImage(named: "slow")
        } else if self.playbackRate == KNormalRate {
             image = UIImage(named: "normal")
        } else if self.playbackRate == KFastRate {
            image = UIImage(named: "fast")
        } else if self.playbackRate == KDoubleRate {
            image = UIImage(named: "double")
        }
        return image?.withTintColor(.label)
    }
}
