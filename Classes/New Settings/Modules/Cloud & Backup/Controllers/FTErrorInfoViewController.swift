//
//  FTErrorInfoViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 02/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

// MARK: This is developed for showing back error message for ignored books
class FTErrorInfoViewController: UIViewController {
    @IBOutlet private weak var infoLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.infoLabel?.text = self.getIgnoredItemsErrorMessage()
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "done".localized, delegate: self)
        self.navigationItem.rightBarButtonItem = rightNavItem
    }

    private func getIgnoredItemsErrorMessage() -> String {
        var errorMsg = ""
        if let ignoredNotebooks = FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList.ignoredItemsForUIDisplay(), !ignoredNotebooks.isEmpty {
            var arrayError: [String] = []
            for ignoreEntry in ignoredNotebooks where ignoreEntry.hideFromUser == false {
                let message = ignoreEntry.ignoreReason
                arrayError.append(message)
            }
            for (index,msg) in arrayError.enumerated() {
                errorMsg.append(msg)
                if index != arrayError.count - 1 {
                    errorMsg.append("\n")
                }
            }
        }
        return errorMsg
    }
}

extension FTErrorInfoViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .right {
            self.dismiss(animated: true)
        }
    }
}
