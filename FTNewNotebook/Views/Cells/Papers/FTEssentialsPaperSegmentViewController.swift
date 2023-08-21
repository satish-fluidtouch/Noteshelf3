//
//  FTEssentialsPaperSegmentViewController.swift
//  FTNewNotebook
//
//  Created by Rakesh on 14/06/23.
//

import UIKit
import FTTemplatesStore

class FTEssentialsPaperSegmentViewController: UIViewController {

    private var varaintsData: FTPaperTemplateDataHelper!
    public func configure(varaintsData: FTPaperTemplateDataHelper,source: Source = .none,delegate:FTPaperTemplateDelegate? = nil, themeUpdateDel: FTThemeUpdateURL) {
        self.varaintsData = varaintsData
        self.source = source
        self.delegate = delegate
        self.themeUpdateDel = themeUpdateDel
    }
//    weak var choosePaperDelegate:FTChoosePaperDelegate?
    private let orientationLoclizdStrng = "shelf.paperPicker.orientation".localized
    private var source: Source = .none
    weak var delegate: FTPaperTemplateDelegate?
    weak var themeUpdateDel: FTThemeUpdateURL?

    @IBOutlet weak private var paperSizeBtn: UIButton!
    @IBOutlet weak private var paperSizeLable: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTemplateSizesMenu()
    }
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let data = self.varaintsData {
            if segue.identifier == "FTPaperTemplateVariantsVc"{
                if let varainstVc = segue.destination as? FTPaperTemplatesVariantsController  {
                    varainstVc.templateVariantsDelegate = self
                    varainstVc.papervariantsDataModel = data.variantsDataModel
                    varainstVc.selectedPaperVariants = data.selectedVariantsAndTheme
                }
            }
            if segue.identifier == "FTPapersVC"{
                if let paperThemesVC = segue.destination as? FTPapersViewController {
                    paperThemesVC.basicPaperThemes = data.basicPaperThemes
                    paperThemesVC.paperPickerMode = source == .shelf ? .quickCreateSettings : .chooseTemplate
                    paperThemesVC.selectedPaperVariantsAndTheme = data.selectedVariantsAndTheme
                    paperThemesVC.papersDelegate = self
                }
            }
        }
    }
}
extension FTEssentialsPaperSegmentViewController: FTPaperDelegate {
    func currentSelectedURL() -> URL? {
        return self.themeUpdateDel?.currentSelectedURL()
    }
    
    func setCurrentSelectedURL(url: URL) {
        self.themeUpdateDel?.setCurrentSelectedURL(url: url)
    }
    
    func didTapMoreTemplates() {

    }
    func didTapPaperTemplate(_ paperTemplate: FTThemeable) {
        self.varaintsData.selectedVariantsAndTheme.theme = paperTemplate
        if source != .shelf {
            self.dismiss(animated: true)
            self.delegate?.didSelectPaperTheme(theme: self.varaintsData.selectedVariantsAndTheme)
        }
    }
}
extension FTEssentialsPaperSegmentViewController: FTPaperTemplatesVariantsDelegateNew {
    func updatePaperVaraints(_ variantsAndTheme: FTSelectedPaperVariantsAndTheme){
        var refreshThemes: Bool = false
        if self.varaintsData.selectedVariantsAndTheme.templateColorModel != variantsAndTheme.templateColorModel || self.varaintsData.selectedVariantsAndTheme.lineHeight != variantsAndTheme.lineHeight{
            refreshThemes = true
        }
        self.varaintsData.selectedVariantsAndTheme.templateColorModel = variantsAndTheme.templateColorModel
        self.varaintsData.selectedVariantsAndTheme.lineHeight = variantsAndTheme.lineHeight
        self.varaintsData.selectedVariantsAndTheme.orientation = variantsAndTheme.orientation
//        self.choosePaperDelegate?.updatePaperVaraints(variantsAndTheme)
        if refreshThemes {
            self.applyVariantsToTemplates()
        }
    }
}
private extension FTEssentialsPaperSegmentViewController{

