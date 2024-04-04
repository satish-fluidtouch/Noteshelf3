//
//  FTPaperPropertiesViewController.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 24/02/23.
//

import UIKit
import FTCommon
import Combine

public struct FTPaperTemplatesVariantsDataModel {
    public var templateColors: [FTTemplateColorModel] = []
    public var lineHeights:[FTTemplateLineHeightModel] = []
    public var sizes:[FTTemplateSizeModel] = []
    public init(templateColors: [FTTemplateColorModel],
         lineHeights:[FTTemplateLineHeightModel],
         sizes: [FTTemplateSizeModel]) {
        self.templateColors = templateColors
        self.lineHeights = lineHeights
        self.sizes = sizes
    }
}
public struct FTSelectedPaperVariantsAndTheme {
    public var templateColorModel: FTTemplateColorModel
    public var lineHeight: FTTemplateLineHeight
    public var orientation: FTTemplateOrientation
    public var size: FTTemplateSize = .iPad
    public var theme: FTThemeable
    public init(templateColorModel: FTTemplateColorModel,
                lineHeight: FTTemplateLineHeight,
                orientation: FTTemplateOrientation,
                size: FTTemplateSize = .iPad,
                selectedPaperTheme: FTThemeable) {
        self.templateColorModel = templateColorModel
        self.lineHeight = lineHeight
        self.orientation = orientation
        self.size = size
        self.theme = selectedPaperTheme
    }

    var thumbImagePrefix: String {
        var imgName: String
        let name = theme.displayName.localizedEnglish.lowercased()
        if name == "plain" {
            imgName = ""
        } else {
            imgName = "\(lineHeight.thumbImgPrefix)_\(name)"
        }
        return imgName
    }
}
protocol FTPaperTemplatesVariantsDelegateNew: NSObject {
    func updatePaperVaraints(_ variantsAndTheme: FTSelectedPaperVariantsAndTheme)
}
class FTPaperTemplatesVariantsController: UIViewController {
    @IBOutlet private weak var templatesPropertiesView: UIView?
    @IBOutlet private weak var templateColorsStackView: UIStackView?
    @IBOutlet private weak var lineHeightButton: UIButton?
    @IBOutlet private weak var orientationSegmentedControl: UISegmentedControl?
    @IBOutlet private weak var customColorWellView: FTPaperTemplateColorWell?
    @IBOutlet private weak var lineHeightView: UIView?
    @IBOutlet private weak var lineHeightViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet private weak var seperatorDotView: UIView?
    @IBOutlet private weak var variantsViewWidthConstraint: NSLayoutConstraint?
    weak var templateVariantsDelegate: FTPaperTemplatesVariantsDelegateNew?
    var papervariantsDataModel: FTPaperTemplatesVariantsDataModel!
    private var firstValueSet = false

