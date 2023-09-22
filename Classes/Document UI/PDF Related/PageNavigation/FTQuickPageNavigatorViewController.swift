//
//  FTQuickPageNavigatorViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTQuickPageNavigatorDelegate: NSObjectProtocol {
    func pageNavigator(showPage atIndex: UInt, controller: FTQuickPageNavigatorViewController)
    func pageNavigatorDidHide(_ controller: FTQuickPageNavigatorViewController?)
}

extension Notification.Name {
    static let quickPageNavigatorShowNotification = Notification.Name(rawValue: "FTQuickPageNavigatorShowNotification")
    static let quickPageNavigatorHideNotification = Notification.Name(rawValue: "FTQuickPageNavigatorHideNotification")
}

enum FTSlidingDirection: Int {
    case horizontal
    case vertical
}
private let gapBetweenPageTipAndThumbnail: CGFloat = 8.0

@objc class FTQuickPageNavigatorViewController: UIViewController {
    
    @IBOutlet weak private var pageInfoContainer: UIView?
    @IBOutlet weak private var thumbnailImageView: UIImageView?
    @IBOutlet weak private var pageSlider: FTPageSlider?
    
    @IBOutlet weak private var pageTipView: UIView?
    @IBOutlet weak private var pageInfoLabel: UILabel?
    @IBOutlet weak private var tipImageView: UIImageView?
    @IBOutlet weak private var tipImageView_Blue: UIImageView?
    var direction: FTSlidingDirection = .horizontal

    weak var delegate: FTQuickPageNavigatorDelegate?
    weak var currentDocument: FTDocumentProtocol?
    private var page: FTPageProtocol?
    private var isTrackingActive: Bool = false
    private var _currentPageIndex: UInt = 0
        
    private var numberOfPages: Int = 1
    private let maximumSpacePerPage: CGFloat = 50.0
    private let thumbnailEdgePadding: CGFloat = 0.0 //No need because we already added padding
    private let expireDuration: TimeInterval = 5.0
    private let springLoadingDuration: TimeInterval = 1.0
    private let thumbAnimationDuration: TimeInterval = (0.15 / 2) // (0.1(Total Duration) / 2(No. Of Images) )

    var currentThumbImageIndex: Int = 0
    let highlightStateImages:[String] = ["handle1", "handle2"]
    let normalStateImages:[String] = ["handle1", "handle1"]

