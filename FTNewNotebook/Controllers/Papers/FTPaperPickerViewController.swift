//
//  FTPaperPickerViewController.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 24/02/23.
//

import UIKit
import AVFoundation

protocol FTPaperPickerDelegate: NSObject {
    func didTapMoreTempates()
    func didCancelPaperSelection()
    func didChoosePaperTemplateWithVariants(_ themeWithVariants: FTSelectedPaperVariantsAndTheme, previewImage:UIImage?)
    func paperSizeBasedOnOrientaion(_ orientaion: FTTemplateOrientation) -> CGRect
    func resetPaperToPreviousSelected() -> CGRect
    func animateShowContentViewBasedOn(themeType:FTThemeType)
    func animateHideContentViewBasedOn(themeType: FTThemeType)
    func handleShowAnimationCompletion(themeType: FTThemeType)
}

class FTPaperPickerViewController: UIViewController {

    @IBOutlet weak var choosePaperContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var templateSizeButton: UIButton?
    @IBOutlet weak private var previewView: UIView?
    @IBOutlet weak private var previewImageView: UIImageView?
    @IBOutlet weak private var previewViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak private var previewViewHeightConstraint: NSLayoutConstraint?

    @IBOutlet weak var previewImageWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var previewViewLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var previewViewTrailingConstraint: NSLayoutConstraint?
    @IBOutlet weak private var choosePaperViewHeightConstraint: NSLayoutConstraint?

    @IBOutlet weak var previewViewHorizontalAlignConstrnt: NSLayoutConstraint?
    @IBOutlet weak var previewViewVerticalAlignConstrnt: NSLayoutConstraint?
    @IBOutlet weak var previewImgViewHightConstrnt: NSLayoutConstraint!

    @IBOutlet weak var panelContainerView: UIView?

