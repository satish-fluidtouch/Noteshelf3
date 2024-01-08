//
//  FTStoreViewController.swift
//  TempletesStore
//
//  Created by Siva on 13/02/23.
//

import UIKit
import Combine
import FTCommon

class FTStoreViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    private let padding = 40.0
    private var cancellables = Set<AnyCancellable>()
    private var viewModel = FTStoreViewModel()
    private var sectionContainer: StoreSectionContainer!
    private var currentSize: CGSize = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sectionContainer = StoreSectionContainer(handlers: [BannerSectionHandler(), CategorySectionHandler(), JournalSectionHandler(), StickersSectionHandler(), TemplatesSectionHandler(), StickersSectionHandler(), TemplatesSectionHandler(), TemplatesSectionHandler()])

        // TODO:check for alternative via storyboard
        self.tableView.sectionHeaderTopPadding = 0
        setupUI()
        fetchStoreInfo()
        viewModel.reloadTableView()
        reloadData()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFrame()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            self.tableView.reloadData()
        }, completion: { (_) in
        })
    }

    private func updateFrame() {
        let frame = self.view.frame.size;
        if currentSize.width != frame.width {
            currentSize = frame
            self.tableView.reloadData()
        }
    }

    func reloadData() {
        if let pare = self.parent as? FTStoreContainerViewController
            , let seg = pare.topSegmentView
            , pare.segmentControl.selectedIndex == 0  {
            self.tableView.tableHeaderView = seg
        }
    }
    
    func scrollToinspirations() {
        guard nil != tableView else {
            return
        }
        let section = viewModel.sectionForInspirations()
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
    }
    
    func navigateToDiaries() {
        guard nil != tableView else {
            return
        }
        let section = viewModel.sectionForBanners()
        if let sectionItem = viewModel.storeSectionInfo(at: section) {
            let items = sectionItem.discoveryItems
            if let index = items.firstIndex(where: {$0.type == FTDiscoveryItemType.diaries.rawValue }) {
                FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: index))
            }
        }
    }
}

// MARK: - UI Methods
private extension FTStoreViewController {
    func setupUI() {
        /// Register Cells
        registerCells()
        /// Config Datasource
        configDatasource()
        /// Observe selection
        observers()
    }

    func registerCells() {
        FTStoreBannerTableCell.registerWithTable(tableView)
        FTStorePlannerTableCell.registerWithTable(tableView)
        FTStoreCategoryTableCell.registerWithTable(tableView)
        FTStoreJournalTableCell.registerWithTable(tableView)
        FTStoreStickersTableCell.registerWithTable(tableView)

        /// Register the custom header view.
        FTStoreHeader.registerWithTable(tableView)
    }

    func configDatasource() {
        viewModel.datasource = TemplatesStoreDatasource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, model in
            guard let self = self else {
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
            }
            return self.sectionContainer.tableView(model, tableView, cellForRowAt: indexPath)
        })
    }

}

// MARK: - Private Methods
private extension FTStoreViewController {
    func observers() {
        FTStoreActionManager.shared.actionStream.sink {[weak self] action in
            guard let self = self else { return }
            switch action {
            case .didTapOnDiscoveryItem(items: let items, selectedIndex: let index):
                let item = items[index] as! DiscoveryItem
                    if item.type == FTDiscoveryItemType.category.rawValue {
                        self.navigateToCategory(template: item)
                    } else if item.type == FTDiscoveryItemType.templates.rawValue || item.type == FTDiscoveryItemType.diaries.rawValue {
                        self.navigateToTempaltesVC(discoveryItem: item)
                    } else if item.type == FTDiscoveryItemType.template.rawValue || item.type == FTDiscoveryItemType.sticker.rawValue || item.type == FTDiscoveryItemType.diary.rawValue || item.type == FTDiscoveryItemType.userJournals.rawValue {
                        self.presentTemplatePreviewFor(templates: items, selectedIndex: index)
                    }
                self.trackEventForTappingDiscoveryItem(item: item)
            }
        }.store(in: &FTStoreActionManager.shared.cancellables)

    }

