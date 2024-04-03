//
//  FTCreateNotebookViewController.swift
//  NewNotebook
//
//  Created by Ramakrishna on 17/02/23.
//

import UIKit
import FTCommon
import FTStyles

public protocol FTCoversInfoDelegate: FTCustomCoverInfoDelegate {
    func fetchCoversData() -> [FTCoverSectionModel]
    func fetchNoCoverTheme() -> FTThemeable?
    func fetchPreviousSelectedCoverTheme() -> FTThemeable
    func didUpdateCover(_ theme: FTThemeable?)
    func setDefaultCoverTheme(_ cover: FTThemeable)
}

public protocol FTPapersInfoDelegate: AnyObject {
    var paperVariantsDataModel: FTPaperTemplatesVariantsDataModel {get}
    var paperThemes:FTBasicTemplateCategoryModel{get}
    var selectedPaperVariantsAndTheme: FTSelectedPaperVariantsAndTheme{get}
}

public protocol FTCreateNotebookDelegate: FTCoversInfoDelegate, FTPapersInfoDelegate {
    func didTapMoreTempates()
    func createNotebookWithModel(_ notebookDetailsModel: FTNewNotebookModel)
    func openPasswordController(on controller: UIViewController, at sourceView: UIView?,passwordDetails: FTPasswordModel?)
}

public class FTCreateNotebookViewController: UIViewController {
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var closeBtn: UIButton?
    @IBOutlet private weak var noCoverLabel: UILabel?
    @IBOutlet private weak var chooseCoverView: UIView?
    @IBOutlet private weak var previewStackView: UIStackView?
    @IBOutlet private weak var notebookTitleAndPasswordView: UIView?
    @IBOutlet private weak var coverImageView: UIImageView?
    @IBOutlet private weak var coverTitleLabel: UILabel?
    @IBOutlet private weak var paperImageView: UIImageView?
    @IBOutlet private weak var paperTitleLabel: UILabel?
    @IBOutlet private weak var paperImageViewHeight: NSLayoutConstraint?
//    @IBOutlet private weak var paperImageViewWidth: NSLayoutConstraint?
    @IBOutlet private weak var paperImageViewTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var paperPickerViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var pwdButton: UIButton?
    @IBOutlet private weak var notebookTitleTextfield: UITextField?
    @IBOutlet private weak var createNotebookButton: UIButton?
    @IBOutlet private weak var choosePaperView: UIView?
    @IBOutlet private weak var scrollView: UIScrollView?

    @IBOutlet weak var coverShadowView: UIView?

    @IBOutlet weak var previewStackViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var containerView: UIView?
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var previewStackViewHeightConstraint: NSLayoutConstraint!
    public weak var delegate: FTCreateNotebookDelegate?

    @IBOutlet weak var chooseCoverHeightConstrnt: NSLayoutConstraint?
    @IBOutlet weak var choosePaperViewHeightConstrnt: NSLayoutConstraint?
    @IBOutlet weak var coverPreviewViewWidthConstraint: NSLayoutConstraint?
    private var passwordDetails: FTPasswordModel?
    private var isLandscapePaper:Bool {
        self.newNotebookDetails?.selectedPaperWithVariants.orientation == .landscape
    }
    private var size: CGSize = .zero

    private var customTransitionDelegate = FTModalScaleTransitionDelegate();
    
