//
//  FTRootViewController_WidgetActions.swift
//  Noteshelf3
//
//  Created by Narayana on 16/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTRootViewController {
    func handleWidgetAction(type: FTWidgetActionType) {
            if type is FTNotebookCreateWidgetActionType {
                self.closeAnyActiveOpenedBook {
                    self.rootContentViewController?.handleWidgetAction(for: type)
                }
            } else {
                if let pathType = type as? FTPinndedWidgetActionType, !pathType.docId.isEmpty {
                    if self.noteBookSplitController == nil {
                        self.openAndperformActionInsidePinnedNotebook(pathType)
                    } else {
                        let docObject = self.noteBookSplitController?.documentViewController?.documentItemObject
                        if let documentId = docObject?.documentUUID , documentId == pathType.docId {
                            if let docVc = self.noteBookSplitController?.documentViewController {
                                docVc.insertNewPageWith(type: pathType)
                            }
                        } else {
                            self.closeAnyActiveOpenedBook {
                                self.openAndperformActionInsidePinnedNotebook(pathType)
                            }
                        }
                    }
                }
            }
    }
}