    private var currentPageIndex: UInt {
        set {
            if newValue != _currentPageIndex {
                _currentPageIndex = newValue
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.springLoadSelectedPage), object: nil)
                if self.isTrackingActive {
                    self.perform(#selector(self.springLoadSelectedPage), with: nil, afterDelay: self.springLoadingDuration)
                }
                //***************************Flash for a moment when reaches bounds
                if (numberOfPages == newValue + 1 || newValue == 0) {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.tipImageView?.alpha = 0.0
                        self.tipImageView_Blue?.alpha = 1.0
                    }) { (_) in
                        UIView.animate(withDuration: 0.8) {
                            self.tipImageView?.alpha = 1.0
                            self.tipImageView_Blue?.alpha = 0.0
                        }
                    }
                }
                else {
                    if let imgView = self.tipImageView, imgView.alpha != 1.0 {
                        UIView.animate(withDuration: 0.2) {
                            self.tipImageView?.alpha = 1.0
                            self.tipImageView_Blue?.alpha = 0.0
                        }
                    }
                }
                //***************************
            }
        }
        get {
            return _currentPageIndex
        }
    }
    //MARK:- View Life Cycle
    deinit {
        self.removeThumbnailObservers()
        
        NotificationCenter.default.removeObserver(self, name: .quickPageNavigatorShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .quickPageNavigatorHideNotification, object: nil)
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.configureNavigatorAppearance()
        self.pageSlider?.minimumValue = 1.0
        
        NotificationCenter.default.addObserver(forName: .quickPageNavigatorShowNotification, object: nil, queue: nil) { [weak self] (notification) in
            var currentSessionID = ""
            if #available(iOS 13.0, *) {
                if let sessionIdentifier = self?.view.window?.windowScene?.session.persistentIdentifier {
                    currentSessionID = sessionIdentifier
                }
            }
            guard let `self` = self, let sessionID = notification.object as? String, sessionID == currentSessionID else {
                return
            }
            self.activateNavigatorHandle()
        }
        
        NotificationCenter.default.addObserver(forName: .quickPageNavigatorHideNotification, object: nil, queue: nil) { [weak self] (notification) in
            var currentSessionID = ""
            if #available(iOS 13.0, *) {
                if let sessionIdentifier = self?.view.window?.windowScene?.session.persistentIdentifier {
                    currentSessionID = sessionIdentifier
                }
            }
            guard let `self` = self, let sessionID = notification.object as? String, sessionID == currentSessionID else {
                return
            }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.deactivateNavigatorHandle), object: nil)
            self.deactivateNavigatorHandle()
        }

        self.pageSlider?.trackingHandler = {[weak self] (trackState) in
            guard let `self` = self, let slider = self.pageSlider else {
                return
            }
            self.isTrackingActive = true
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.deactivateNavigatorHandle), object: nil)
            //****************************
            if trackState == .began {
                UIView.animate(withDuration: 0.3) {
                    self.thumbnailImageView?.alpha = 1.0
                    self.pageTipView?.alpha = 1.0
                }
                self.currentPageIndex = UInt(max(Int(slider.value.rounded()) - 1, 0))
                self.updatePageInfoContainer(at: self.currentPageIndex)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.animateToNormalImage), object: nil)
                self.perform(#selector(self.animateToHighlightingImage), with: nil, afterDelay: self.thumbAnimationDuration)
            }
            else if trackState == .ended {
                self.isTrackingActive = false
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.animateToHighlightingImage), object: nil)
                self.perform(#selector(self.animateToNormalImage), with: nil, afterDelay: self.thumbAnimationDuration)

                self.perform(#selector(self.deactivateNavigatorHandle), with: nil, afterDelay: self.expireDuration)
                UIView.animate(withDuration: 0.3, animations: {
                    self.thumbnailImageView?.alpha = 0.0
                    self.pageTipView?.alpha = 0.0
                }) { (success) in
                    if(success) {
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.springLoadSelectedPage), object: nil)
                        self.currentPageIndex = UInt(max(Int(slider.value.rounded()) - 1, 0))
                        FTCLSLog("QuickNavigator - pageSelected");

                        self.delegate?.pageNavigator(showPage: self.currentPageIndex, controller: self)
                    }
                }
            }
            //****************************
        }
        
        self.perform(#selector(self.deactivateNavigatorHandle), with: nil, afterDelay: expireDuration)
    }
    
    private func configureNavigatorAppearance() {
        if let pageCount = currentDocument?.pages().count, pageCount > self.currentPageIndex {
            numberOfPages = pageCount
            self.page = currentDocument?.pages()[Int(self.currentPageIndex)]
        }
        self.thumbnailImageView?.alpha = 0.0
        self.pageTipView?.alpha = 0.0
        //Shadow
        self.pageInfoContainer?.layer.shadowColor = UIColor.black.cgColor;
        self.pageInfoContainer?.layer.shadowRadius = 5;
        self.pageInfoContainer?.layer.shadowOpacity = 0.12;
        self.pageInfoContainer?.layer.shadowOffset = CGSize(width: 0, height: 4);

        self.thumbnailImageView?.layer.cornerRadius = 3.0
        self.thumbnailImageView?.layer.masksToBounds = true

        self.setThumbImage(image: UIImage(named: "handle1")!, state: .normal)
        self.setThumbImage(image: UIImage(named: "handle1")!, state: .highlighted)
        self.pageSlider?.maximumTrackTintColor = .clear
        self.pageSlider?.minimumTrackTintColor = .clear
        self.arrangeContentsForPageInfoContainer()
    }

    private func setThumbImage(image: UIImage, state: UIControl.State) {
#if !targetEnvironment(macCatalyst)
        self.pageSlider?.setThumbImage(image, for: state)
#endif
    }

    @objc private func activateNavigatorHandle() {
        FTCLSLog("QuickNavigator - activate");

        self.view.isUserInteractionEnabled = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.deactivateNavigatorHandle), object: nil)
        self.perform(#selector(self.deactivateNavigatorHandle), with: nil, afterDelay: expireDuration)

        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 1.0
        })
    }
    
    @objc private func deactivateNavigatorHandle() {
        FTCLSLog("QuickNavigator - deactivate");

        self.view.isUserInteractionEnabled = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.deactivateNavigatorHandle), object: nil)
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }) {[weak self] (success) in
            if success {
                self?.delegate?.pageNavigatorDidHide(self)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateSliderConfiguration(false)
    }
        
    @IBAction private func sliderValueChanged(_ slider: UISlider) {
        #if DEBUG
        print(slider.value)
        #endif
        
        self.currentPageIndex = UInt(max(Int(slider.value.rounded()) - 1, 0))
        self.updatePageInfoContainer(at: self.currentPageIndex)
    }
    
    //MARK:- UI Configuration
    private func updateSliderConfiguration(_ animated: Bool) {
        guard let pageCount = currentDocument?.pages().count, let slider = self.pageSlider else {
            return
        }
        self.numberOfPages = pageCount
        if self.direction == .vertical {
            slider.transform = CGAffineTransform(rotationAngle: .pi / 2)
        }

        slider.maximumValue = Float(self.numberOfPages)
        let newPageNumber = Float(self.currentPageIndex + 1)
        if slider.value.rounded() != newPageNumber {
            slider.setValue(newPageNumber, animated: false) //The page number, not index
        }
        slider.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        slider.center = CGPoint.init(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
        if self.direction == .horizontal {
            let sliderWidth = slider.frame.width
            let eachPageSpace = sliderWidth/CGFloat(numberOfPages)
            if eachPageSpace > maximumSpacePerPage {
                var currentFrame = slider.frame
                currentFrame.size.width = maximumSpacePerPage * CGFloat(numberOfPages)
                slider.frame = currentFrame
                slider.center = CGPoint.init(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
            }
        }
        else {
            let sliderHeight = slider.frame.height
            let eachPageSpace = sliderHeight/CGFloat(numberOfPages)
            if eachPageSpace > maximumSpacePerPage {
                var currentFrame = slider.frame
                currentFrame.size.height = maximumSpacePerPage * CGFloat(numberOfPages)
                slider.frame = currentFrame
                slider.center = CGPoint.init(x: self.view.frame.width * 0.5, y: self.view.frame.height * 0.5)
            }
        }
        self.updatePageInfoContainer(at: self.currentPageIndex)
    }
    
    private func updatePageInfoContainer(at pageIndex: UInt) {
        self.removeThumbnailObservers()
        
        var pageIndexToShow: Int = Int(pageIndex)
        if let totalPages = self.currentDocument?.pages().count, pageIndexToShow >= totalPages {
            if totalPages == 0 {
                return
            }
            self.numberOfPages = totalPages
            pageIndexToShow = totalPages - 1
            self.currentPageIndex = UInt(pageIndexToShow)
            self.updateSliderConfiguration(false)
        }
        
        if let slider = self.pageSlider, let infoContainer = self.pageInfoContainer {
            let trackRect = slider.trackRect(forBounds: slider.bounds)
            let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: trackRect, value: slider.value)
            var centerPoint = CGPoint.init(x: thumbRect.midX + slider.frame.minX, y: (slider.frame.origin.y - infoContainer.frame.height * 0.5) + 13)
            if self.direction == .vertical {
                //Reverse the coordinates as transform applied to slider
                centerPoint = CGPoint.init(x: centerPoint.y, y: centerPoint.x)
                infoContainer.frame = CGRect.init(origin: CGPoint.init(x: slider.frame.origin.x - infoContainer.frame.width + 8, y: slider.frame.origin.y + centerPoint.y - (infoContainer.frame.height * 0.5)), size: infoContainer.frame.size)
            }
            else {
                infoContainer.center = centerPoint
            }
            
            self.pageInfoLabel?.text =  String.localizedStringWithFormat(NSLocalizedString("notebook.quickPageNavigator.pageNumber.Text", comment: "N of N"), pageIndex + 1, Int(slider.maximumValue))
            self.page?.thumbnail()?.cancelThumbnailGeneration()
            
            self.page = currentDocument?.pages()[pageIndexToShow]
            self.updateThumbnailImage()
        }
    }
        
    @objc private func springLoadSelectedPage() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.springLoadSelectedPage), object: nil)
        if self.isTrackingActive {
            FTCLSLog("QuickNavigator - spring loaded page");

            self.delegate?.pageNavigator(showPage: self.currentPageIndex, controller: self)
        }
    }
}