    private var paperImageViewTopConstraintConstant: CGFloat {
        if self.traitCollection.isRegular {
            if isLandscapePaper {
                return 74
            }
        }else {
            if isLandscapePaper {
                return ((self.previewStackView?.frame.height ?? 190)/2) - 32
            }
        }
        return 0
    }
    private var coverImage: UIImage? = UIImage(named: "sampleCover", in: currentBundle, with: nil)
    private var paperImage: UIImage? = UIImage(named: "samplePaperPreview", in: currentBundle, with: nil)
    private var viewBGColor: UIColor? = UIColor.appColor(.createNotebookViewBG)
    private var newNotebookDetails: FTNewNotebookModel?
    private var chevronString : NSAttributedString {
        let chevronImage = UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 11))).withTintColor(UIColor.appColor(.black70))
        let chevronAttachment = NSTextAttachment()
        chevronAttachment.image = chevronImage
        return NSAttributedString(attachment: chevronAttachment)
    }


    public override func viewDidLoad() {
        super.viewDidLoad()
        self.noCoverLabel?.text = "covers.category.noCover".localized.capitalized
        self.noCoverLabel?.isHidden = true
        self.updateNewNotebookDetails()
        self.view.layoutIfNeeded()
        self.setUpView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
#if targetEnvironment(macCatalyst)
        self.view.addVisualEffectBlur(style: .light,cornerRadius: 0);
        self.navigationController?.view.backgroundColor = .clear
        self.closeBtn?.isHidden = true;
#endif
    }
    override public func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    private func setUpView(){
        self.view.backgroundColor = viewBGColor
        self.setUpTitleView()
        self.setUpCreateNotebookButton()
        self.setUpPreviewStackViewForScreenSize(self.view.frame.size)
        self.configPaperPickerBasedOnScrnSize(self.view.frame.size)
        self.configCoverPickerBasedOnScrnSize(self.view.frame.size)
        self.updatePasswordStatus()
        self.notebookTitleTextfield?.placeholder = "shelf.createNotebook.MyNotebook".localized
        self.notebookTitleTextfield?.delegate = self
        Task {
            if let themeWithVariants = newNotebookDetails?.selectedPaperWithVariants {
                await setPaperTemplateWithVarinats(themeWithVariants)
            }
        }
    }
    private func setUpTitleView() {
        self.notebookTitleAndPasswordView?.dropShadowWith(color:FTNewNotebook.Constants.ShadowColor.titleView,offset: FTNewNotebook.Constants.ShadowOffset.titleView,radius: FTNewNotebook.Constants.ShadowRadius.titleView)
        let clearButton = UIButton(type: .custom)
        clearButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        let clearIcon = UIImage(systemName:"xmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
        clearButton.setImage(clearIcon, for: .normal)
        clearButton.tintColor = UIColor.appColor(.black40)
        clearButton.addTarget(self, action: #selector(clearNotebookTitle), for: .allEvents)
        notebookTitleTextfield?.rightView = clearButton
        notebookTitleTextfield?.delegate = self
        notebookTitleTextfield?.rightViewMode = .whileEditing
    }
    private func setUpCreateNotebookButton(){
        self.createNotebookButton?.dropShadowWith(color: FTNewNotebook.Constants.ShadowColor.newNotebookButton, offset: FTNewNotebook.Constants.ShadowOffset.newNotebookButton, radius: FTNewNotebook.Constants.ShadowRadius.newNotebookButton)
    }
    @IBAction func dismissNotebookCreationProcess(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    // MARK:- Keyboard
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        self.scrollView?.isScrollEnabled = true
        self.scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: (keyboardViewEndFrame.height + 28) - view.safeAreaInsets.bottom, right: 0)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        self.scrollView?.contentInset = UIEdgeInsets.zero
        self.scrollView?.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    //MARK: Notebook Password
    @IBAction func showPasscodeView(_ sender: UIButton) {
        if passwordDetails == nil {
            // Opening set password screen for setting NB password
            delegate?.openPasswordController(on: self, at: sender, passwordDetails: passwordDetails)
        } else {
            // Removing Password
            passwordDetails = nil
            self.newNotebookDetails?.passwordDetails = FTPasswordModel()
            updatePasswordStatus()
        }
     }
    private func updatePasswordStatus(){
        var lockIcon = UIImage(systemName: "lock.open")?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .semibold, with: 11))).withTintColor(FTNewNotebook.Constants.SelectedAccent.tint)
        var title = NSLocalizedString("shelf.createNotebook.addPwd", comment: "Add a Password")
        if let passwordDetails =  passwordDetails, !(passwordDetails.pin ?? "").isEmpty {
            title = NSLocalizedString("shelf.createNotebook.removePassword", comment: "Remove password")
            lockIcon = UIImage(systemName: "trash")?.withConfiguration(UIImage.SymbolConfiguration(font:UIFont.appFont(for: .semibold, with: 11))).withTintColor(FTNewNotebook.Constants.SelectedAccent.tint)
        }
        let lockIconAttachment = NSTextAttachment()
        lockIconAttachment.image = lockIcon
        let attributedString = NSMutableAttributedString(attachment: lockIconAttachment)
        let titleAttributedString = NSAttributedString(string: "  " + title ,attributes: [  .font: UIFont.appFont(for: .medium, with: 13), .foregroundColor : FTNewNotebook.Constants.SelectedAccent.tint ])
        attributedString.append(titleAttributedString)
        self.pwdButton?.setAttributedTitle(attributedString, for: .normal)
    }
    //MARK: Cover Picker
    private func updateCoverImage(_ image: UIImage?) {
        let coverPreviewViewSize = getCoverPreviewSizeBasedOn(size)
        self.coverImageView?.image = image?.resizedImage(coverPreviewViewSize)
        self.setShadowToCoverPreview()
        self.setCornersToCoverPreview()
        self.setNoCoverTextIfNeeded()
    }
    private func configCoverPickerBasedOnScrnSize(_ size: CGSize) {
        self.coverPreviewViewWidthConstraint?.isActive = size.width > 560 ? true : false
        let coverPreviewViewSize = getCoverPreviewSizeBasedOn(size)
        self.coverPreviewViewWidthConstraint?.constant = coverPreviewViewSize.width
        self.chooseCoverHeightConstrnt?.constant = coverPreviewViewSize.height
        self.chooseCoverView?.setNeedsLayout()
        self.previewStackView?.layoutIfNeeded()
        self.updateCoverImage(self.newNotebookDetails?.selectedCoverTheme?.themeThumbnail())
        let gesture = UITapGestureRecognizer(target: self, action: #selector(chooseCoverTapped(_ :)))
        self.chooseCoverView?.addGestureRecognizer(gesture)
        self.setTitleTextToCoverLabel(coverTitle: NSLocalizedString("shelf.createNotebook.coverTitle", comment: "Cover"))
    }
    private func setCornersToCoverPreview(){
        if let coverTheme = newNotebookDetails?.selectedCoverTheme, coverTheme.hasCover {
            let coverCornerRadiusConstants = FTNewNotebook.Constants.SelectedCoverRadius.self
            self.coverImageView?.roundCorners(topLeft: coverCornerRadiusConstants.topLeft, topRight: coverCornerRadiusConstants.topRight, bottomLeft: coverCornerRadiusConstants.bottomLeft, bottomRight: coverCornerRadiusConstants.bottomRight)
        } else {
            let coverCornerRadiusConstants = FTNewNotebook.Constants.NoCoverRadius.self
            self.coverImageView?.roundCorners(topLeft: coverCornerRadiusConstants.allCorners, topRight: coverCornerRadiusConstants.allCorners, bottomLeft: coverCornerRadiusConstants.allCorners, bottomRight: coverCornerRadiusConstants.allCorners)
        }
    }

    private func setShadowToCoverPreview() {
        if let coverTheme = newNotebookDetails?.selectedCoverTheme {
            if coverTheme.hasCover {
                coverShadowView?.layer.shadowPath = UIBezierPath(
                    roundedRect: coverShadowView?.bounds ?? .zero,
                    cornerRadius: 14).cgPath
                self.coverShadowView?.addShadow(color: UIColor.appColor(.black28), offset: CGSize(width: 0, height: 24), opacity: 1, shadowRadius: 40)
            }else{
                self.coverShadowView?.removeShadow()
            }
        }
    }

    private func setNoCoverTextIfNeeded() {
        self.noCoverLabel?.isHidden = true
        if let coverTheme = newNotebookDetails?.selectedCoverTheme, !coverTheme.hasCover {
            self.noCoverLabel?.isHidden = false
        }
    }

    @objc private func chooseCoverTapped(_ gesture: UITapGestureRecognizer) {
       let currentTheme = self.delegate?.fetchPreviousSelectedCoverTheme()
        if let chooseCoverVC = FTChooseCoverViewController.viewControllerInstance(coversInfoDelegate: self.delegate, currentTheme: currentTheme),let coverImgView = self.coverImageView {
            let initialFrame = coverImgView.convert(coverImgView.bounds, to: self.view)
            chooseCoverVC.coverUpdateDelegate = self
            self.add(chooseCoverVC)
            chooseCoverVC.openPreview(from: initialFrame, onCompletion: nil)
        }
    }
    
    //MARK: Preview Stackview
    private func setUpPreviewStackViewForScreenSize(_ size: CGSize){
        let stackViewSpacing = getStackViewSpacingBasedOnScreenSize(size)
        let previewStackViewSize = getPreviewStackViewSizeBasedOn(size)
        self.previewStackViewWidthConstraint?.constant = previewStackViewSize.width
        self.previewStackViewHeightConstraint.constant = previewStackViewSize.height
        self.previewStackView?.distribution = size.width > 700 ? .fillProportionally : (size.width > 375 ? .equalSpacing : .fillEqually)
        self.previewStackView?.spacing = stackViewSpacing
        self.previewStackView?.setNeedsLayout()
        self.containerView?.setNeedsLayout()
    }
    //MARK: Paper Picker
    @objc private func choosePaperTapped(_ gesture: UITapGestureRecognizer) {
        if let papersDelegate = delegate,
           let selectedPaperThemeAndVariants = newNotebookDetails?.selectedPaperWithVariants,
           let paperPickerVc = UIStoryboard(name: "FTPapers", bundle: currentBundle).instantiateInitialViewController() as? FTPaperPickerViewController, let paperImageView = self.paperImageView {
                    let initialFrame = paperImageView.convert(paperImageView.bounds, to: self.view)
                    paperPickerVc.paperPickerDelegate = self
                    paperPickerVc.paperVariantsDataModel = papersDelegate.paperVariantsDataModel
                    paperPickerVc.selectedPaperVariantsAndTheme = selectedPaperThemeAndVariants
                    paperPickerVc.basicPaperThemes = papersDelegate.paperThemes
                    paperPickerVc.modalPresentationStyle = .overFullScreen
                    paperPickerVc.view.frame = self.view.frame
                    self.add(paperPickerVc)
                    paperPickerVc.openPreview(from: initialFrame, onCompletion: nil)
        }
    }
    private func configPaperPickerBasedOnScrnSize(_ size: CGSize) {
        if let paperDisplayName = self.newNotebookDetails?.selectedPaperWithVariants.theme.displayName {
            self.setTitleTextToPaperLabel(paperDisplayName)
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(choosePaperTapped(_ :)))
        self.choosePaperView?.addGestureRecognizer(gesture)
        self.setPaperPreviewForScreenSize(size)
        self.setShadowToPaperPreview()
    }
    private func setPaperPreviewForScreenSize(_ size: CGSize){
        let paperPreviewSize = paperPreviewSizeBasedOnScrnSize(size, orientaion: self.newNotebookDetails?.selectedPaperWithVariants.orientation)
        self.choosePaperViewHeightConstrnt?.constant = paperPreviewSize.height + 48
        self.paperPickerViewWidthConstraint?.constant = paperPreviewSize.width
        self.choosePaperView?.layoutIfNeeded()
        self.previewStackView?.layoutIfNeeded()
    }
    private func setPaperTemplateWithVarinats(_ templateWithVariants: FTSelectedPaperVariantsAndTheme) {
        guard let paperTheme = (templateWithVariants.theme as? FTPaperThumbnailGenerator) else {
            return
        }
        let thumbImage = paperTheme.generateThumbnailFor(selectedVariantsAndTheme: templateWithVariants,forPreview:true)
        self.paperImage = thumbImage?.resizedImageWithinRect(self.paperPreviewSizeBasedOnScrnSize(self.view.frame.size,orientaion: self.newNotebookDetails?.selectedPaperWithVariants.orientation))
        self.paperImageView?.image = self.paperImage
    }

    private func setShadowToPaperPreview(){
        self.paperImageView?.addShadow(color: UIColor.appColor(.black28), offset: CGSize(width: 0, height: 24), opacity: 1, shadowRadius: 40)
    }

    //MARK: Layout size calculations
    private func getStackViewSpacingBasedOnScreenSize(_ size: CGSize) -> CGFloat {
        if size.width > 700 {
            if isLandscapePaper {
                return 44
            }
            return 68
        }else {
            if size.width > 560 {
                return 49
            }else {
                return size.width >= 375 ? 24 : 8
            }
        }
    }
    private func getPreviewStackViewSizeBasedOn(_ refSize: CGSize) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        if refSize.width > 700 {
            width = self.newNotebookDetails?.selectedPaperWithVariants.orientation == .portrait ? 516 : 566
            height = 330
        }
        else if refSize.width > 560 {
            width = 497
            height = 330
        } else if refSize.width >= 375 {
            width = 312
            height = 224
        } else {
            width = refSize.width - 32
            height = 219
        }
        return CGSize(width:width , height: height)
    }
    private func paperPreviewSizeBasedOnScrnSize(_ size: CGSize,orientaion: FTTemplateOrientation?) -> CGSize {
        let previewConstants = FTNewNotebook.Constants.PaperSize.self

        if size.width > 700 {
            return orientaion == .portrait ? previewConstants.Regular.portraitPaper :  previewConstants.Regular.landscapePaper
        } else {
            if size.width > 560 {
                return orientaion == .portrait ? previewConstants.Regular.portraitPaper : CGSize(width: 224, height: 173)
            } else if size.width > 375 {
                return orientaion == .portrait ? CGSize(width: 144, height: 192) : CGSize(width: 144, height: 109)
            } else {
                return orientaion == .portrait ?  CGSize(width: self.choosePaperView?.frame.width ?? 140 , height: self.previewStackView?.frame.height ?? 187) : CGSize(width: self.choosePaperView?.frame.width ?? 140 , height: (self.previewStackView?.frame.height ?? 187)/2)
            }
        }

    }
    private func getCoverPreviewSizeBasedOn(_ refSize: CGSize) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        if refSize.width > 560 {
            width = 224
            height = 330
        }else if refSize.width >= 375 {
            width = 144
            height = 224
        } else {// these will be dynamic
            width = 140
            height = 219
        }
        return CGSize(width: width, height: height)
    }
    //MARK: General
    private func updateNewNotebookDetails(){
        if let cover = self.delegate?.fetchPreviousSelectedCoverTheme() ,
           let themeWithVariants = self.delegate?.selectedPaperVariantsAndTheme {
            FTCurrentCoverSelection.shared.selectedCover = cover
            self.newNotebookDetails = FTNewNotebookModel(coverTheme: cover, selectedPaperWithVariants: themeWithVariants,passwordDetails: FTPasswordModel())
        }
    }
    private func setTitleTextToCoverLabel(coverTitle: String) { // setting attributed texts
        let coverTitle = coverTitle
        let coverAttributedText = NSMutableAttributedString(string: coverTitle + " ",attributes: [.font: UIFont.appFont(for: .medium, with: 13),.foregroundColor: UIColor.appColor(.black70)])
        coverAttributedText.append(chevronString)
        self.coverTitleLabel?.attributedText = coverAttributedText
    }
    private func setTitleTextToPaperLabel(_ paperTitle:String) {
        let paperAttributedText = NSMutableAttributedString(string: paperTitle + " ",attributes: [.font: UIFont.appFont(for: .medium, with: 13),.foregroundColor: UIColor.appColor(.black70)])
        paperAttributedText.append(chevronString)
        self.paperTitleLabel?.attributedText = paperAttributedText
    }
    @IBAction func didTapCreateNotebookButton(_ sender: UIButton) {
        self.notebookTitleTextfield?.endEditing(true)
        if var newNotebookDetails = self.newNotebookDetails {
            if newNotebookDetails.title.isEmpty {
                newNotebookDetails.title =  NSLocalizedString("shelf.createNotebook.MyNotebook", comment: "My Notebook")
            }
#if targetEnvironment(macCatalyst)
            self.dismiss(animated: true) { [weak self] in
                self?.delegate?.createNotebookWithModel(newNotebookDetails)
            }
#else
            self.delegate?.createNotebookWithModel(newNotebookDetails)
#endif
        }
    }

    static var del = FTModalScaleTransitionDelegate();
    public static func showFromViewController(_ viewController: UIViewController){
        if let createNotebookViewController = UIStoryboard.init(name: "FTNewNotebook", bundle: currentBundle).instantiateViewController(withIdentifier: "FTCreateNotebookViewController") as? FTCreateNotebookViewController {
            createNotebookViewController.delegate = viewController as? FTCreateNotebookDelegate
#if targetEnvironment(macCatalyst)
            createNotebookViewController.modalPresentationStyle = .formSheet;
            let navController = UINavigationController(rootViewController: createNotebookViewController);
            createNotebookViewController.title = "New Notebook";

            let insetBy: CGFloat = 20;
            var preferedSize = viewController.view.frame.insetBy(dx: insetBy, dy: 0).size;
            if let size = viewController.view.window?.windowScene?.sizeRestrictions?.minimumSize {
                preferedSize = CGSize(width: size.width - 2 * insetBy, height: size.height);
            }

            createNotebookViewController.preferredContentSize = preferedSize;
            navController.navigationBar.isTranslucent = false;
            
            navController.modalPresentationStyle = .formSheet;
            viewController.present(navController, animated: true) {
                let rightBar = FTNavBarButtonItem(type: .right, title: "Cancel".localized, delegate: createNotebookViewController);
                createNotebookViewController.navigationItem.rightBarButtonItem = rightBar;
            }
#else
            createNotebookViewController.modalPresentationStyle = .custom
            createNotebookViewController.transitioningDelegate = createNotebookViewController.customTransitionDelegate;
            createNotebookViewController.view.frame = viewController.view.frame
            viewController.present(createNotebookViewController, animated: true)
#endif
        }
    }
    
    @objc private func clearNotebookTitle(){
        self.notebookTitleTextfield?.text = ""
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var toLayout: Bool = true
        if self.children.contains(where: { $0 is FTChooseCoverViewController || $0 is FTChoosePaperViewController }) {
            toLayout = false
        }
        if self.size != self.view.frame.size && toLayout {
            self.size = self.view.frame.size
            self.setUpPreviewStackViewForScreenSize(self.view.frame.size)
            self.configPaperPickerBasedOnScrnSize(self.view.frame.size)
            self.configCoverPickerBasedOnScrnSize(self.view.frame.size)
            self.previewStackView?.setNeedsLayout()
            self.containerView?.setNeedsLayout()
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let cover = self.newNotebookDetails?.selectedCoverTheme {
                self.updateCoverImage(cover.themeThumbnail())
            }
        }
    }

    private func getPaperViewFrame() -> CGRect {
        self.view.layoutIfNeeded()
        var rect: CGRect = .zero
        if let paperImgView = self.paperImageView {
            let paperImageViewWidth = paperImgView.bounds.width
            let paperImageViewHeight = paperImgView.bounds.height
            let imageX = (paperImageViewWidth - (paperImgView.image?.size.width ?? paperImageViewWidth))/2
            rect = paperImgView.convert(CGRect(x: imageX, y: paperImgView.bounds.origin.y, width: (paperImgView.image?.size.width ?? paperImageViewWidth), height: (paperImgView.image?.size.height ?? paperImageViewHeight)), to: self.view)
        }
        return rect
    }
}
extension FTCreateNotebookViewController: UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if let title = textField.text {
            if !title.isEmpty {
                self.newNotebookDetails?.title = title
            }
        }
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension FTCreateNotebookViewController: FTPasswordDelegate {
    public func didTapCancelPassword() {
    }

    public func didTapSavePasswordWith(pin: String, hint: String, useBiometric: Bool) {
        self.passwordDetails = FTPasswordModel(pin: pin, hint: hint, useBiometric: useBiometric)
        self.newNotebookDetails?.passwordDetails = self.passwordDetails
        self.updatePasswordStatus()
    }
}
extension FTCreateNotebookViewController: FTPaperPickerDelegate {
    func didTapMoreTempates() {
        self.dismiss(animated: true)
        self.delegate?.didTapMoreTempates()
    }