    private func trackEventForTappingDiscoveryItem(item: DiscoveryItem) {
        let eventMapping: [FTStoreSectionType: String] = [
            .banner: EventName.templates_banner_tap,
            .category: EventName.templates_category_tap,
            .templates: EventName.templates_template_tap,
            .stickers: EventName.templates_sticker_tap,
            .journals: EventName.templates_diaries_tap,
            .userJournals: EventName.templates_inspirations_tap
        ]

        if let type = FTStoreSectionType(rawValue: item.sectionType ?? 99), let event = eventMapping[type] {
            FTStoreContainerHandler.shared.actionStream.send(.track(event: event, params: [EventParameterKey.title: item.fileName], screenName: ScreenName.templatesStore))
        }

    }

    func fetchStoreInfo() {
        let output = viewModel.transform()
        output.receive(on: RunLoop.main)
            .sink { event in
                switch event {
                case .fetchTemplatesDidSuccess:
                    print("success")
                case .fetchTemplatesDidFail(let error):
                    print(error)
                }
            }.store(in: &cancellables)
    }

    @objc func seeAllAction(_ sender: UIButton) {
        if let sectionItem = viewModel.storeSectionInfo(at: sender.tag)
        {
            let discoveryItem = DiscoveryItem(displayTitle: sectionItem.title, fileName: sectionItem.fileName, displaySubTitle: "", items: sectionItem.discoveryItems, type: sectionItem.type)
            self.navigateToTempaltesVC(discoveryItem: discoveryItem)
        }
    }

}

//
//MARK: - UITableViewDelegate
extension FTStoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // TODO: Move to reusable view
        if let sectionItem = viewModel.storeSectionInfo(at: section) {
            if sectionItem.sectionType == FTStoreSectionType.banner.rawValue || sectionItem.sectionType == FTStoreSectionType.category.rawValue  {
                let view = UIView()
                view.backgroundColor = .clear
                return view
            }

            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                                                                    FTStoreHeader.reuseIdentifier) as! FTStoreHeader
            view.seeAllButton.isHidden = false
            if sectionItem.sectionType == FTStoreSectionType.stickers.rawValue || sectionItem.sectionType == FTStoreSectionType.userJournals.rawValue {
                view.seeAllButton.isHidden = true
            }
            view.seeAllButton.tag = section
            view.seeAllButton.addTarget(self, action: #selector(seeAllAction(_:)), for: .touchUpInside)
            view.titleLabel.text = sectionItem.title
            return view
        }
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.appColor(.secondaryBG)
        return view
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.1
        }
        return 16
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || section == 1 {
            return 0.1
        }
        return 34.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionItem = viewModel.storeSectionInfo(at: indexPath.section)
        if let type = FTStoreSectionType(rawValue: sectionItem?.sectionType ?? 0) {
            switch type {
            case .banner:
                let size = FTStoreConstants.Banner.calculateSizeFor(view: self.view)
                return size.height + (2 * FTStoreConstants.Banner.topBottomInset)
            case .templates:
                return FTStoreConstants.StoreTemplate.size.height + FTStoreConstants.StoreTemplate.extraHeightPadding + FTStoreConstants.StoreTemplate.topBottomInset
            case .category:
                let sectionItem = viewModel.storeSectionInfo(at: indexPath.section)
                let rows = sectionItem?.rowsCount ?? 1
                var sectionInsert = 0.0
                if rows > 2 {
                    sectionInsert = 30.0
                }
                let height = CGFloat(68 * rows) + padding + sectionInsert //+ CGFloat((rows * 3))
                return 172//height
            case .journals:
                return FTStoreConstants.DigitalDiary.size.height + FTStoreConstants.DigitalDiary.extraHeightPadding + FTStoreConstants.DigitalDiary.topBottomInset

            case .stickers, .userJournals:
                let size = FTStoreConstants.Sticker.calculateSizeFor(view: self.view)
                return size.height + FTStoreConstants.Sticker.extraHeightPadding + FTStoreConstants.StoreTemplate.topBottomInset
            }
        }
        return 360
    }

}

// MARK: - Helper Methods
private extension FTStoreViewController {
    func navigateToCategory(template: DiscoveryItem) {
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTCategoryTempaltesViewController") as? FTCategoryTempaltesViewController {
            vc.categoryTemplate = template
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func navigateToTempaltesVC(discoveryItem: DiscoveryItem) {
        if let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTStoreTemplatesViewController") as? FTStoreTemplatesViewController {
            vc.discoveryItem = discoveryItem
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func presentTemplatePreviewFor(templates: [TemplateInfo], selectedIndex: Int) {
        FTTemplatesPageViewController.presentFromViewController(self, templates: templates, selectedIndex: selectedIndex)
    }

}