//MARK:- Public Methods
extension FTQuickPageNavigatorViewController {
    
    class func controller(nib nibName: String, document: FTDocumentProtocol, pageIndex: UInt? = 0) -> FTQuickPageNavigatorViewController {
        let pageNavController = FTQuickPageNavigatorViewController(nibName:"FTQuickPageNavigatorViewController" , bundle: nil)
        pageNavController.currentDocument = document
        pageNavController.currentPageIndex = pageIndex ?? 0
        return pageNavController
    }
    
    @objc func setCurrentPageIndex(_ newPageIndex: Int) {
        var pageIndexToShow: Int = max(newPageIndex, 0)
        self.currentPageIndex = UInt(pageIndexToShow)
        if let totalPages = self.currentDocument?.pages().count, pageIndexToShow >= totalPages {
            pageIndexToShow = totalPages - 1
            self.currentPageIndex = UInt(pageIndexToShow)
        }
        self.updateSliderConfiguration(true)
    }
    
    @objc class func showPageNavigator(onController controller: UIViewController) {
        var sessionID = ""
        if #available(iOS 13.0, *) {
            if let sessionIdentifier = controller.view.window?.windowScene?.session.persistentIdentifier {
                sessionID = sessionIdentifier
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.quickPageNavigatorShowNotification, object: sessionID)
    }