    func resetPaperToPreviousSelected() -> CGRect {
        if let themeWithVariants = self.delegate?.selectedPaperVariantsAndTheme {
            self.newNotebookDetails?.selectedPaperWithVariants = themeWithVariants
        }
        self.setUpPreviewStackViewForScreenSize(self.view.frame.size)
        self.configPaperPickerBasedOnScrnSize(self.view.frame.size)
        if let themeWithVariants = self.delegate?.selectedPaperVariantsAndTheme {
            Task {
                await setPaperTemplateWithVarinats(themeWithVariants)
            }
        }
        return getPaperViewFrame()
    }
    func paperSizeBasedOnOrientaion(_ orientaion: FTTemplateOrientation) -> CGRect {
        self.newNotebookDetails?.selectedPaperWithVariants.orientation = orientaion
        self.setUpPreviewStackViewForScreenSize(self.view.frame.size)
        self.configPaperPickerBasedOnScrnSize(self.view.frame.size)
        return getPaperViewFrame()
    }
    func didChoosePaperTemplateWithVariants(_ themeWithVariants: FTSelectedPaperVariantsAndTheme,previewImage:UIImage?) {
        self.newNotebookDetails?.selectedPaperWithVariants = themeWithVariants
        self.setTitleTextToPaperLabel(themeWithVariants.theme.displayName)
        self.setUpPreviewStackViewForScreenSize(self.view.frame.size)
        self.configPaperPickerBasedOnScrnSize(self.view.frame.size)
        self.configCoverPickerBasedOnScrnSize(self.view.frame.size)
        self.paperImage = previewImage?.resizedImageWithinRect(self.paperPreviewSizeBasedOnScrnSize(self.view.frame.size,orientaion: themeWithVariants.orientation))
        self.paperImageView?.image = self.paperImage
    }
    func didCancelPaperSelection() {
    }
}