    private func applyVariantsToTemplates(){
        for child in children {
            if let childVC = child as? FTPapersViewController {
                childVC.reloadTemplatesViewWithLatest(selectedVariantsAndTheme: self.varaintsData.selectedVariantsAndTheme)
                break
            }
        }
    }
    //MARK: Template sizes menu
    private func configureTemplateSizesMenu() {
        self.paperSizeBtn.setTitle(varaintsData.selectedVariantsAndTheme.size.displayTitle, for: .normal)
        if self.traitCollection.isRegular {
            self.paperSizeBtn?.menu = templateSizeOptionsMenu
        } else {
            let menuElements: [UIMenuElement] = self.varaintsData.selectedVariantsAndTheme.size == FTTemplateSize.mobile ? [templateSizeOptionsMenu] : [templateSizeOptionsMenu,orientaionOptionsMenu]
            self.paperSizeBtn?.menu = UIMenu(identifier: UIMenu.Identifier("SizesMenu") ,children:menuElements)
        }
        self.paperSizeBtn?.showsMenuAsPrimaryAction = true
    }
    private var templateSizeOptionsMenu: UIMenu {
        var sizeActions = [UIAction]()
        for templateSizeModel in self.varaintsData.variantsDataModel.sizes {
            let displayTitle = templateSizeModel.size.displayTitle
            let isSelected =  templateSizeModel.size == self.varaintsData.selectedVariantsAndTheme.size
            let state: UIMenuElement.State = isSelected ? .on : .off
            let action = UIAction(title: displayTitle,state: state) { [weak self]action in
                self?.paperSizeBtn.setTitle(action.title, for: .normal)
                self?.varaintsData.selectedVariantsAndTheme.size = templateSizeModel.size
                if let templateSizeMenu = self?.paperSizeBtn?.menu {
                    self?.paperSizeBtn?.menu = self?.updateActionState(actionTitle: displayTitle, menu: templateSizeMenu)
                }
                if templateSizeModel.size == .mobile {
                    self?.varaintsData.selectedVariantsAndTheme.orientation = .portrait
                }
            }
            sizeActions.append(action)
        }
        return UIMenu(options: .displayInline, children: sizeActions)
    }
    private var orientaionOptionsMenu: UIMenu {

        let isPortraitSelected : UIMenuElement.State = (self.varaintsData.selectedVariantsAndTheme.orientation == .portrait) ? .on : .off
        let isLandscapeSelected : UIMenuElement.State = isPortraitSelected == .on ? .off : .on
        let menuSubTitle = isPortraitSelected == .on ? FTTemplateOrientation.portrait.title : FTTemplateOrientation.landscape.title

        func orientationMenuElement(for orientation: FTTemplateOrientation) -> UIAction {
            let state: UIMenuElement.State = orientation == .portrait ? isPortraitSelected : isLandscapeSelected
           return UIAction(title: orientation.title,image: orientation.image,state: state, handler: { [weak self] _ in
                self?.varaintsData.selectedVariantsAndTheme.orientation = orientation
                if let templateSizeMenu = self?.paperSizeBtn?.menu {
                    self?.paperSizeBtn?.menu = self?.updateOrientationSubTitleInMenu(orientation, menu: templateSizeMenu)
                }
            })
        }

        let orientationMenu = UIMenu(title: orientationLoclizdStrng,subtitle: menuSubTitle, image: UIImage(systemName: "ipad"),children: [
            orientationMenuElement(for: .landscape),
            orientationMenuElement(for: .portrait)
        ])
        return orientationMenu
    }
    private func updateOrientationSubTitleInMenu(_ oriention:FTTemplateOrientation, menu: UIMenu) -> UIMenu {
        menu.children.forEach { child in
            guard let menu =  child as? UIMenu else {
                return
            }
            if menu.title == orientationLoclizdStrng {
                menu.subtitle = oriention.title
                menu.children.forEach { action in
                    guard let action =  action as? UIAction else {
                        return
                    }
                    action.state = action.title == oriention.title ? .on : .off
                }
            } else {
                menu.children.forEach { action in
                    guard let action =  action as? UIAction else {
                        return
                    }
                    action.state = action.title == self.varaintsData.selectedVariantsAndTheme.size.displayTitle ? .on : .off
                }
            }
        }
        return menu
    }
    private func updateActionState(actionTitle: String? = nil, menu: UIMenu) -> UIMenu {
        func updateActionState(_ action:UIMenuElement) {
            guard let action =  action as? UIAction else {
                return
            }
            action.state = action.title == actionTitle ? .on : .off
        }
        var filteredMenuChildren : [UIMenu] = [UIMenu]()
        if self.traitCollection.isRegular {
            filteredMenuChildren = [templateSizeOptionsMenu]
        } else {
            filteredMenuChildren = varaintsData.selectedVariantsAndTheme.size == FTTemplateSize.mobile ? [templateSizeOptionsMenu] : [templateSizeOptionsMenu,orientaionOptionsMenu]
        }
        
        if actionTitle != nil {
            filteredMenuChildren.forEach { child in
                if self.traitCollection.isRegular {
                    updateActionState(child)
                }else {
                    guard child.title == "" else {
                        return
                    }
                    menu.children.forEach { child in
                        updateActionState(child)
                    }
                }
            }
        } else {
            let action = filteredMenuChildren.first?.children as? UIAction
            action?.state = .on
        }
        return UIMenu(identifier: UIMenu.Identifier("SizesMenu"), children: filteredMenuChildren)
    }
}