    @objc class func hidePageNavigator(forController controller: UIViewController) {
        var sessionID = ""
        if #available(iOS 13.0, *) {
            if let sessionIdentifier = controller.view.window?.windowScene?.session.persistentIdentifier {
                sessionID = sessionIdentifier
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.quickPageNavigatorHideNotification, object: sessionID)
    }
}
//MARK:- Navigator Animation
extension FTQuickPageNavigatorViewController {
    @objc private func animateToHighlightingImage() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.animateToNormalImage), object: nil)

        DispatchQueue.main.async {
            UIView.animate(withDuration: self.thumbAnimationDuration) {
                self.currentThumbImageIndex = min(self.highlightStateImages.count - 1, self.currentThumbImageIndex + 1)

                self.setThumbImage(image: UIImage(named: self.highlightStateImages[self.currentThumbImageIndex])!, state: .highlighted)

                if self.currentThumbImageIndex == (self.highlightStateImages.count - 1) {
                    if let isStillTracking = self.pageSlider?.isTracking, isStillTracking, let lastImageName = self.highlightStateImages.last {
                        self.setThumbImage(image: UIImage(named: lastImageName)!, state: .normal)
                        self.setThumbImage(image: UIImage(named: lastImageName)!, state: .highlighted)
                    }
                    else{
                        self.setThumbImage(image: UIImage(named: self.highlightStateImages[0])!, state: .normal)
                        self.setThumbImage(image: UIImage(named: self.highlightStateImages[0])!, state: .highlighted)
                    }
                    self.pageSlider?.setNeedsLayout()
                }
                else {
                    self.perform(#selector(self.animateToHighlightingImage), with: nil, afterDelay: self.thumbAnimationDuration)
                }
            }
        }
    }
    
    @objc private func animateToNormalImage() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.animateToHighlightingImage), object: nil)
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.thumbAnimationDuration) {
                self.currentThumbImageIndex = max(0, self.currentThumbImageIndex - 1)
                self.setThumbImage(image: UIImage(named: self.normalStateImages[self.currentThumbImageIndex])!, state: .normal)

                if self.currentThumbImageIndex == 0 {
                    self.setThumbImage(image: UIImage(named: self.normalStateImages[0])!, state: .normal)
                    self.setThumbImage(image: UIImage(named: self.normalStateImages[0])!, state: .highlighted)
                    self.pageSlider?.setNeedsLayout()
                }
                else {
                    self.perform(#selector(self.animateToNormalImage), with: nil, afterDelay: self.thumbAnimationDuration)
                }
            }
        }
    }
}
extension FTQuickPageNavigatorViewController {
    //This will setup the frames for all the subviews with respect to the scrolling direction
    private func arrangeContentsForPageInfoContainer() {
        guard let infoContainer = self.pageInfoContainer,
            let tipView = self.pageTipView,
            let tipBlackImgView = self.tipImageView,
            let tipBlueImgView = self.tipImageView_Blue,
            let pageLabel = self.pageInfoLabel else {
            return
        }

        let normalTipImage = UIImage.init(named: self.direction == .horizontal ? "pagenumbertip" : "pagenumbertip_v")
        let blueTipImage = UIImage.init(named: self.direction == .horizontal ? "pagenumbertip_blue" : "pagenumbertip_blue_v")
        self.tipImageView?.image = normalTipImage
        self.tipImageView_Blue?.image = blueTipImage
        
        //******************************** To calculate dark blue tip size ONLY ONCE as getting some UI glitch if we do on  page number changes
        var referencePageString = "999/999"
        if numberOfPages > 999 {
            referencePageString = "9999/9999"
        }
        if numberOfPages > 9999 {
            referencePageString = "99999/99999"
        }
        //********************************

        if self.direction == .horizontal { //For horizontal, frames will be as it is in the xib file
            if numberOfPages > 99 {
                let tipViewBounds = tipView.bounds
                let expectedSize = referencePageString.sizeWithFont(pageLabel.font)
                let tipImageFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: max(expectedSize.width + 36, 88), height: 69))
                
                var strechedImage = normalTipImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15), resizingMode: .stretch)
                tipBlackImgView.contentMode = .scaleToFill
                tipBlackImgView.image = strechedImage
                tipBlackImgView.frame = tipImageFrame
                tipBlackImgView.center = CGPoint.init(x: tipViewBounds.width * 0.5, y: tipViewBounds.midY + 12)

                strechedImage = blueTipImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15), resizingMode: .stretch)
                tipBlueImgView.contentMode = .scaleToFill
                tipBlueImgView.image = strechedImage
                tipBlueImgView.frame = tipBlackImgView.frame
            }
        }
        else { //For vertical, all the calculations applied here for arranging subviews in pageInfoContainer
            var tipContainerSize = CGSize.init(width: 64, height: 36)
            var tipImageFrame = CGRect.init(origin: CGPoint.init(x: -13, y: -4), size: CGSize.init(width: 97, height: 60))
            if numberOfPages > 99 {
                let expectedSize = referencePageString.sizeWithFont(pageLabel.font);
                tipImageFrame.size = CGSize.init(width: max(expectedSize.width + 44, 97), height: 60)
                tipContainerSize = CGSize.init(width: expectedSize.width + 10, height: 36)
                
                var strechedImage = normalTipImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15), resizingMode: .stretch)
                tipBlackImgView.contentMode = .scaleToFill
                tipBlackImgView.image = strechedImage

                strechedImage = blueTipImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15), resizingMode: .stretch)
                tipBlueImgView.contentMode = .scaleToFill
                tipBlueImgView.image = strechedImage
            }
            tipBlackImgView.frame = tipImageFrame
            tipBlueImgView.frame = tipBlackImgView.frame
                        
            infoContainer.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 100 + gapBetweenPageTipAndThumbnail + tipContainerSize.width, height: 125))
            
            var tipViewFrame = tipView.frame
            tipViewFrame.origin = CGPoint.init(x: infoContainer.bounds.width - tipContainerSize.width - 5, y: (infoContainer.frame.height * 0.5) - (tipContainerSize.height * 0.5))
            tipViewFrame.size = tipContainerSize
            tipView.frame = tipViewFrame
                        
            pageLabel.frame = CGRect.init(origin: tipView.bounds.origin, size: CGSize.init(width: tipView.bounds.width, height: tipView.bounds.height))
        }
    }
}
//MARK:- Thumbnail & Page Info
extension FTQuickPageNavigatorViewController {
    
