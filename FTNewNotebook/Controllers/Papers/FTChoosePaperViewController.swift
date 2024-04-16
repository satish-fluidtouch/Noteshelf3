//
//  FTPaperTemplatesViewController.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 24/02/23.
//

import UIKit
import FTStyles
import FTCommon

protocol FTChoosePaperDelegate: NSObject {
    func didTapCancel()
    func didChoosePaperWithVariants(_ themeWithVariants: FTSelectedPaperVariantsAndTheme)
    func updatePaperVaraints(_ variants: FTSelectedPaperVariantsAndTheme)
    func updatePaperPreviewWith(_ paperTemplate:FTThemeable)
    func didTapMoreTempates()
}

class FTChoosePaperViewController: UIViewController {
    @IBOutlet weak private var choosePaperViewHeightConstraint: NSLayoutConstraint?
    
    var paperVariantsDataModel: FTPaperTemplatesVariantsDataModel!
    var selectedPaperVariantsAndTheme: FTSelectedPaperVariantsAndTheme!
    var basicPaperThemes: FTBasicTemplateCategoryModel?
    weak var choosePaperDelegate: FTChoosePaperDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.view.shapeTopCorners()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setViewSize()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.setViewSize()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.setViewSize()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let paperTemplateVc = segue.destination as? FTPaperTemplatesVariantsController {
            paperTemplateVc.templateVariantsDelegate = self
            paperTemplateVc.papervariantsDataModel = paperVariantsDataModel
            paperTemplateVc.selectedPaperVariants = selectedPaperVariantsAndTheme
        }
        if let paperThemesVC = segue.destination as? FTPapersViewController {
            paperThemesVC.basicPaperThemes = basicPaperThemes
            paperThemesVC.paperPickerMode = .paperPicker
            paperThemesVC.selectedPaperVariantsAndTheme =  selectedPaperVariantsAndTheme
            paperThemesVC.papersDelegate = self
        }
    }

    private func styleNavigationBar(){
        self.title = "shelf.paperPicker.choosePaper".localized
        let titleAttrs = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0), NSAttributedString.Key.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttrs
        let leftNavItem = FTNavBarButtonItem(type: .left, title: "Cancel".localized, delegate: self)
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self)
        self.navigationItem.leftBarButtonItem = leftNavItem
        self.navigationItem.rightBarButtonItem = rightNavItem
    }

    private func applyVariantsToTemplates(){
        for child in children {
            if let childVC = child as? FTPapersViewController {
                childVC.reloadTemplatesViewWithLatest(selectedVariantsAndTheme: self.selectedPaperVariantsAndTheme)
                break
            }
        }
    }
    private func setViewSize(){
        if self.traitCollection.horizontalSizeClass == .regular {
            if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
                self.choosePaperViewHeightConstraint?.constant = 242
            } else {
                self.choosePaperViewHeightConstraint?.constant = 213
            }
        } else {
            self.choosePaperViewHeightConstraint?.constant = 213
        }
    }
}
extension FTChoosePaperViewController: FTPaperTemplatesVariantsDelegateNew {
    func updatePaperVaraints(_ variantsAndTheme: FTSelectedPaperVariantsAndTheme){
        var refreshThemes: Bool = false
        if self.selectedPaperVariantsAndTheme.templateColorModel != variantsAndTheme.templateColorModel || self.selectedPaperVariantsAndTheme.lineHeight != variantsAndTheme.lineHeight || self.selectedPaperVariantsAndTheme.orientation != variantsAndTheme.orientation {
            refreshThemes = true
        }
        self.selectedPaperVariantsAndTheme.templateColorModel = variantsAndTheme.templateColorModel
        self.selectedPaperVariantsAndTheme.lineHeight = variantsAndTheme.lineHeight
        self.selectedPaperVariantsAndTheme.orientation = variantsAndTheme.orientation
        self.choosePaperDelegate?.updatePaperVaraints(variantsAndTheme)
        if refreshThemes {
            self.applyVariantsToTemplates()
        }
    }
}
extension  FTChoosePaperViewController: FTPaperDelegate {
    func didTapMoreTemplates() {
        self.choosePaperDelegate?.didTapMoreTempates()
    }
    func didTapPaperTemplate(_ paperTemplate: FTThemeable) {
        self.selectedPaperVariantsAndTheme.theme = paperTemplate
        self.choosePaperDelegate?.updatePaperPreviewWith(paperTemplate)
    }
}

extension FTChoosePaperViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .left {
            self.choosePaperDelegate?.didTapCancel()
        } else {
            self.choosePaperDelegate?.didChoosePaperWithVariants(self.selectedPaperVariantsAndTheme)
        }
    }
}
