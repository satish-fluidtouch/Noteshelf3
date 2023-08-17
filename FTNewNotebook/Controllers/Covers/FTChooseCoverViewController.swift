//
//  FTChooseCoverViewController.swift
//  FTNewNotebook
//
//  Created by Narayana on 24/02/23.
//

import UIKit
import FTCommon

public enum FTCoverSelectionType: Int {
    case chooseCover, changeCover;
}

public class FTChooseCoverViewController: UIViewController {
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var coverPreview: UIImageView?
    @IBOutlet private weak var coverEditPreview: FTCoverEditPreview?

    @IBOutlet private weak var previewContainerWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var previewContainerHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var previewContainerCenterXConstraint: NSLayoutConstraint?
    @IBOutlet private weak var previewContainerCenterYConstraint: NSLayoutConstraint?

    @IBOutlet private weak var panelHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var panelBottomConstraint: NSLayoutConstraint?

    @IBOutlet private weak var panelContainerView: UIView?

    weak var delegate: FTCoversInfoDelegate?
    public weak var coverUpdateDelegate: FTCoverUpdateDelegate?
    public var coverImagePreview: UIImage?
    private var customTransitionDelegate = FTModalScaleTransitionDelegate();
    
    private var size: CGSize = .zero
    private let sizeHelper = FTPreviewSizeHelper()
    private var isInitialPreviewed: Bool = false
    private let animDuration: CGFloat = 0.2

    private var coverSelectionType: FTCoverSelectionType = .chooseCover;
    
    private var previewMode: FTCoverPreviewMode = .justPreview {
        didSet {
            if previewMode == .justPreview {
                self.coverPreview?.isHidden = false
                self.coverEditPreview?.isHidden = true
            } else {
                self.coverEditPreview?.isHidden = false
                self.coverPreview?.isHidden = true
            }
        }
    }

    public static func viewControllerInstance(coverSelectionType : FTCoverSelectionType = .chooseCover, coversInfoDelegate: FTCoversInfoDelegate?, currentTheme: FTThemeable?) -> FTChooseCoverViewController? {
        if let chooseCoverVc = UIStoryboard(name: "FTCovers", bundle: currentBundle).instantiateInitialViewController() as? FTChooseCoverViewController {
            chooseCoverVc.delegate = coversInfoDelegate;
            if(coverSelectionType == .changeCover) {
                chooseCoverVc.transitioningDelegate = chooseCoverVc.customTransitionDelegate;
                chooseCoverVc.modalPresentationStyle = .custom;
                FTCurrentCoverSelection.shared.selectedCover = currentTheme
            }
            chooseCoverVc.coverSelectionType = coverSelectionType;
            return chooseCoverVc;
        }
        return nil;
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.panelBottomConstraint?.constant = 0.0
        if let themeInfo = FTCurrentCoverSelection.shared.selectedCover {
            self.coverPreview?.image = themeInfo.themeThumbnail()
        } else {
            self.coverPreview?.image = coverImagePreview
        }

        var previewShadowRadius: CGFloat = 40.0
#if targetEnvironment(macCatalyst)
        previewShadowRadius = 20.0
#endif
        self.previewContainer?.addShadow(color: UIColor.black.withAlphaComponent(0.3), offset: CGSize(width: 0.0, height: 24.0), opacity: 1.0, shadowRadius: previewShadowRadius)
        self.panelContainerView?.dropShadowWith(color: UIColor.label.withAlphaComponent(0.2), offset: CGSize(width: 0, height: -8), radius: 64.0)
        self.updatePreviewModeIfNeeded(.justPreview)
        
        if(coverSelectionType == .changeCover) {
            self.view.backgroundColor = UIColor.appColor(.createNotebookViewBG)
            self.handleLayoutChanges()
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            if isInitialPreviewed {
                self.handleLayoutChanges()
            }
        }
    }

    func getPanelHeight() -> CGFloat {
        let height = (self.isRegularClass() ? FTCovers.Panel.regularHeight : FTCovers.Panel.compactHeight) //+ self.view.safeAreaInsets.bottom
        return height
    }

    private func updatePanelHeight() {        
        self.panelHeightConstraint?.constant = self.getPanelHeight()
    }
    