    let landscapeLoclizdStrng = NSLocalizedString("Landscape", comment: "Landscape")
    let portraitLoclizdStrng =  NSLocalizedString("Portrait", comment: "Portrait")
    let orientationLoclizdStrng = NSLocalizedString("shelf.paperPicker.orientation", comment: "Orientation")
    var paperVariantsDataModel: FTPaperTemplatesVariantsDataModel!
    var selectedPaperVariantsAndTheme: FTSelectedPaperVariantsAndTheme!
    var basicPaperThemes: FTBasicTemplateCategoryModel!
    weak var paperPickerDelegate: FTPaperPickerDelegate?
    private var size: CGSize = .zero
    private var initialPreviewImage: UIImage?
    private var bottomPanelHeight: CGFloat {
        if self.traitCollection.horizontalSizeClass == .regular {
            if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
                return 340
            }else {
                return 311
            }
        } else {
            return 311
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panelContainerView?.addShadow(color: UIColor.label.withAlphaComponent(0.2), offset: CGSize(width: 0, height: 8), opacity: 1.0, shadowRadius: 64.0)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let paperTemplateVc = segue.destination.children.first(where: { vc in
            vc is FTChoosePaperViewController
        }) as? FTChoosePaperViewController {
            paperTemplateVc.choosePaperDelegate = self
            paperTemplateVc.paperVariantsDataModel = paperVariantsDataModel
            paperTemplateVc.selectedPaperVariantsAndTheme = selectedPaperVariantsAndTheme
            paperTemplateVc.basicPaperThemes = basicPaperThemes
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            setUpPreviewSize()
            setBottomPanelHeight()
            configureTemplateSizesMenu()
        }

    }
    private func setupUI() {
        if selectedPaperVariantsAndTheme.size == .mobile {
            selectedPaperVariantsAndTheme.orientation = .portrait
        }
        setUpPreviewSize()
        setAttributedTextToTemplateSizeButton(self.selectedPaperVariantsAndTheme.size)
        configureTemplateSizesMenu()
        setBottomPanelHeight()
        setShadowToPreview()
    }
    private func setBottomPanelHeight(){
        self.choosePaperViewHeightConstraint?.constant = bottomPanelHeight
    }
    //MARK: Template sizes menu
    private func configureTemplateSizesMenu() {
        if self.traitCollection.isRegular {
            self.templateSizeButton?.menu = templateSizeOptionsMenu
        } else {
            let menuElements: [UIMenuElement] = selectedPaperVariantsAndTheme.size == FTTemplateSize.mobile ? [templateSizeOptionsMenu] : [templateSizeOptionsMenu,orientaionOptionsMenu]
            self.templateSizeButton?.menu = UIMenu(identifier: UIMenu.Identifier("SizesMenu") ,children:menuElements)
        }
        self.templateSizeButton?.showsMenuAsPrimaryAction = true
    }
    private var templateSizeOptionsMenu: UIMenu {
        var sizeActions = [UIAction]()
        for templateSizeModel in paperVariantsDataModel.sizes.reversed() {
            let displayTitle = templateSizeModel.size.displayTitle
            let isSelected =  templateSizeModel.size == self.selectedPaperVariantsAndTheme.size
            let state: UIMenuElement.State = isSelected ? .on : .off
            let action = UIAction(title: displayTitle,state: state) { [weak self]action in
                let resizeThumbnail = self?.selectedPaperVariantsAndTheme.size != templateSizeModel.size
                self?.selectedPaperVariantsAndTheme.size = templateSizeModel.size
                self?.setAttributedTextToTemplateSizeButton(templateSizeModel.size)
                self?.setThumbnailToPreviewImageView(toResize: resizeThumbnail)
                if let templateSizeMenu = self?.templateSizeButton?.menu {
                    self?.templateSizeButton?.menu = self?.updateActionState(actionTitle: displayTitle, menu: templateSizeMenu)
                }
                if templateSizeModel.size == .mobile {
                    self?.selectedPaperVariantsAndTheme.orientation = .portrait
                }
                self?.updateOrientationOptionVisibility(displayTitle == FTTemplateSize.mobile.displayTitle)
            }
            sizeActions.append(action)
        }
        return UIMenu(options: .displayInline, children: sizeActions)
    }
    private var orientaionOptionsMenu: UIMenu {
        let isPortraitSelected : UIMenuElement.State = (selectedPaperVariantsAndTheme.orientation == .portrait) ? .on : .off
        let isLandscapeSelected : UIMenuElement.State = isPortraitSelected == .on ? .off : .on
        let menuSubTitle = isPortraitSelected == .on ? portraitLoclizdStrng : landscapeLoclizdStrng

        let orientationMenu = UIMenu(title: orientationLoclizdStrng,subtitle: menuSubTitle, image: UIImage(systemName: "ipad"),children: [
            UIAction(title: landscapeLoclizdStrng,image: UIImage(systemName: "ipad.landscape"),state: isLandscapeSelected, handler: { [weak self] _ in
                let resizeThumbnail = self?.selectedPaperVariantsAndTheme.orientation != .landscape
                self?.selectedPaperVariantsAndTheme.orientation = .landscape
                self?.setThumbnailToPreviewImageView(toResize: resizeThumbnail)
                if let templateSizeMenu = self?.templateSizeButton?.menu {
                    self?.templateSizeButton?.menu = self?.updateOrientationSubTitleInMenu(.landscape, menu: templateSizeMenu)
                }
            }),
            UIAction(title: portraitLoclizdStrng,image: UIImage(systemName: "ipad"),state: isPortraitSelected, handler: { [weak self] _ in
                let resizeThumbnail = self?.selectedPaperVariantsAndTheme.orientation != .portrait
                self?.selectedPaperVariantsAndTheme.orientation = .portrait
                self?.setThumbnailToPreviewImageView(toResize: resizeThumbnail)
                if let templateSizeMenu = self?.templateSizeButton?.menu {
                    self?.templateSizeButton?.menu = self?.updateOrientationSubTitleInMenu(.portrait, menu: templateSizeMenu)
                }
            })
        ])
        return orientationMenu
    }
    private func updateOrientationSubTitleInMenu(_ oriention:FTTemplateOrientation, menu: UIMenu) -> UIMenu {
        let subTitle = (oriention == .portrait) ? portraitLoclizdStrng : landscapeLoclizdStrng
        menu.children.forEach { child in
            guard let menu =  child as? UIMenu else {
                return
            }
            if menu.title == orientationLoclizdStrng {
                menu.subtitle = subTitle
                menu.children.forEach { action in
                    guard let action =  action as? UIAction else {
                        return
                    }
                    action.state = action.title == subTitle ? .on : .off
                }
            } else { // template sizes
                menu.children.forEach { action in
                    guard let action =  action as? UIAction else {
                        return
                    }
                    action.state = action.title == selectedPaperVariantsAndTheme.size.displayTitle ? .on : .off
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
        let menuChildren = menu.children
        var filteredMenuChildren : [UIMenu] = [UIMenu]()
        if self.traitCollection.isRegular {
            filteredMenuChildren = [templateSizeOptionsMenu]
        } else {
            filteredMenuChildren = selectedPaperVariantsAndTheme.size == FTTemplateSize.mobile ? [templateSizeOptionsMenu] : [templateSizeOptionsMenu,orientaionOptionsMenu]
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
    //MARK: Template size button code
    private func setAttributedTextToTemplateSizeButton(_ templateSize: FTTemplateSize) {
        let aspectRatioImage = UIImage(systemName: "aspectratio")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 13))).withTintColor(FTNewNotebook.Constants.SelectedAccent.tint)
        let chevronImage = UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 11))).withTintColor(FTNewNotebook.Constants.SelectedAccent.tint )
        let title = templateSize.displayTitle

