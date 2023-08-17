//
//  FTAddMenuPageViewController.swift
//  Noteshelf
//
//  Created by srinivas on 01/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTAddMenuPageViewControllerDelegate: AnyObject {
    func didTapPageItem(_ type: FTPageType)
}

class FTAddMenuPageViewController: UIViewController, FTPopoverPresentable {
    @IBOutlet private weak var tableView: UITableView!
    var ftPresentationDelegate = FTPopoverPresentation()
    weak var delegate: FTAddMenuPageViewControllerDelegate?
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    var dataManager: AddMenuDataManager?
    private var items: [[PageItem]]? {
        didSet {
            self.tableView.reloadData()
            tableView.layoutIfNeeded()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.items = dataManager?.fetchPageItems()
        if let vc = self.navigationController?.parent as? FTAddDocumentEntitiesViewController {
            let height = tableView.contentSize.height + FTAddMenuConfig.addMenuTopsegmentHeight 
            let size = CGSize(width: AddMenuType.pages.contentSize.width, height: height)
            vc.navigationController?.preferredContentSize = size
        } else {
            let height = tableView.contentSize.height
            let size = CGSize(width: AddMenuType.pages.contentSize.width, height: height)
            self.navigationController?.preferredContentSize = size
        }
        if delegate is FTFinderViewController {
            topConstraint.constant = 14
            self.view.updateConstraintsIfNeeded()
        }
    }
}

//MARK: - Delegate
extension FTAddMenuPageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let rows = items?[indexPath.section] else {
            return
        }
        let item = rows[indexPath.row]
        self.navigationController?.dismiss(animated: false) { [weak self]  in
            self?.delegate?.didTapPageItem(item.type)
        }
    }
}

extension UIListContentConfiguration {
    func addMenuContentConfig() -> UIListContentConfiguration {
        var content = self
        content.imageProperties.reservedLayoutSize = CGSize(width: 24.0, height: 24.0)
        content.imageProperties.tintColor = UIColor.appColor(.accent)
        content.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 20))
        content.textProperties.font = UIFont.appFont(for: .regular, with: 17.0)
        return content
    }
}

//MARK: - DataSource
extension FTAddMenuPageViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rows = items?[section] {
            return rows.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        if let rows = items?[indexPath.section] {
             let item = rows[indexPath.row]
            var config = cell.defaultContentConfiguration().addMenuContentConfig()
            config.image = item.image
            config.text = item.name
            config.image?.withTintColor(UIColor.appColor(.accent))
            cell.contentConfiguration = config
            cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
            if item.showDiscloser {
                cell.accessoryType = .disclosureIndicator
            }
            if item.type == .newPage || item.type == .chooseTemplate {
                cell.layer.borderColor = UIColor.appColor(.accentBorder).cgColor
                cell.layer.borderWidth = 1.0
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = FTAddMenuConfig.rowHeightNormal
        if let rows = items?[indexPath.section] {
            let item = rows[indexPath.row]
            if item.type == .newPage || item.type == .chooseTemplate {
                height = FTAddMenuConfig.rowHeightLarge
            }
        }
        return height
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var height: CGFloat = FTAddMenuConfig.footerHeightNormal
        if section == 0 {
            height = FTAddMenuConfig.footerHeightSmall
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height = CGFloat.leastNonzeroMagnitude
        if section == 2 {
            height = 20.0
        }
        return height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 20))
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "add.menu.page.background".localized
            label.font = UIFont.appFont(for: .medium, with: 13.0)
            label.textColor = UIColor.appColor(.black50)
            headerView.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0),
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            ])
            return headerView
        }
        return nil
    }
}
