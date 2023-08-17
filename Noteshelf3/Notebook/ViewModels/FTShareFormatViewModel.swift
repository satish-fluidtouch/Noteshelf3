//
//  FTShareFormatViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 02/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTShareFormatViewModel: ObservableObject {
    weak var delegate: FTShareFormatDelegate?
    var option: FTShareOption = .currentPage
    var previewImages: [UIImage?] = []
    var shelfItems: [FTShelfItemProtocol] = []
    var pages:[FTPageProtocol] = []
    var bookHasStandardCover: Bool = false
    let saveToCameraroll = "share.savetoCameraRoll".localized
    let share = "notebook.share.text".localized
    let cancel = "Cancel".localized
    let titleShare = "share".localized
    let hide = "Hide".localized
    let options = "Options".localized

    @Published var previewItems: [FTSharePreviewItemViewModel]  = []
    @Published var selectedFormat: RKExportFormat {
        didSet {
            self.updateExportOptions()
            self.saveSelectedFormat()
        }
    }

    @Published var exportOptions: [FTShareOptionStatus] = []

    init(option: FTShareOption) {
        self.option = option
        self.selectedFormat = RKExportFormat(rawValue: UInt32(FTUserDefaults.exportFormat()))
        self.updateExportOptions()
    }

    convenience init(option: FTShareOption,shelfItems:[FTShelfItemProtocol]){
        self.init(option: option)
        self.shelfItems = shelfItems
        self.setShelfItemsForPreview()
    }

    convenience init(option: FTShareOption, pages: [FTPageProtocol],bookHasStandardCover: Bool = false) {
        self.init(option: option)
        self.pages = pages
        self.bookHasStandardCover = bookHasStandardCover
        self.setpagesForPreview()
    }
    var canShowSaveToCameraRollOption: Bool {
        if  selectedFormat == kExportFormatImage && option != .notebook {
            return true
        }
        return false
    }
    func updateDelegate(_ delegate: FTShareFormatDelegate) {
        self.delegate = delegate
    }

    func handleCancelAction() {
        self.delegate?.didTapOnCancel()
    }

    func handleShareAction() {
        self.delegate?.didInitiateShare(type:.share)
    }

    func handleAddCameraRollAction() {
        self.delegate?.didInitiateShare(type:.savetoCameraRoll)
    }

    func updateExportOptions() {
        var reqOptions: [FTExportOptions] = [.pageTemplate, .coverPage, .pageFooter]
        if option != .allPages {
            reqOptions.removeAll { option in
                option == .coverPage
            }
        }
        if self.selectedFormat == kExportFormatNBK {
            reqOptions.removeAll()
        }
        self.exportOptions = reqOptions.map({ option in
            FTShareOptionStatus(option: option)
        })
    }

    func saveSelectedFormat() {
        FTUserDefaults.setExportFormat(Int(self.selectedFormat.rawValue))
    }

    func saveStatus(for option: FTExportOptions, status: Bool) {
        if option == .pageFooter {
            FTUserDefaults.exportPageFooter = status
        } else if option == .pageTemplate {
            FTUserDefaults.showPageTemplate = status
        } else if option == .coverPage {
            FTUserDefaults.exportCoverPage = status
        }
    }
    private func setInitialValues(_ option: FTShareOption){
        self.option = option
        self.selectedFormat = RKExportFormat(rawValue: UInt32(FTUserDefaults.exportFormat()))
        self.updateExportOptions()
    }
    private func setShelfItemsForPreview(){
        var items: [FTSharePreviewItemViewModel] = []
        self.shelfItems.prefix(3).forEach { shelfItem in
            if let groupItem = shelfItem as? FTGroupItemProtocol {
                items.append(FTShareGroupItemPreviewViewModel(group: groupItem))
            } else  {
                items.append(FTShareNotebookPreviewViewModel(shelfItem: shelfItem))
            }
        }
        previewItems =  items
    }
    private func setpagesForPreview(){
        var items: [FTSharePreviewItemViewModel] = []
        self.pages.prefix(3).forEach { page in
            items.append(FTSharePageItemPreviewViewModel(page: page))
        }
        previewItems =  items
    }
}

struct FTShareOptionStatus: Identifiable {
    var id: FTExportOptions
    var option: FTExportOptions
    var status: Bool = true

    init(option: FTExportOptions) {
        self.id = option
        self.option = option
        if option == .pageFooter {
            self.status = FTUserDefaults.exportPageFooter
        } else if option == .pageTemplate {
            self.status = FTUserDefaults.showPageTemplate
        } else if option == .coverPage {
            self.status = FTUserDefaults.exportCoverPage
        }
    }
}