    private func handleLayoutChanges() {
        self.updatePanelHeight();
        let previewSize = sizeHelper.getCoverPreviewSize(from: self)
        self.previewContainerWidthConstraint?.constant = previewSize.width
        self.previewContainerHeightConstraint?.constant = previewSize.height
        self.previewContainer.layoutIfNeeded()
        self.view.layoutIfNeeded()
        self.updateCornerRadius()
    }

    func openPreview(from frame: CGRect, onCompletion: (() -> Void)?) {
        self.panelBottomConstraint?.constant = -500.0
        let centerXandY = self.getCenterXandY(from: frame)
        
        self.previewContainerCenterXConstraint?.constant = centerXandY.x
        self.previewContainerCenterYConstraint?.constant = centerXandY.y
        self.previewContainerWidthConstraint?.constant = frame.size.width
        self.previewContainerHeightConstraint?.constant = frame.size.height
        self.view.layoutIfNeeded()
        
        let path = self.getInitialPathOfPreview()
        let shapeLayer = self.getShapeLayer()
        shapeLayer.path = path
        self.coverPreview?.layer.mask = shapeLayer

        let previewSize = self.sizeHelper.getCoverPreviewSize(from: self)
        let scalex = previewSize.width/frame.size.width;
        let scaley = previewSize.height/frame.size.height;
        
        let animTransform = CGAffineTransformMakeScale(scalex, scaley);
        
        self.updatePanelHeight();
        
        UIView.animate(withDuration: animDuration,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            self.coverUpdateDelegate?.animateHideContentViewBasedOn(themeType: .cover)
            // Panel
            self.panelBottomConstraint?.constant = 0.0
            
            self.previewContainer.transform = animTransform;
            // Preview
            self.previewContainerCenterXConstraint?.constant = 0.0
            self.previewContainerCenterYConstraint?.constant = -(self.getPanelHeight()/2.0)
            
            self.previewContainer.layoutIfNeeded()
            self.view.layoutIfNeeded()
            
        }) { _ in
            self.isInitialPreviewed = true
            self.previewContainer.transform = .identity;
            self.previewContainerWidthConstraint?.constant = previewSize.width
            self.previewContainerHeightConstraint?.constant = previewSize.height
            self.previewContainer.layoutIfNeeded()

            let path = self.getFinalPathOfPreview(size: previewSize)
            let shapeLayer = self.getShapeLayer()
            shapeLayer.path = path
            self.coverPreview?.layer.mask = shapeLayer

            onCompletion?()
        }
    }

    func closePreview(isCancelled: Bool = false, onCompletion: @escaping () -> Void) {
        self.previewContainer?.layer.shadowOpacity = 0.0
        if(coverSelectionType == .changeCover) {
            self.dismiss(animated: true,completion: {
                onCompletion();
            });
            return;
        }
        
        guard let frame = self.coverUpdateDelegate?.fetchCoverViewFrame() else {
            onCompletion();
            return;
        }

        self.view.layoutIfNeeded()
        if isCancelled, let prevCover = self.coverUpdateDelegate?.fetchPreviousSelectedCover() {
            self.coverPreview?.image = prevCover
        }
        
        var scalex: CGFloat = 1;
        var scaley: CGFloat = 1;
        
        if let previewSize = self.previewContainer?.frame {
            scalex = frame.size.width/previewSize.width;
            scaley = frame.size.height/previewSize.height;
        }
        
        let animTransform = CGAffineTransformMakeScale(scalex, scaley);

        
        UIView.animate(withDuration: animDuration,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            self.coverUpdateDelegate?.animateShowContentViewBasedOn(themeType:.cover)
            // Panel
            self.panelBottomConstraint?.constant = -500

            // Preview
            let centerXandY = self.getCenterXandY(from: frame)

            self.previewContainerCenterXConstraint?.constant = centerXandY.x
            self.previewContainerCenterYConstraint?.constant = centerXandY.y
            
            self.previewContainer.transform = animTransform;
            self.view.layoutIfNeeded()
        }) { _ in
            
            self.previewContainer.transform = .identity;
            self.previewContainerWidthConstraint?.constant = frame.size.width
            self.previewContainerHeightConstraint?.constant = frame.size.height
            self.previewContainer?.layoutIfNeeded()

            self.coverUpdateDelegate?.handleShowAnimationCompletion(themeType: .cover)
            onCompletion()
        }
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let coverStyleVc = segue.destination.children.first(where: { vc in
            vc is FTCoverStyleViewController
        }) as? FTCoverStyleViewController {
            coverStyleVc.viewModel = FTCoversViewModel(with: self.delegate)
            coverStyleVc.selectionDelegate = self
        }
    }
}

