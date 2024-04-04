//
//  FTPapersViewController.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 02/03/23.
//

import UIKit
import FTTemplatesStore
protocol FTPaperDelegate: AnyObject, FTThemeUpdateURL {
    func didTapPaperTemplate(_ paperTemplate: FTThemeable)
    func didTapMoreTemplates()
}
public enum FTPaperPickerMode{
    case chooseTemplate
    case paperPicker
    case quickCreateSettings
}
class FTPapersViewController: UIViewController {

    @IBOutlet weak private var collectionViewLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak private var collectionViewTrailingConstraint: NSLayoutConstraint?
    @IBOutlet weak private var collectionViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak private var collectionView: UICollectionView?

    @IBOutlet weak var paperTypesTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperTypesBottomConstraint: NSLayoutConstraint!

    private let templateCellReuseId = "FTPaperCollectionViewCell"
    private let moreTemplateCellReuseId = "FTMoreTemplatesCollectionViewCell"

    weak var papersDelegate: FTPaperDelegate?
    var basicPaperThemes: FTBasicTemplateCategoryModel?
    var selectedPaperVariantsAndTheme: FTSelectedPaperVariantsAndTheme!
    private var selectedPaperThemeCellIndexPath: IndexPath?
    var paperPickerMode:FTPaperPickerMode = FTPaperPickerMode.paperPicker

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpCollectionViewConstraints()
        collectionView?.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollCollectionViewToSelectedTheme()
    }
    private func setUpCollectionViewConstraints(){
        let cellWidth = FTNewNotebook.Constants.ChoosePaperPanel.templateCellRegularSize.width
        let interItemSpacing = FTNewNotebook.Constants.ChoosePaperPanel.regularItemSpacing
        let calculatedCollectionViewWidth = (cellWidth + interItemSpacing) * CGFloat(((self.basicPaperThemes?.categoryData.count ?? 0) + 1))
        if calculatedCollectionViewWidth <  self.view.frame.width {
            self.collectionViewLeadingConstraint?.isActive = false
            self.collectionViewTrailingConstraint?.isActive = false
            self.collectionView?.contentInset = UIEdgeInsets.zero
            self.collectionViewWidthConstraint?.constant = calculatedCollectionViewWidth
        } else {
            self.collectionViewWidthConstraint?.constant = self.view.frame.width
            self.collectionViewLeadingConstraint?.isActive = true
            self.collectionViewTrailingConstraint?.isActive = true
        }
        if var layout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            if paperPickerMode == .paperPicker{
                layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .horizontal
                paperTypesTopConstraint.isActive = false
                paperTypesBottomConstraint.isActive = false
            }else{
                layout = FTPaperTemplateCenteredCollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                paperTypesTopConstraint.isActive = true
                paperTypesBottomConstraint.isActive = true
            }
            self.collectionView?.collectionViewLayout = layout
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setUpCollectionViewConstraints()
    }
    func reloadTemplatesViewWithLatest(selectedVariantsAndTheme:FTSelectedPaperVariantsAndTheme){
        self.selectedPaperVariantsAndTheme = selectedVariantsAndTheme
        if let themes = self.basicPaperThemes?.categoryData {
            for (index,theme) in themes.enumerated() {
                if let cell = self.collectionView?.cellForItem(at: IndexPath(row: index, section: 0)) as? FTPaperCollectionViewCell {
                    cell.applySelectedColorVariant(UIColor(hexString: selectedVariantsAndTheme.templateColorModel.hex))
                    var variantsWithTheme = selectedVariantsAndTheme
                    variantsWithTheme.theme = theme
                    cell.thumbnailForVariantsAndTheme(variantsWithTheme)
                }
            }
        }
    }
    @objc private func showAlertToNavigateToTemplatesView() {
        UIAlertController.showNavigateToTemplatesAlert(with: NSLocalizedString("paperPicker.moreTemplates.alert.title", comment: "This will exit the New Notebook screen and redirect you to the Templates view on the Shelf."), message: NSLocalizedString("paperPicker.moreTemplates.alert.message", comment: "Would you like to continue?"), from: self) {
            self.papersDelegate?.didTapMoreTemplates()
        }
    }
    private func scrollCollectionViewToSelectedTheme(){
        if let selectedIndexPath = self.getInitialSelectedIndexpathIfExist() {
            self.collectionView?.scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: false)
        } else {
            self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    private func getInitialSelectedIndexpathIfExist() -> IndexPath? {
        var scrollIndexPath: IndexPath?
        if let themeIndex = self.basicPaperThemes?.categoryData.firstIndex(where: {$0.displayName == selectedPaperVariantsAndTheme.theme.displayName}){
                scrollIndexPath = IndexPath(row: themeIndex, section: 0)
        }
        return scrollIndexPath
    }
}
extension FTPapersViewController: UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //var count: Int = 1
        return paperPickerMode == .paperPicker ? (basicPaperThemes?.categoryData.count ?? 0) + 1 :  (basicPaperThemes?.categoryData.count ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if paperPickerMode == .paperPicker && indexPath.row == basicPaperThemes?.categoryData.count {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: moreTemplateCellReuseId, for: indexPath) as? FTMoreTemplatesCollectionViewCell else {
                fatalError("FTMoreTemplatesCollectionViewCell cell doesn't exists")
            }
            cell.configureCell()
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: templateCellReuseId, for: indexPath) as? FTPaperCollectionViewCell else {
                fatalError("FTPaperCollectionViewCell cell doesn't exists")
            }
            if let paperTheme = basicPaperThemes?.categoryData[indexPath.row],var variantsAndTheme = self.selectedPaperVariantsAndTheme {
                var isPaperSelected = selectedPaperVariantsAndTheme.theme.displayName == paperTheme.displayName
                let lastPath = paperTheme.themeFileURL.lastPathComponent.deletingPathExtension
                if let selectedThemeURL = self.papersDelegate?.currentSelectedURL() {
                    isPaperSelected = (selectedThemeURL.lastPathComponent.deletingPathExtension == lastPath)
                }

                variantsAndTheme.theme = paperTheme
                variantsAndTheme.orientation = .portrait
                cell.configureCellWith(title: paperTheme.displayName,
                                       thumbnailColorHex: variantsAndTheme.templateColorModel.hex)
                if paperPickerMode == .paperPicker || paperPickerMode == .quickCreateSettings{
                    cell.isCellSelected = isPaperSelected
                    if isPaperSelected {
                        self.selectedPaperThemeCellIndexPath = indexPath
                    }
                    if isPaperSelected {
                        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                    }
                } else {
                    cell.isCellSelected = false
                }
                  cell.thumbnailForVariantsAndTheme(variantsAndTheme)
            }
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        func didSelectTheme(){
            if let tappedPaper = basicPaperThemes?.categoryData[indexPath.row] {
                self.selectedPaperVariantsAndTheme.theme = tappedPaper
                self.papersDelegate?.didTapPaperTemplate(tappedPaper)
                self.papersDelegate?.setCurrentSelectedURL(url: selectedPaperVariantsAndTheme.theme.themeFileURL)
            }
        }
            if let currenSelectedCell = self.collectionView?.cellForItem(at: indexPath) as? FTPaperCollectionViewCell {
                if let previousSelectedCellIndexPath = self.selectedPaperThemeCellIndexPath, let previousSelectedCell = self.collectionView?.cellForItem(at: previousSelectedCellIndexPath) as? FTPaperCollectionViewCell {
                    previousSelectedCell.isCellSelected = false
                    currenSelectedCell.isCellSelected = true
                } else {
                    currenSelectedCell.isCellSelected = true
                }
                selectedPaperThemeCellIndexPath = indexPath
                didSelectTheme()
            }else if let _ = self.collectionView?.cellForItem(at: indexPath) as? FTMoreTemplatesCollectionViewCell {
                self.showAlertToNavigateToTemplatesView()
            }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if paperPickerMode == .paperPicker{
            if !self.traitCollection.isRegular {
                return FTNewNotebook.Constants.ChoosePaperPanel.templateCellCompactSize
            }
            return FTNewNotebook.Constants.ChoosePaperPanel.templateCellRegularSize
        }else{
            return FTNewNotebook.Constants.ChoosePaperPanel.templateCellRegularSize
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            if paperPickerMode == .paperPicker{
                if !self.traitCollection.isRegular {
                    return FTNewNotebook.Constants.ChoosePaperPanel.compactItemSpacing
                }else{
                    return FTNewNotebook.Constants.ChoosePaperPanel.regularItemSpacing
                }
            }else{
                return FTNewNotebook.Constants.ChoosePaperPanel.paperTemplateLineItemSpacing
            }
        }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if !self.traitCollection.isRegular {
            return FTNewNotebook.Constants.ChoosePaperPanel.compactItemSpacing
        }
        return FTNewNotebook.Constants.ChoosePaperPanel.regularItemSpacing
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if paperPickerMode == .chooseTemplate{
            return UIEdgeInsets(top: 0,left: !self.traitCollection.isRegular ? 18 :46,bottom: 0,right: !self.traitCollection.isRegular ? 18 :46)
        }else{
            return UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
        }
    }
}