        let aspectRatioimageAttachment = NSTextAttachment()
        aspectRatioimageAttachment.image = aspectRatioImage
        let chevronAttachment = NSTextAttachment()
        chevronAttachment.image = chevronImage
        let attributedString = NSMutableAttributedString(attachment: aspectRatioimageAttachment)
        let titleAttributedString = NSAttributedString(string: "  " + title + "  ",attributes: [.font: UIFont.appFont(for: .medium, with: 13), .foregroundColor : FTNewNotebook.Constants.SelectedAccent.tint])
        attributedString.append(titleAttributedString)
        let chevronString = NSAttributedString(attachment: chevronAttachment)
        attributedString.append(chevronString)

        self.templateSizeButton?.setAttributedTitle(attributedString, for: .normal)
    }
    //MARK: Preview Size Calculations
    private func sizeForPreviewView() -> CGSize {
        let previewConstants = FTNewNotebook.Constants.ChoosePaperPanel.preview.self
        if self.traitCollection.horizontalSizeClass == .regular {
            if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
                //return getPreviewViewSizeDynamicallyForImage()
                return self.selectedPaperVariantsAndTheme.orientation == .portrait ? previewConstants.regularPortraitOrientationPortraitSize :  previewConstants.regularPortraitOrientationLandscapeSize
            }else {
                return self.selectedPaperVariantsAndTheme.orientation == .portrait ? previewConstants.regularLandscapeOrientationPortraitSize :  previewConstants.regularLanscapeOrientationLandscapeSize
            }
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return getCompactPreviewSize()
            }else {
                return CGSize(width: 152 , height: 224)
            }
        }
    }
    private func getCompactSizePreviewImagePadding() -> CGFloat {
        let portaitPadding: CGFloat = self.view.frame.width >= 375 ? 62 : 34
        let landscapedPadding: CGFloat = self.view.frame.width >= 375 ? 34 : 16
        let padding = self.selectedPaperVariantsAndTheme.orientation == .portrait ? portaitPadding : landscapedPadding
        return padding
    }
    private func getCompactPreviewSize() -> CGSize {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if self.view.frame.width < 420 {
                return self.selectedPaperVariantsAndTheme.orientation == .portrait ? CGSize(width: 252, height: 336):CGSize(width: 288, height: 216)
            }else {
                let previewConstants = FTNewNotebook.Constants.ChoosePaperPanel.preview.self
                if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
                    return self.selectedPaperVariantsAndTheme.orientation == .portrait ? previewConstants.regularPortraitOrientationPortraitSize :  previewConstants.regularPortraitOrientationLandscapeSize
                }else {
                    return self.selectedPaperVariantsAndTheme.orientation == .portrait ? previewConstants.regularLandscapeOrientationPortraitSize :  previewConstants.regularLanscapeOrientationLandscapeSize
                }
            }
        }else {
            return self.selectedPaperVariantsAndTheme.orientation == .portrait ? CGSize(width: 252, height: 336):CGSize(width: 288, height: 216)
        }
    }
    private func getPreviewViewSizeDynamicallyForImage(_ image: UIImage) -> CGSize {
        let horizontalMargin: CGFloat = (self.view.frame.width > self.view.frame.height) ? 152 : 88
        let verticalMargin: CGFloat = 120
        let templateSizeButtonHeight: CGFloat = 48
        let availableSpaceSize = CGSize(width: self.view.frame.width - horizontalMargin, height: self.view.frame.height - bottomPanelHeight - verticalMargin - templateSizeButtonHeight)


        let availableWidth = self.view.frame.width - horizontalMargin
        let gutterWidth: CGFloat = 24
        let totalColumnWidth = availableWidth - 8*gutterWidth
        let eachColumnWidth = totalColumnWidth/9
        let maxWidth = self.selectedPaperVariantsAndTheme.orientation == .portrait ?  ((eachColumnWidth*5) + 4*24) :  ((eachColumnWidth*7) + 6*24)
        let previewMaxWidth = (self.view.frame.width > self.view.frame.height) ? ((eachColumnWidth*5) + 4*24) : maxWidth
        let previewMaxHeight = availableSpaceSize.height
        let aspectRect = AVMakeRect(aspectRatio:image.size , insideRect: CGRect(x: 0, y: 0, width: previewMaxWidth, height: previewMaxHeight))
        return aspectRect.size
    }
    private func getCompctPreviewImgMaxSize() -> CGSize {
        let padding = self.getCompactSizePreviewImagePadding()
        let maxWidth = self.view.frame.width - padding
        var maxheight = 336
        if UIDevice.current.userInterfaceIdiom == .phone, self.view.frame.width < 375 {
            maxheight = 164
        }
        if self.selectedPaperVariantsAndTheme.orientation == .landscape {
            maxheight -= 50
        }
        return CGSize(width: CGFloat(maxWidth), height: CGFloat(maxheight))
    }

