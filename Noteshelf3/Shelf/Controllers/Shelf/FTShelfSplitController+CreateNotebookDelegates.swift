//
//  FTShelfSplitController+CreateNotebookDelegates.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 23/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTNewNotebook

extension FTShelfSplitViewController: FTPapersInfoDelegate {
    var selectedPaperVariantsAndTheme: FTNewNotebook.FTSelectedPaperVariantsAndTheme {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        let variants = basicTemplatesDataSource.variantsForMode(.basic)
        return FTSelectedPaperVariantsAndTheme(templateColorModel: variants.color,
                                               lineHeight: variants.lineHeight,
                                               orientation: variants.orientaion,
                                               size: variants.templateSize,
                                               selectedPaperTheme: selectedPaperTheme)
    }
    var paperVariantsDataModel: FTNewNotebook.FTPaperTemplatesVariantsDataModel {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        let dataSource = basicTemplatesDataSource.basictemplateDateSourceForMode(.basic)
        return FTPaperTemplatesVariantsDataModel(templateColors: dataSource.colorModel,
                                                                       lineHeights: dataSource.lineHeightsModel,
                                                                       sizes: dataSource.sizeModel)
    }
    var paperThemes: FTNewNotebook.FTBasicTemplateCategoryModel {
        guard let basicThemes = FTBasicTemplatesDataSource.shared.fetchThemesForMode(.quickCreate).first else{
            fatalError("Error in fetching basicThemes")
        }
        return basicThemes
    }
}
extension FTShelfSplitViewController: FTCreateNotebookDelegate {
    
    func didTapMoreTempates() {
        self.sideMenuController?.selectAndOpenTemplatesScreen()
    }

    func createNotebookWithModel(_ notebookDetailsModel: FTNewNotebook.FTNewNotebookModel) {
        if(!FTDeveloperOption.bookScaleAnim) {
            self.presentedViewController?.dismiss(animated: true)
        }
        self.udpatePaperThemeAndVariants(notebookDetailsModel.selectedPaperWithVariants)
        if let coverTheme = notebookDetailsModel.selectedCoverTheme {
            self.setDefaultCoverTheme(coverTheme)
        }
        let coverTheme = notebookDetailsModel.selectedCoverTheme
        let newNotebookDetails = FTNewNotebookDetails(coverTheme: coverTheme, paperTheme: notebookDetailsModel.selectedPaperWithVariants.theme, documentPin: FTDocumentPin(pin: notebookDetailsModel.passwordDetails?.pin, hint: notebookDetailsModel.passwordDetails?.hint, isTouchIDEnabled: notebookDetailsModel.passwordDetails?.useBiometric), title: notebookDetailsModel.title)
        self.currentShelfViewModel?.createBookUsing(notebookDetails: newNotebookDetails)
    }
    func openPasswordController(on controller: UIViewController, at sourceView: UIView?, passwordDetails: FTPasswordModel?) {
        let passcodeController = FTPasswordHostController(passwordViewDelegate: controller as? FTCreateNotebookViewController, passwordDetails: passwordDetails)
        let navigationController = UINavigationController(rootViewController: passcodeController)
        navigationController.modalPresentationStyle = .popover
        let viewHeight = FTBiometricManager.shared().isTouchIDEnabled() ? 440 : 396
        navigationController.preferredContentSize = CGSize(width: 330, height: viewHeight)
        navigationController.popoverPresentationController?.sourceView = sourceView
        controller.present(navigationController, animated: true)
    }
}
extension FTShelfSplitViewController: FTCoversInfoDelegate, FTCoverUpdateDelegate {
    //MARK: Covers Delegate
    func generateCoverTheme(image: UIImage, coverType: FTNewNotebook.FTCoverSelectedType) -> FTNewNotebook.FTThemeable? {
        let coverDataSource = FTCoverDataSource.shared
        return coverDataSource.generateCoverTheme(image: image, coverType: coverType, shouldSave: true)
    }

    func fetchCoversData() -> [FTCoverSectionModel] {
        let coverDataSource = FTCoverDataSource.shared
        let coverSections = coverDataSource.fetchCoverItems()
        return coverSections
    }

    func fetchNoCoverTheme() -> FTThemeable? {
        if let  themeUrl = Bundle.main.url(forResource: "NoCover", withExtension: "nsc", subdirectory:"StockCovers.bundle") {
            let theme = FTTheme.theme(url: themeUrl, themeType: .noCover)
            return theme
        }
        return nil
    }

    func fetchRecentCoversData() -> [FTCoverThemeModel] {
        let coverDataSource = FTCoverDataSource.shared
        let recents = coverDataSource.getRecents()
        return recents
    }

    func fetchPreviousSelectedCoverTheme() -> FTThemeable {
        let coverDataSource = FTCoverDataSource.shared
        return coverDataSource.fetchPreviousSelectedCoverTheme()
    }
    
    func didUpdateCover(_ theme: FTThemeable?) {
        if let theme {
            self.currentShelfViewModel?.didSelectCover(theme)
        }
    }
}

extension FTShelfSplitViewController {
    private var selectedPaperTheme: FTThemeable {
        FTThemesLibrary(libraryType: .papers).getDefaultTheme(defaultMode: .basic)
    }
    private func setDefaultCoverTheme(_ theme: FTThemeable) {
        FTThemesLibrary(libraryType: .covers).setDefaultTheme(theme, defaultMode:.basic, withVariants: nil)
    }
    private func udpatePaperThemeAndVariants(_ themeWithVariants: FTNewNotebook.FTSelectedPaperVariantsAndTheme) {
        let basicTemplatesDataSource = FTBasicTemplatesDataSource.shared
        basicTemplatesDataSource.saveThemeWithVariants(themeWithVariants,mode: .basic)
    }
}
