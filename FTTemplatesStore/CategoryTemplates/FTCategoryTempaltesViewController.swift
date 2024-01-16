//
//  FTCategoryTempaltesViewController.swift
//  TempletesStore
//
//  Created by Siva on 14/02/23.
//

import UIKit
import Combine
import FTCommon

class FTCategoryTempaltesViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tagsView: FTTagsView!

    private var viewModel = FTCategoryTemplatesViewModel()

    private var sectionContainer: StoreSectionContainer!
    private var actionManager: FTStoreActionManager!
    private var categoryTemplate: TemplateInfo!

    class func controller(categoryTemplate: TemplateInfo, actionManager: FTStoreActionManager) -> FTCategoryTempaltesViewController {
        guard let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTCategoryTempaltesViewController") as? FTCategoryTempaltesViewController else {
            fatalError("FTCategoryTempaltesViewController not found")
        }
        vc.categoryTemplate = categoryTemplate
        vc.actionManager = actionManager
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.sectionHeaderTopPadding = 0
        var sections = [FTStoreSectionHandler]()
        categoryTemplate.items?.forEach({ discoveryItem in
            sections.append(TemplatesSectionHandler(actionStream: actionManager.actionStream))
        })
        self.sectionContainer = StoreSectionContainer(handlers: sections)

        viewModel.categoryTemplate = categoryTemplate
        self.title = viewModel.headerTitle

        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tagsView.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let size = self.tagsView.collectionView.contentSize
            self.tableView.tableHeaderView?.frame.size.height = size.height
            self.tableView.tableHeaderView = self.tableView.tableHeaderView
        }
    }

}

// MARK: - Private Methods
private extension FTCategoryTempaltesViewController {
    func setupUI() {
        /// Register TableView Cells
        registerCells()
        /// Configure Tags View
        configureTagsView()
        /// Observers
        observers()
        /// Configure Datasource
        configureDatasource()
        /// reload
        viewModel.reloadTableView()
    }

    func registerCells() {
        FTStorePlannerTableCell.registerWithTable(self.tableView)
        /// Register the custom header view.
        FTStoreHeader.registerWithTable(tableView)
        self.tableView.delegate = self
    }

    func configureTagsView() {
        let tagsConfig = FTTagViewConfiguration(tagBgColor: UIColor.appColor(.secondaryLight), borderColor: .clear)
        tagsConfig.bgColor = .clear
        tagsView.backgroundColor = .clear
        tagsView.delegate = self
        tagsConfig.showContextMenu = false
        tagsView.tagConfiguration = tagsConfig
        let tags = viewModel.tags
        tagsView.items = tags
        self.tagsView.refresh()

        let size = self.tagsView.collectionView.contentSize
        self.tableView.tableHeaderView?.frame.size.height = size.height
    }

    func configureDatasource() {
        viewModel.datasource = CategoryTemplatesDatasource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, packModel in
            var cell = UITableViewCell()
            guard let self = self else {
                cell =  UITableViewCell(style: .default, reuseIdentifier: "cell")
                return cell
            }
            if let templates = packModel.items {
                let cellModel = Discover(displayTitle: packModel.displayTitle, sectionType: 2, rowsCount: 1, type: "", items: templates)
                return self.sectionContainer.tableView(cellModel, tableView, cellForRowAt: indexPath)
            }
            return cell
        })
    }

    func observers() {
        actionManager?.actionStream.sink {[weak self] action in
            guard let self = self else { return }
            switch action {
            case .didTapOnDiscoveryItem(items: let items, selectedIndex: let index):
                let item = items[index] as! DiscoveryItem
                if item.type == FTDiscoveryItemType.category.rawValue {
                    self.navigateToCategory(template: item)
                } else if item.type == FTDiscoveryItemType.templates.rawValue {
                    self.navigateToTempaltesVC(discoveryItem: item)
                } else if item.type == FTDiscoveryItemType.template.rawValue {
                    self.presentTemplatePreviewFor(templates: items, selectedIndex: index)
                }
            }
        }.store(in: &actionManager.cancellables)
    }


    @objc func seeAllAction(_ sender: UIButton) {
        if let sectionItem = viewModel.sectionInfo(at: sender.tag) {
            self.navigateToTempaltesVC(discoveryItem: sectionItem as! DiscoveryItem)
        }
    }

}

// MARK: - UITableViewDelegate
extension FTCategoryTempaltesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // TODO: Move to reusable view
        let sectionItem = viewModel.sectionInfo(at: section)
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                                                                FTStoreHeader.reuseIdentifier) as! FTStoreHeader
        view.seeAllButton.tag = section
        view.seeAllButton.addTarget(self, action: #selector(seeAllAction(_:)), for: .touchUpInside)
        view.titleLabel.text = sectionItem?.title
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 16.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FTStoreConstants.StoreTemplate.size.height + FTStoreConstants.StoreTemplate.extraHeightPadding + FTStoreConstants.StoreTemplate.topBottomInset
    }

}

// MARK: - TagsViewDelegate
extension FTCategoryTempaltesViewController: TagsViewDelegate {
    func didSelectIndexPath(indexPath: IndexPath) {
        let button = UIButton()
        button.tag = indexPath.row
        seeAllAction(button)
    }

    func didAddNewTag(tag: String) {
    }

}

// MARK: - Helper Methods
private extension FTCategoryTempaltesViewController {
    func navigateToCategory(template: DiscoveryItem) {
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTCategoryTempaltesViewController") as? FTCategoryTempaltesViewController {
            vc.categoryTemplate = template
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func navigateToTempaltesVC(discoveryItem: DiscoveryItem) {
        let vc = FTStoreTemplatesViewController.controller(discoveryItem: discoveryItem, actionManager: actionManager)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func presentTemplatePreviewFor(templates: [TemplateInfo], selectedIndex: Int) {
        // TODO: AK
        FTTemplatesPageViewController.presentFromViewController(self, actionManager: actionManager, templates: templates, selectedIndex: selectedIndex)
    }

}