//MARK: Preview Constraints and Thumbnail
    private func setUpPreviewSize(){
        if self.traitCollection.isRegular {
            self.previewViewWidthConstraint?.constant = self.sizeForPreviewView().width
            self.previewViewHeightConstraint?.constant =   self.sizeForPreviewView().height
            self.previewView?.setNeedsLayout()
        } else {
            if self.view.frame.width < 420 {
                let padding = getCompactSizePreviewImagePadding()
                self.previewViewLeadingConstraint?.constant = padding
                self.previewViewTrailingConstraint?.constant = padding
            }else {
                self.previewViewLeadingConstraint?.isActive = false
                self.previewViewTrailingConstraint?.isActive = false
            }
        }
    }
    private func centerPreviewViewVerticallyCenter(){
        let heightWthOutBtmPanel = self.view.frame.height - bottomPanelHeight
        let topRect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: heightWthOutBtmPanel)
        self.previewViewVerticalAlignConstrnt?.constant = getCenterXandY(from: topRect).y
    }
    private func fetchPaperPreview( completionhandler: @escaping (_ thumbImage : UIImage?)->()){
        guard let paperTheme = (self.selectedPaperVariantsAndTheme.theme as? FTPaperThumbnailGenerator)    else {
            fatalError("Type case error while trying to generate paper thumb")
        }
        paperTheme.generateThumbnailFor(selectedVariantsAndTheme: self.selectedPaperVariantsAndTheme, forPreview: true, completionhandler: completionhandler)
    }
    private func setThumbnailToPreviewImageView(toResize:Bool = false) {
        if toResize {
            Task {
                await self.resizePaperPreviewViewAndSetThumbnail()
            }
        }else {
            self.fetchPaperPreview { thumbImage in
                DispatchQueue.main.async {
                    self.previewImageView?.image = thumbImage?.resizedImageWithinRect(self.sizeForPreviewView())
                }
            }
        }
    }
    private func resizePaperPreviewViewAndSetThumbnail() async {
        fetchPaperPreview { thumbImage in
            DispatchQueue.main.async {
                if !self.traitCollection.isRegular , self.view.frame.width < 420 {
                        let maxPreviewImgSize = self.getCompactPreviewSize()
                        if let image = thumbImage?.resizedImageWithinRect(maxPreviewImgSize) {

                            self.updateConstraintOfPreviewToSize(image.size)
                            self.previewImageView?.image = image
                            self.setInitialPreviewImage(image)
                        }
                }else{
                    let aspectSize = self.getPreviewViewSizeDynamicallyForImage(thumbImage!)
                    self.previewImageView?.image = thumbImage?.resizedImage(aspectSize)
                    if let previewImage = self.previewImageView?.image {
                        self.updateConstraintOfPreviewToSize(previewImage.size)
                        self.setInitialPreviewImage(previewImage)
                    }
                }
            }
        }
    }
    private func updateConstraintOfPreviewToSize(_ size: CGSize) {
        self.previewViewHeightConstraint?.constant = size.height
        self.previewViewWidthConstraint?.constant = size.width
        self.previewView?.layoutIfNeeded()
    }
    private func setInitialPreviewImage(_ image:UIImage?){
        if initialPreviewImage == nil {
            initialPreviewImage = image
        }
    }
    private func setShadowToPreview(){
        self.previewImageView?.addShadow(color: UIColor.appColor(.black28), offset: CGSize(width: 0, height: 24), opacity: 1, shadowRadius: 40)
    }
    private func updateOrientationOptionVisibility(_ shouldHide: Bool){
        let choosePaperController = (self.children.first as? UINavigationController)?.viewControllers.first
        if let children = choosePaperController?.children {
            for childVC in children where childVC as? FTPaperTemplatesVariantsController != nil {
                (childVC as? FTPaperTemplatesVariantsController)?.updateOrientationSegmentVisibility(shouldHide)
            }
        }
    }