    @objc private func updateThumbnailImage() {
        self.thumbnailImageView?.contentMode = UIView.ContentMode.scaleAspectFit;
        self.page?.thumbnail()?.thumbnailImage(onUpdate: { [weak self] (image, uuidString) in
            if let currentPage = self?.page , currentPage.uuid == uuidString {
                self?.thumbnailImageView?.image = image;
                self?.thumbnailImageView?.backgroundColor = UIColor.clear
                if nil == image {
                    self?.thumbnailImageView?.image = nil;
                    self?.thumbnailImageView?.backgroundColor = UIColor.white
                    self?.thumbnailImageView?.contentMode = UIView.ContentMode.scaleToFill;
                }
                if(currentPage.thumbnail()?.shouldGenerateThumbnail ?? false) {
                    self?.addThumbnailObservers();
                }
            }

            if let currentPage = self?.page, currentPage.uuid == uuidString {
                if nil == image {
                    self?.thumbnailImageView?.image = nil;
                    self?.thumbnailImageView?.backgroundColor = UIColor.white
                    self?.thumbnailImageView?.contentMode = UIView.ContentMode.scaleToFill;
                }
                else {
                    let originalThumbnailSize: CGSize = CGSize.init(width: 100, height: 125)
                    if let thumbnailImgView = self?.thumbnailImageView, let newImage = image?.resizedImageWithinRect(originalThumbnailSize), let tipView = self?.pageTipView {
                        self?.thumbnailImageView?.image = newImage;
                        self?.thumbnailImageView?.backgroundColor = UIColor.clear
                        
                        if let scrollDirection = self?.direction, scrollDirection == .vertical {
                            thumbnailImgView.frame = CGRect.init(origin: CGPoint.zero, size: newImage.size)
                            thumbnailImgView.center = CGPoint.init(x: tipView.frame.minX - gapBetweenPageTipAndThumbnail - thumbnailImgView.frame.width * 0.5, y: tipView.center.y)
                        }
                        else {
                            thumbnailImgView.frame = CGRect.init(origin: CGPoint.zero, size: newImage.size)
                            thumbnailImgView.center = CGPoint.init(x: originalThumbnailSize.width * 0.5, y: tipView.frame.minY - (newImage.size.height * 0.5) - gapBetweenPageTipAndThumbnail)
                    }
                    }
                }
            }
        });
    }
    
