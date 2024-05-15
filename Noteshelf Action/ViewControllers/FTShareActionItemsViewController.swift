//
//  FTShareActionItemsViewController.swift
//  Noteshelf Action
//
//  Created by Sameer on 15/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTShareActionItemsViewController: UIViewController {
    @IBOutlet var tableView: UITableView?
    var type = FTShareItemType.category
    @IBOutlet weak var createButton: UIButton!
    var currentItemModel: FTShareItemsFetchModel?
    var selectedShareItem: FTShareItem?
    var arrayOfItems = [[FTShareItem]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBar()
        createButton.isHidden = true
        buildDataAndReload()
        createButton.layer.cornerRadius = 12
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "standardCell")
        tableView?.sectionHeaderTopPadding = 0
        createButton.titleLabel?.font = UIFont.clearFaceFont(for: .medium, with: 20)
        if currentItemModel?.collection == nil {
            self.navigationItem.title = "Notebook".localized
        } else {
            self.navigationItem.title = currentItemModel?.collection?.title ?? "Notebook".localized
        }
    }
    
    private func configureNavigationBar() {
        self.navigationItem.hidesBackButton = false
        let rightBarButton = UIBarButtonItem(title: "Done".localized, style: .plain, target: self, action: #selector(doneTapped))
        rightBarButton.setTitleTextAttributes([.font: UIFont.appFont(for: .regular, with: 17)], for: .normal)
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    @objc func doneTapped()  {
        self.extensionContext?.completeRequest(returningItems: self.extensionContext?.inputItems, completionHandler: nil)
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        if let vcs = self.navigationController?.viewControllers, let firstVc = vcs.first as? FTShareActionViewController {
            firstVc.selectedItem = self.currentItemModel
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func buildDataAndReload() {
        if let itemsFetchModel = currentItemModel {
            if itemsFetchModel.type == .category {
                itemsFetchModel.fetchUserCategories {[weak self] items in
                    guard let self = self else {
                        return
                    }
                    let defaultShareItems = items.filter({ eachItem in
                        return eachItem.collection?.isUnfiledNotesShelfItemCollection ?? false
                    })
                    if !defaultShareItems.isEmpty {
                        self.arrayOfItems.append(defaultShareItems)
                    }
                    let shareItems = items.filter({ eachItem in
                        return !(eachItem.collection?.isUnfiledNotesShelfItemCollection ?? false)
                    })
                    if !shareItems.isEmpty {
                        self.arrayOfItems.append(shareItems)
                        self.createButton.isHidden = (self.arrayOfItems.count == 1) ? false : true
                    }
                    self.tableView?.reloadData()
                }
            } else if itemsFetchModel.type == .noteBook || itemsFetchModel.type == .group {
                itemsFetchModel.fetchShelfItems { items in
                    self.arrayOfItems.append(items)
                    self.createButton.isHidden = (self.arrayOfItems.count == 1) ? false : true
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
}

extension FTShareActionItemsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.arrayOfItems.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "CATEGORIES".localized
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if currentItemModel?.collection != nil {
            return 0
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayOfItems[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if currentItemModel?.collection != nil {
            return 64
        }
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.arrayOfItems[indexPath.section][indexPath.row]
        if currentItemModel?.collection == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "standardCell", for: indexPath) as UITableViewCell
            var config = cell.defaultContentConfiguration()
            config.text = item.title
            config.textProperties.font = UIFont.appFont(for: .regular, with: 17)
            config.image = item.fetchImage()
            config.imageProperties.tintColor = UIColor.appColor(.accent)
            config.textProperties.color = .label
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            return cell
        } else {
            if let shareItemCell = tableView.dequeueReusableCell(withIdentifier: "FTShareItemTableViewCell", for: indexPath) as? FTShareItemTableViewCell {
                shareItemCell.selectionStyle = .none
                shareItemCell.configureCell(item: item, indexPath: indexPath, shouldDisable: hasAnyNoteshelfFiles())
                return shareItemCell
            }
        }
        return UITableViewCell()
    }
    
    func hasAnyNoteshelfFiles() -> Bool {
        if let vcs = self.navigationController?.viewControllers, let firstVc = vcs.first as? FTShareActionViewController {
            return firstVc.hasAnyNoteshelfFiles()
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.arrayOfItems[indexPath.section][indexPath.row]
        if item.itemType == .noteBook {
            // select notebook to import
            self.selectedShareItem = item
            let model = FTShareItemsFetchModel()
            model.collection = item.collection
            model.noteBook = item.shelfItem
            model.type = item.itemType
            if let vcs = self.navigationController?.viewControllers, let firstVc = vcs.first as? FTShareActionViewController {
                firstVc.selectedItem = model
            }
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            self.navigate(with: item)
        }
    }
    
    func navigate(with item: FTShareItem) {
        let storyboard = UIStoryboard(name: "MainInterface", bundle: Bundle(for: FTShareActionItemsViewController.self))
        guard let vc = storyboard.instantiateViewController(withIdentifier: "FTShareActionItemsViewController") as? FTShareActionItemsViewController else {
            fatalError("Could not find FTShareActionItemsViewController")
        }
        let model = FTShareItemsFetchModel()
        if item.itemType == .category {
            model.type = .noteBook
            model.collection = item.collection
        } else if item.itemType == .group {
            model.type = .noteBook
            model.collection = item.collection
            model.group = item.shelfItem as? FTGroupItemProtocol
        }
        vc.currentItemModel = model
        self.navigationItem.backButtonTitle = "Back".localized
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
