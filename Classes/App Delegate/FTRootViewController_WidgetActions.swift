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
        self.closeAnyActiveOpenedBook {
            if type is FTNotebookCreateWidgetActionType {
                self.rootContentViewController?.handleWidgetAction(for: type)
            } else {
                if let pathType = type as? FTPinndedWidgetActionType {
                    print("zzzz - pinned widget - path: \(pathType.relativePath)")
                    self.openAndperformActionInsidePinnedNotebook(pathType)
                }
            }
        }
    }
}