    var selectedPaperVariants: FTSelectedPaperVariantsAndTheme! {
        didSet {
            if !firstValueSet {
                firstValueSet = true
                return
            }
            self.templateVariantsDelegate?.updatePaperVaraints(self.selectedPaperVariants)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    private func configureUI() {
        self.configurTemplateColorsView()
        self.configureLineHeightView()
        self.configureOrientaionSegmentedControl()
    }
    func updateOrientationSegmentVisibility(_ shouldHide: Bool){
        self.orientationSegmentedControl?.isHidden = shouldHide
        self.seperatorDotView?.isHidden = shouldHide
        self.variantsViewWidthConstraint?.constant = shouldHide ? 328 : 448
        if shouldHide {
            self.orientationSegmentedControl?.selectedSegmentIndex = 0
            self.selectedPaperVariants.orientation = .portrait
        }
    }

//MARK: Template orientation related code
    private func configureOrientaionSegmentedControl(){
        let selectedOrientaion = selectedPaperVariants.orientation
        self.orientationSegmentedControl?.selectedSegmentIndex = selectedOrientaion == .portrait ? 0 : 1
        orientationSegmentedControl?.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        orientationSegmentedControl?.backgroundColor = UIColor.black.withAlphaComponent(0.04)
        orientationSegmentedControl?.clipsToBounds = true
        updateOrientationSegmentVisibility(selectedPaperVariants.size == FTTemplateSize.mobile)
    }
    @IBAction func templateOrientaionChanged(_ sender: UISegmentedControl) {
        let orientation: FTTemplateOrientation = sender.selectedSegmentIndex == 0 ? .portrait : .landscape
        self.selectedPaperVariants.orientation = orientation
    }
//MARK: Template colors related code
    private func configurTemplateColorsView(){
        for (index,colorModel) in papervariantsDataModel.templateColors.enumerated() {
            var templateColorModel: FTTemplateColorModel = colorModel
            let isSelected = colorModel.color == selectedPaperVariants.templateColorModel.color
            if (colorModel.color == .custom && colorModel.color == selectedPaperVariants.templateColorModel.color) {
                templateColorModel = selectedPaperVariants.templateColorModel
            }
            if let colorView = templateColorsStackView?.subviews.first(where: {$0.tag == (700 + index)}) as? FTPaperTemplateColorButton {
                colorView.configureViewWith(templateColor: templateColorModel,isSelected: isSelected)
            }
            if templateColorModel.color == .custom {
                self.customColorWellView?.selectedColor = nil
                self.customColorWellView?.customColorDelegate = self
                if isSelected {
                    self.customColorWellView?.selectedColor = UIColor(hexString: templateColorModel.hex)
                }
            }
        }
    }
    @IBAction func tappedTemplateColor(_ sender: UIButton) {
        self.resetBasicTemplateColorsSelection()
        if let colorView = sender as? FTPaperTemplateColorButton, let templateColor = colorView.templateColor {
            self.customColorWellView?.selectedColor = nil
            colorView.isColorSelected = true
            selectedPaperVariants.templateColorModel = templateColor
        }
    }
    private func resetBasicTemplateColorsSelection() {
        guard let colorButtons = templateColorsStackView?.subviews.compactMap({ $0 as? FTPaperTemplateColorButton }) else {
            return
        }
        for colorButton in colorButtons where colorButton.isColorSelected {
            colorButton.isColorSelected = false
        }
    }

//MARK: Template line heights related code
    private func configureLineHeightView(){
        self.setConstraintToLineHeightView()
        configureTemplateLineHeightMenu()
        let iconName = selectedPaperVariants.lineHeight.iconPath + "Big"
        let lineHeightImage = UIImage(named: iconName, in: currentBundle, with: nil)
        self.lineHeightButton?.setImage(lineHeightImage, for: .normal)
        self.lineHeightButton?.layer.borderColor = UIColor.appColor(.black20).cgColor
        self.lineHeightButton?.layer.borderWidth = 1.0
    }

    private func setConstraintToLineHeightView(){
        if let lineHeightView = self.lineHeightView {
            let xOrigin: CGFloat = self.traitCollection.isRegular ? 288 : 272
            self.lineHeightView?.frame = CGRect(x: xOrigin, y: lineHeightView.frame.origin.y, width: lineHeightView.frame.width, height: lineHeightView.frame.height)
        }
    }
    private func configureTemplateLineHeightMenu() {
        var actions = [UIAction]()
        for lineHeightModel in papervariantsDataModel.lineHeights {
            let lineHeightTitle = lineHeightModel.lineHeight.displayTitle
            let lineHeightImage = UIImage(named: lineHeightModel.lineHeight.iconPath, in: currentBundle, with: nil)
            let isSelected =  lineHeightModel.lineHeight == selectedPaperVariants.lineHeight
            let state: UIMenuElement.State = isSelected ? .on : .off
            let action = UIAction(title: lineHeightTitle,image: lineHeightImage,state: state) {[weak self] action in
                self?.selectedPaperVariants.lineHeight = lineHeightModel.lineHeight
                self?.updatelineHeightButtonWith(selectedLineHeight: lineHeightModel.lineHeight)
                if let lineHeightMenu = self?.lineHeightButton?.menu {
                    self?.lineHeightButton?.menu = self?.updateActionState(actionTitle: action.title, menu:  lineHeightMenu)
                }
            }
            actions.append(action)
        }
        self.lineHeightButton?.menu = UIMenu(children:actions)
        self.lineHeightButton?.showsMenuAsPrimaryAction = true
        self.lineHeightButton?.preferredMenuElementOrder = .fixed
    }
    private func updatelineHeightButtonWith(selectedLineHeight: FTTemplateLineHeight){
        let iconNameForLineHeightbutton = selectedLineHeight.iconPath + "Big"
        let lineHeightImage = UIImage(named: iconNameForLineHeightbutton, in: currentBundle, with: nil)
        self.lineHeightButton?.setImage(lineHeightImage, for: .normal)
    }
    private func updateActionState(actionTitle: String? = nil, menu: UIMenu) -> UIMenu {
        if let actionTitle = actionTitle {
            menu.children.forEach { action in
                guard let action = action as? UIAction else {
                    return
                }
                action.state = action.title == actionTitle ? .on : .off
            }
        } else {
            let action = menu.children.first as? UIAction
            action?.state = .on
        }
        return menu
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.setConstraintToLineHeightView()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.setConstraintToLineHeightView()
        self.updateOrientationSegmentVisibility(selectedPaperVariants.size == FTTemplateSize.mobile)
    }
}
extension FTPaperTemplatesVariantsController: FTPaperTemplateCustomColorDelegate {
    func didSelectCustomColor(_ color: UIColor?) {
        self.resetBasicTemplateColorsSelection()
        if let selectedColor = self.customColorWellView?.selectedColor {
            selectedPaperVariants.templateColorModel = FTTemplateColorModel(color: .custom, hex: selectedColor.hexStringFromColor())
        }
    }
}