extension FTCreateNotebookViewController: FTCoverUpdateDelegate {
    public func setDefaultCoverToNoCover(_ cover: FTThemeable) {
        self.delegate?.setDefaultCoverTheme(cover)
        if let selectedCover = self.newNotebookDetails?.selectedCoverTheme,selectedCover.isCustom,!FileManager.default.fileExists(atPath: selectedCover.themeFileURL.path) {
            FTCurrentCoverSelection.shared.selectedCover = cover
            self.updateCoverImage(cover.themeThumbnail())
            self.newNotebookDetails?.selectedCoverTheme = cover
            self.setNoCoverTextIfNeeded()
        }
    }

    public func fetchCoverViewFrame() -> CGRect {
        self.view.layoutIfNeeded()
        var rect: CGRect = .zero
        if let coverImgView = self.coverImageView {
            rect = coverImgView.convert(coverImgView.bounds, to: self.view)
        }
        return rect
    }

    public func fetchPreviousSelectedCover() -> FTThemeable? {
        self.newNotebookDetails?.selectedCoverTheme
    }

    public func animateHideContentViewBasedOn(themeType: FTThemeType) {
        if themeType == .cover {
            self.coverImageView?.isHidden = true
        } else {
            self.paperImageView?.isHidden = true
        }
        self.contentView?.alpha = 0.0
        self.closeBtn?.alpha = 0.0
    }