private extension FTChooseCoverViewController {
    private func getCenterXandY(from frame: CGRect) -> CGPoint {
        let centerX = frame.origin.x + frame.size.width/2 - self.view.frame.width/2
        let centerY = frame.origin.y + frame.size.height/2 - self.view.frame.height/2
        return CGPoint(x: centerX, y: centerY)
    }

    private func updatePreviewModeIfNeeded(_ mode: FTCoverPreviewMode) {
        if self.previewMode != mode {
            self.previewMode = mode
        }
    }

    private func getShapeLayer() -> CAShapeLayer {
        if let shapeLayer = self.coverPreview?.layer.mask as? CAShapeLayer, shapeLayer.name == "previewLayer" {
            return shapeLayer
        } else {
            let shape = CAShapeLayer()
            shape.name = "previewLayer"
            return shape
        }
    }

    private func getInitialPathOfPreview() -> CGPath? {
        let coverRadiusAttrs = FTNewNotebook.Constants.SelectedCoverRadius.self
        var initialPath = self.coverPreview?.getCornerRadiiPath(topLeft: coverRadiusAttrs.topLeft, topRight: coverRadiusAttrs.topRight, bottomLeft: coverRadiusAttrs.bottomLeft, bottomRight: coverRadiusAttrs.bottomRight)
        if let curCover = FTCurrentCoverSelection.shared.selectedCover,  !curCover.hasCover { // no cover
            let radius: CGFloat = 14.0
            initialPath = self.coverPreview?.getCornerRadiiPath(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
        }
        return initialPath
    }

    private func getFinalPathOfPreview(size: CGSize) -> CGPath? {
        var reqPath: CGPath?
        if let initialFrame = self.coverUpdateDelegate?.fetchCoverViewFrame() {
            let cornerRadii = self.fetchCoverPreviewRadii(using: size, previousSize: initialFrame.size)
            reqPath = self.coverPreview?.getCornerRadiiPath(topLeft: cornerRadii.topLeft, topRight: cornerRadii.topRight, bottomLeft: cornerRadii.bottomLeft, bottomRight: cornerRadii.bottomRight)
            if let curCover = FTCurrentCoverSelection.shared.selectedCover,  !curCover.hasCover { // no cover
                let radius = self.fetchNoCoverPreviewRadius(using: size, previousSize: initialFrame.size)
                reqPath = self.coverPreview?.getCornerRadiiPath(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
            }
        }
        return reqPath
    }

    private func fetchNoCoverPreviewRadius(using currentSize: CGSize, previousSize: CGSize) -> CGFloat {
        var radius: CGFloat = 21.0 // // Change cover - since no animation
        if(coverSelectionType == .chooseCover && previousSize != .zero && currentSize != .zero) {
            let noCoverRadius = FTNewNotebook.Constants.NoCoverRadius.allCorners
            let reqFactor = currentSize.width * (currentSize.width/currentSize.height)
            radius = noCoverRadius/previousSize.width * reqFactor
        }
        return radius
    }

    private func fetchCoverPreviewRadii(using currentSize: CGSize, previousSize: CGSize) -> (topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        if (coverSelectionType == .chooseCover && previousSize != .zero && currentSize != .zero) {
            let coverRadiusAttrs = FTNewNotebook.Constants.SelectedCoverRadius.self
            let reqFactor = currentSize.width * (previousSize.width/previousSize.height)
            let topLeft: CGFloat = coverRadiusAttrs.topLeft/previousSize.width * reqFactor
            let topRight: CGFloat = coverRadiusAttrs.topRight/previousSize.width * reqFactor
            let bottomLeft: CGFloat = coverRadiusAttrs.bottomLeft/previousSize.width * reqFactor
            let bottomRight: CGFloat = coverRadiusAttrs.bottomRight/previousSize.width * reqFactor
            return (topLeft, topRight, bottomLeft, bottomRight)
        } else { // Change cover - since no animation
            let previewAttrs = FTCovers.PreviewCoverRadius.self
            return (previewAttrs.topLeft, previewAttrs.topRight, previewAttrs.bottomLeft, previewAttrs.bottomRight)
        }
    }

    private func updateCornerRadius() {
        let previewSize = self.sizeHelper.getCoverPreviewSize(from: self)
        if let initialFrame = self.coverUpdateDelegate?.fetchCoverViewFrame() {
            if let curCover = FTCurrentCoverSelection.shared.selectedCover,  !curCover.hasCover { // no cover
                let radius = self.fetchNoCoverPreviewRadius(using: previewSize, previousSize: initialFrame.size)
                self.coverPreview?.roundCorners(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
            } else {
                let radii = self.fetchCoverPreviewRadii(using: previewSize, previousSize: initialFrame.size)
                if self.previewMode == .justPreview {
                    self.coverPreview?.roundCorners(topLeft: radii.topLeft, topRight: radii.topRight, bottomLeft: radii.bottomLeft, bottomRight: radii.bottomRight)
                } else {
                    self.coverEditPreview?.roundCorners(topLeft: radii.topLeft, topRight: radii.topRight, bottomLeft: radii.bottomLeft, bottomRight: radii.bottomRight)
                }
            }
        }
    }
}

extension FTChooseCoverViewController: FTCoverSelectionDelegate {
    func didTapCancelbutton() {
        self.updatePreviewModeIfNeeded(.justPreview)
        self.closePreview(isCancelled: true) {
            self.remove()
            self.coverUpdateDelegate?.didCancelCoverSelection()
        }
    }

    func didTapOnDoneButton() {
        let coverInfo = FTCurrentCoverSelection.shared.selectedCover
        if let theme = coverInfo {
            self.closePreview() {
                self.remove()
                self.coverUpdateDelegate?.didUpdateCover(theme)
            }
        } else {
            if nil == coverInfo, let editView = self.coverEditPreview, var selectedImage = editView.selectedImageView.image {
                editView.spineImgView?.isHidden = true
                if let image = editView.asImage() {
                    selectedImage = image
                }
                if let rawImage = coverEditPreview?.rawImage, let rect = coverEditPreview?.scaledRect, rect != .zero {
                    selectedImage = rawImage.croppedImage(at: rect)
                }
                editView.spineImgView?.isHidden = false
                self.closePreview() {
                    self.remove()
                    if let cover = self.delegate?.generateCoverTheme(image: selectedImage, coverType: .custom) {
                        FTCurrentCoverSelection.shared.selectedCover = cover
                        self.coverUpdateDelegate?.didUpdateCover(cover)
                    }
                }
            } else {
                self.closePreview {}
            }
        }
    }

    func didSelectCover(_ themeModel: FTCoverThemeModel) {
        FTCurrentCoverSelection.shared.selectedCover = themeModel.themeable
        self.updatePreviewModeIfNeeded(.justPreview)
        self.coverPreview?.image = themeModel.thumbnail()
        self.updateCornerRadius()
    }

    func didSelectCustomImage(_ image: UIImage) {
        self.updatePreviewModeIfNeeded(.previewEdit)
        self.coverEditPreview?.updatePreviewIfNeeded(image)
        FTCurrentCoverSelection.shared.selectedCover = nil
        self.updateCornerRadius()
    }

    func didSelectUnsplash(of url: String) {
        let placeholder: UIImage?
        if self.previewMode.isEditPreviewMode {
            placeholder = self.coverEditPreview?.selectedImageView.image
        } else {
            placeholder = self.coverPreview?.image
        }
        self.updatePreviewModeIfNeeded(.previewEdit)
        self.coverEditPreview?.updateAsynchronousImage(using: url, placeholder: placeholder)
        self.updateCornerRadius()
    }
}
