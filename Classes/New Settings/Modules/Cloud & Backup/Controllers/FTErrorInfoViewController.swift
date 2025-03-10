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
    @IBOutlet private weak var tableView: UITableView?
    private var errorItems = [FTBackupIgnoreEntry]()
    private var lastBackupError: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        if let err = UserDefaults.standard.object(forKey: BACKUP_ERROR) as? String, !err.isEmpty {
            self.lastBackupError = err
        }
        if let items = FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList.ignoredItemsForUIDisplay() {
            self.errorItems = items;
        }
        
        self.tableView?.dataSource = self
        self.tableView?.delegate = self

        self.tableView?.rowHeight = UITableView.automaticDimension
        self.tableView?.estimatedRowHeight = 52
                
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "done".localized, delegate: self)
        self.navigationItem.rightBarButtonItem = rightNavItem
        self.title = "cloud.backup.errors".localized;
    }
}

extension FTErrorInfoViewController: UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections: Int = 1
        if !self.lastBackupError.isEmpty {
            sections = 2
        }
        return sections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var itemCount: Int = 1
        if section == 0 {
            itemCount = self.errorItems.count
        }
        return itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTErrorInfoTableViewCell") ?? UITableViewCell()
        if let errorInfoCell = cell as? FTErrorInfoTableViewCell {
            if indexPath.section == 0 {
                let item = self.errorItems[indexPath.row]
                errorInfoCell.configure(item)
            } else if indexPath.section == 1, !lastBackupError.isEmpty {
                errorInfoCell.configure(for: lastBackupError)
            }
            errorInfoCell.setNeedsUpdateConstraints()
            errorInfoCell.updateConstraintsIfNeeded()
        }
        return cell
    }
}

extension FTErrorInfoViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .right {
            self.dismiss(animated: true)
        }
    }
}

class FTErrorInfoTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel?;
    @IBOutlet private weak var pathLabel: UILabel?;
    @IBOutlet private weak var errorLabel: UILabel?;
    @IBOutlet private weak var errorImageView: UIImageView?;
    
    func configure(_ ignoreEntry: FTBackupIgnoreEntry) {
        self.titleLabel?.text = ignoreEntry.title;
        let displayPath = URL(fileURLWithPath: ignoreEntry.relativePath).relativePathWithOutExtension().deletingLastPathComponent;
        self.pathLabel?.text = displayPath
        self.errorLabel?.text = ignoreEntry.ignoreReason;
        
        if let image = UIImage(systemName: "exclamationmark.triangle.fill") {
            var config = UIImage.SymbolConfiguration(paletteColors: [
                UIColor.white
                ,UIColor.appColor(.secondaryAccent)
            ])
            // Apply a configuration that scales to the system font point size of 42.
            config = config.applying(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20)))
            self.errorImageView?.image = image.applyingSymbolConfiguration(config)
        }
    }

    func configure(for errorMessage: String) {
        self.errorLabel?.text = errorMessage
        if let image = UIImage(systemName: "exclamationmark.circle.fill") {
            var config = UIImage.SymbolConfiguration(paletteColors: [
                UIColor.white
                ,UIColor.appColor(.destructiveRed)
            ])
            // Apply a configuration that scales to the system font point size of 42.
            config = config.applying(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20)))
            self.errorImageView?.image = image.applyingSymbolConfiguration(config)
        }
    }
}
