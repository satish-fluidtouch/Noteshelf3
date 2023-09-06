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
    @IBOutlet private weak var tableView: UITableView!
    internal let ignoredItems = FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList.ignoredItemsForUIDisplay() ?? []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Errors"
        self.tableView.isHidden = ignoredItems.isEmpty
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "done".localized, delegate: self)
        self.navigationItem.rightBarButtonItem = rightNavItem
    }
}

extension FTErrorInfoViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .right {
            self.dismiss(animated: true)
        }
    }
}

extension FTErrorInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ignoredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FTErrorInfoTableViewCell", for: indexPath) as? FTErrorInfoTableViewCell else {
            fatalError("Programmer error, unable to find FTErrorInfoTableViewCell")
        }
        cell.configureErrorInfo(with: ignoredItems[indexPath.row])
        return cell
    }
}