    public func animateShowContentViewBasedOn(themeType: FTThemeType) {
        if themeType == .cover {
            self.coverImageView?.isHidden = true
        } else {
             self.paperImageView?.isHidden = true
        }
        self.contentView?.alpha = 1.0
        self.closeBtn?.alpha = 1.0
    }

    public func handleShowAnimationCompletion(themeType: FTThemeType) {
        if themeType == .cover {
            self.coverImageView?.isHidden = false
            self.coverImageView?.alpha = 1.0
        } else {
            self.paperImageView?.isHidden = false
            self.paperImageView?.alpha = 1.0
        }
        self.contentView?.alpha = 1.0
        self.closeBtn?.alpha = 1.0
        self.contentView?.isHidden = false
#if !targetEnvironment(macCatalyst)
        self.closeBtn?.isHidden = false
#endif
    }

    public func didUpdateCover(_ theme: FTThemeable?) {
        if let cover = theme {
            self.newNotebookDetails?.selectedCoverTheme = cover
            self.updateCoverImage(cover.themeThumbnail())
        }
    }

    public func didCancelCoverSelection() {
        FTCurrentCoverSelection.shared.selectedCover = self.newNotebookDetails?.selectedCoverTheme
    }

    public func removeNoCoverShadow() {
        self.coverShadowView?.removeShadow()
    }
}

#if targetEnvironment(macCatalyst)
extension FTCreateNotebookViewController: FTBarButtonItemDelegate {
    public func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        self.dismiss(animated: true);
    }
}

extension FTCreateNotebookViewController: FTKeyCommandAction {
    public override var keyCommands: [UIKeyCommand]? {
        return [FTKeyCommand.closeModalWindow];
    }
    
    public func didTapOnClose(_ sender: UIKeyCommand) {
        self.dismiss(animated: true);
    }
}
#endif
