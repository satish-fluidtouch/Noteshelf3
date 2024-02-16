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
        switch type {
        case FTNotebookCreateWidgetActionType.quickNote:
            self.currentShelfViewModel?.quickCreateNewNotebook()

        case FTNotebookCreateWidgetActionType.newNotebook:
            self.currentShelfViewModel?.showNewNotebookPopover()

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
            if self.checkIfGlobalSearchControllerExists() {
                self.exitFromGlobalSearch()
            }
            self.navigateToGlobalSearch()

        default:
            break
        }
    }
}
