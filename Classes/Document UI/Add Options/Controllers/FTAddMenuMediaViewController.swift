//
//  FTAddMenuMediaViewController.swift
//  Noteshelf
//
//  Created by srinivas on 30/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTAddMenuMediaViewControllerDelegate: AnyObject {
    func didTapMediaItem(_ item: MediaType)
}

class FTAddMenuMediaViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    var dataManager: AddMenuDataManager?

    weak var mediaDelegate: FTAddMenuMediaViewControllerDelegate?
    weak var ftPHPickerDelegare: FTAddMenuPHPickerDelegate?
    weak var cameraDelegate: FTAddMenuCameraDelegate?

    private var items: [[MediaItem]]? {
        didSet {
            tableView.reloadData()
            tableView.layoutIfNeeded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.items = dataManager?.fetchMediaItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let vc = self.navigationController?.parent as? FTAddDocumentEntitiesViewController {
            let height = tableView.contentSize.height + FTAddMenuConfig.addMenuTopsegmentHeight
            vc.navigationController?.preferredContentSize = CGSize(width: AddMenuType.media.contentSize.width, height: height)
        }

        if let indexPath = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

//MARK: - Delegate
extension FTAddMenuMediaViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let rows = items?[indexPath.section] else {
            return
        }
        let item = rows[indexPath.row]
        if item.type == .photo {
            ftPHPickerDelegare?.didSelectPhotoLibrary(menuItem: .photoLibrary)
        } else if item.type == .camera {
            cameraDelegate?.didSelectCamera(.takePhoto)
        } else {
            mediaDelegate?.didTapMediaItem(item.type)
        }
        FTNotebookEventTracker.trackNotebookEvent(with: item.type.eventName)
    }
}

//MARK: - DataSource
extension FTAddMenuMediaViewController: UITableViewDataSource {
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
        let cell = UITableViewCell(style: .default, reuseIdentifier: FTAddMenuConfig.cellReuseId)
        if let rows = items?[indexPath.section] {
            let item = rows[indexPath.row]
            var config = cell.defaultContentConfiguration().addMenuContentConfig()
            config.image = item.image
            config.text = item.name
            config.image?.tint(with: UIColor.appColor(.accent))
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