    private func addThumbnailObservers() {
        if let page = self.page {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didReceiveNotifcationForGenerateThumbnail(_:)),
                                                   name: NSNotification.Name(rawValue: "FTShouldGenerateThumbnail"),
                                                   object: page);
        }
    }
    
    private func removeThumbnailObservers() {
        if let page = self.page {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name(rawValue: "FTShouldGenerateThumbnail"),
                                                      object: page);
        }
    }

    @objc private func didReceiveNotifcationForGenerateThumbnail(_ notification : Notification)
    {
        if(!Thread.current.isMainThread) {
            runInMainThread { [weak self] in
                self?.didReceiveNotifcationForGenerateThumbnail(notification);
            }
            return;
        }

        if let pageObject = notification.object as? FTPageProtocol,
            let curPage = self.page,
            pageObject.uuid == curPage.uuid {
            self.updateThumbnailImage();
        }
    }
}
//********************************
//MARK:- FTPageSlider
enum FTSliderTrackingState: Int {
    case began
    case ended
}

class FTPageSlider: UISlider {
    var trackingHandler: ((FTSliderTrackingState) -> (Void))?
    
#if targetEnvironment(macCatalyst)
    override var behavioralStyle: UIBehavioralStyle {
        return .pad;
    }
#endif

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let beganTracking = super.beginTracking(touch, with: event)
        if (beganTracking) {
            self.trackingHandler?(FTSliderTrackingState.began)
        }
        return beganTracking
    }
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let shouldContinue = super.continueTracking(touch, with: event)
        return shouldContinue
    }
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        self.trackingHandler?(FTSliderTrackingState.ended)
    }
}
//********************************
class FTNavigatorTouchByPassView : UIView {
    @IBOutlet weak var sliderView : FTPageSlider?
    @IBOutlet weak var contentView : UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var view = super.hitTest(point, with: event);
        if let slider = self.sliderView, let containerView = self.contentView {
            let trackRect = slider.trackRect(forBounds: slider.bounds)
            let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: trackRect, value: slider.value)
            let thumbRectInSuperView = slider.convert(thumbRect, to: containerView)
            if(!thumbRectInSuperView.contains(point)) {
                view = nil;
            }
        }
        return view;
    }
}
//********************************
