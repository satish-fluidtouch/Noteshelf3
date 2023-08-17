//
//  FTExternalMediaViewController.swift
//  FTAddOperations
//
//  Created by Siva Kumar Reddy on 29/07/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import UIKit

struct FTTagItem {
    let image: UIImage?
    let name: String
    var showDiscloser: Bool = false
}

protocol FTExternalMediaViewControllerDelegate: AnyObject {
    func didTapAttachmentItem(_ type: AttachmentType)
}

class FTExternalMediaViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

   weak var delegate: FTExternalMediaViewControllerDelegate?
    var dataManager: AddMenuDataManager?

    private var items: [AttachmentItem]? {
        didSet {
            tableView.reloadData()
            tableView.layoutIfNeeded()
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.items = dataManager?.fetchAttachmentItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let vc = self.navigationController?.parent as? FTAddDocumentEntitiesViewController {
            let height = tableView.contentSize.height + FTAddMenuConfig.addMenuTopsegmentHeight
            vc.navigationController?.preferredContentSize = CGSize(width: AddMenuType.externalMedia.contentSize.width, height: height)
        }

        if let indexPath = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

// MARK: - DataSource
extension FTExternalMediaViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: FTAddMenuConfig.cellReuseId)
        if let item = items?[indexPath.row] {
            var config = cell.defaultContentConfiguration().addMenuContentConfig()
            config.image = item.image
            config.text = item.name
            config.image?.withTintColor(UIColor.appColor(.accent))
            cell.contentConfiguration = config
            cell.backgroundColor = UIColor.appColor(.cellBackgroundColor)
            if item.showDiscloser {
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FTAddMenuConfig.rowHeightNormal
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return FTAddMenuConfig.footerHeightNormal
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

//MARK: Delegate
extension FTExternalMediaViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row] {
            self.delegate?.didTapAttachmentItem(item.type)
        }
    }
}
