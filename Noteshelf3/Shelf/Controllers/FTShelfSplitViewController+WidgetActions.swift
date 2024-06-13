//
//  FTShelfSplitViewController+WidgetActions.swift
//  Noteshelf3
//
//  Created by Narayana on 16/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShelfSplitViewController {
    func handleWidgetAction(for type: FTWidgetActionType) {
        if self.checkIfGlobalSearchControllerExists() {
            self.exitFromGlobalSearch {
                executeAction()
            }
        } else {
            executeAction()
        }

        func executeAction() {
            switch type {
            case FTNotebookCreateWidgetActionType.quickNote:
                if let currentShelfViewModel , !currentShelfViewModel.collection.isStarred, !currentShelfViewModel.collection.isTrash {
                    currentShelfViewModel.quickCreateNewNotebook()
                } else {
                    FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { [weak self] collection in
                        if let unfiledCollection = collection {
                            self?.createNewNotebookInside(collection: unfiledCollection, group: nil, notebookDetails: nil, isQuickCreate: true, onCompletion: { error, shelfItem in
                            })
                        }
                    }
                }
            case FTNotebookCreateWidgetActionType.newNotebook:
                self.showNewBookPopverOnShelf()
            case FTNotebookCreateWidgetActionType.audioNote:
                if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
                    FTIAPurchaseHelper.shared.showIAPAlert(on: self);
                    return
                }
                self.createAudioNotebook()

            case FTNotebookCreateWidgetActionType.scan:
                if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
                    FTIAPurchaseHelper.shared.showIAPAlert(on: self)
                    return
                }
                let scanService = FTScanDocumentService.init(delegate: self)
                scanService.startScanningDocument(onViewController: self)

            case FTNotebookCreateWidgetActionType.search:
                self.navigateToGlobalSearch()

            default:
                break
            }
            if let _type = type as? FTNotebookCreateWidgetActionType {
                track(_type.eventName, params: ["action": _type.parameterName])
            }
        }
    }
}