//MARK: Animations Code
    func openPreview(from frame: CGRect, onCompletion: (() -> Void)?) {
        self.choosePaperContainerViewBottomConstraint?.constant = -500.0
        let centerXandY = self.getCenterXandY(from: frame)

        self.previewViewHorizontalAlignConstrnt?.constant = centerXandY.x
        self.previewViewVerticalAlignConstrnt?.constant = centerXandY.y
        self.updateConstraintOfPreviewToSize(frame.size)
        self.templateSizeButton?.alpha = 0.0
        self.previewView?.setNeedsLayout()
        self.view.layoutIfNeeded()
        fetchPaperPreview { thumbImage in
            DispatchQueue.main.async {
                self.previewImageView?.image = thumbImage?.resizedImageWithinRect(frame.size)
                let heightWthOutBtmPanel = self.view.frame.height - self.bottomPanelHeight
                let topRect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: heightWthOutBtmPanel)
                if let thumbImage = thumbImage {
                    let paperPreviewSize: CGSize = self.traitCollection.isRegular ? self.getPreviewViewSizeDynamicallyForImage(thumbImage) : self.getCompactPreviewSize()
                    UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   options: .curveEaseOut,
                                   animations: {
                        self.paperPickerDelegate?.animateHideContentViewBasedOn(themeType: .paper)
                        // Bottom Panel
                        self.choosePaperContainerViewBottomConstraint?.constant = 0.0
                        //
                        // Paper Preview
                        self.previewViewHorizontalAlignConstrnt?.constant = 0.0
                        self.previewViewVerticalAlignConstrnt?.constant = self.getCenterXandY(from: topRect).y

                        self.previewImageView?.image = thumbImage.resizedImageWithinRect(paperPreviewSize)
                        let aspectFittedImage = thumbImage.resizedImageWithinRect(paperPreviewSize)
                        self.setInitialPreviewImage(aspectFittedImage)
                        self.updateConstraintOfPreviewToSize(aspectFittedImage.size)
                        self.previewView?.setNeedsLayout()
                        self.view.layoutIfNeeded()
                    }) { _ in
                        self.templateSizeButton?.alpha = 1.0
                        onCompletion?()
                    }
                }
            }
        }
    }
    func closePreview(to frame: CGRect,isCancelled: Bool = false, onCompletion: @escaping () -> Void) {
        self.view.layoutIfNeeded()
        if isCancelled, let previewImage = initialPreviewImage {
            self.previewImageView?.image = previewImage
        }
        self.templateSizeButton?.alpha = 0.0
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            self.paperPickerDelegate?.animateShowContentViewBasedOn(themeType:.paper)
            // Bottom Panel
            self.choosePaperContainerViewBottomConstraint?.constant = -500

            // Paper Preview
            let centerXandY = self.getCenterXandY(from: frame)

            self.previewViewHorizontalAlignConstrnt?.constant = centerXandY.x
            self.previewViewVerticalAlignConstrnt?.constant = centerXandY.y
            self.previewViewWidthConstraint?.constant = frame.size.width
            self.previewViewHeightConstraint?.constant = frame.size.height
            self.previewView?.setNeedsLayout()
            self.view.layoutIfNeeded()
        }) { _ in
            self.paperPickerDelegate?.handleShowAnimationCompletion(themeType: .paper)
            onCompletion()
        }
    }
    private func getCenterXandY(from frame: CGRect) -> CGPoint {
        let centerX = frame.origin.x + frame.size.width/2 - self.view.frame.width/2
        let centerY = frame.origin.y + frame.size.height/2 - self.view.frame.height/2
        return CGPoint(x: centerX, y: centerY)
    }
}
extension FTPaperPickerViewController: FTChoosePaperDelegate {
    func didTapMoreTempates() {
        self.paperPickerDelegate?.didTapMoreTempates()
    }

    func updatePaperPreviewWith(_ paperTemplate: FTThemeable) {
        self.selectedPaperVariantsAndTheme.theme = paperTemplate
        self.setThumbnailToPreviewImageView()
    }
    func updatePaperVaraints(_ variants: FTSelectedPaperVariantsAndTheme) {
        self.selectedPaperVariantsAndTheme.templateColorModel = variants.templateColorModel
        self.selectedPaperVariantsAndTheme.lineHeight = variants.lineHeight
        let resizeThumbnail = self.selectedPaperVariantsAndTheme.orientation != variants.orientation
        if self.traitCollection.isRegular {
            self.selectedPaperVariantsAndTheme.orientation = variants.orientation
        }
        self.setThumbnailToPreviewImageView(toResize: resizeThumbnail)
    }
    func didTapCancel() {
        guard let paperFrame = self.paperPickerDelegate?.resetPaperToPreviousSelected()
        else {
            return
        }
        self.closePreview(to: paperFrame,isCancelled:true) {
            self.remove()
            self.paperPickerDelegate?.didCancelPaperSelection()
        }
    }
    func didChoosePaperWithVariants(_ themeWithVariants: FTSelectedPaperVariantsAndTheme) {
        var themeWithVariants = themeWithVariants
        themeWithVariants.size = self.selectedPaperVariantsAndTheme.size
        if !self.traitCollection.isRegular {
            themeWithVariants.orientation = self.selectedPaperVariantsAndTheme.orientation
        }
        self.paperPickerDelegate?.didChoosePaperTemplateWithVariants(themeWithVariants, previewImage: self.previewImageView?.image)
        guard let paperFrame = self.paperPickerDelegate?.paperSizeBasedOnOrientaion(self.selectedPaperVariantsAndTheme.orientation)
        else {
            return
        }
        self.closePreview(to: paperFrame) {
            self.remove()
        }
    }
}
