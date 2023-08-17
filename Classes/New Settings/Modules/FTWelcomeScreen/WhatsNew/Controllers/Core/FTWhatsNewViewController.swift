//
//  FTWhatsNewViewController.swift
//  Noteshelf
//
//  Created by Srikanth on 08/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SafariServices

typealias FTEmptyCompletion = (() -> Void);

#if DEBUG
let nextSlideShowTimeInSeconds: Double = 60
#else
let nextSlideShowTimeInSeconds: Double = 7*24*60*60
#endif

private var isAttemptedToPresentWhatsNew = false

let learnMoreLinkLatestVersion = "https://medium.com/noteshelf/whats-new-in-noteshelf-v8-6-new-features-ui-enhancements-revamped-shelf-and-more-f914183aa22b"

class FTWhatsNewViewController: UIViewController {

    @IBOutlet fileprivate weak var closeButton: UIButton!
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var scrollView: UIScrollView!

    @IBOutlet weak var scrollContainer: UIView!
    private var source: FTSourceScreen!
    private var placeOfSlideShow: FTWhatsNewSlideShowPlace = .shelf
    
    private var slideStartTime: Date?
    private var slideEndTime: Date?
    
    var dismissBlock: FTEmptyCompletion?
    var viewControllers: [FTWhatsNewSlideViewController]!
    let customTransitioningDelegate = FTFormSheetPresentationManager(with: .blur);
    fileprivate var pageSize: CGSize!

    override func viewDidLoad() {
        super.viewDidLoad()
        pageSize = scrollView.bounds.size
        viewControllers = FTWhatsNewManger.viewControllers(for: self.source, slideShowPlace: self.placeOfSlideShow);
        viewControllers.forEach({ [weak self] slideViewController in
            guard let strongSelf = self else { return }
            slideViewController.delegate = strongSelf
        })
        pageControl.numberOfPages = self.viewControllers.count
        pageControl.currentPage = 0
        if self.source != .settings {
            self.pageControl.hidesForSinglePage = true
        }
        scrollView.contentSize = CGSize(width: CGFloat(viewControllers.count) * pageSize.width, height: pageSize.height)
        for i in 0..<viewControllers.count {
            let vc = viewControllers[i]
            vc.view.frame = CGRect(x: CGFloat(i) * pageSize.width,
                                   y: 0,
                                   width: pageSize.width,
                                   height: pageSize.height)
            scrollView.addSubview(vc.view)
            addChild(vc)
        }
        scrollContainer.layer.cornerRadius = 10.0
        scrollContainer.layer.masksToBounds = true

        updateContainerUIBasedOnCurrentPage()
        self.configureSwipeToCloseSlideShow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.viewControllers.count == 1 {
            viewControllers.first?.playAnimation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.slideStartTime = Date()
    }
    
    private func configureSwipeToCloseSlideShow() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            self.updateWhatsNewPageStatus()
            // Tracking slide show time and close
            self.slideEndTime = Date()
            let pageTitle = self.getCurrentPageTitle()
            if pageTitle != "" {
                FTSlideShowTimeTracker.shared.trackSlideShowTime(startTime: self.slideStartTime, endTime: self.slideEndTime, pageTitle: pageTitle, source: self.source)
            }
                self.dismiss(animated: true, completion: {
                    isAttemptedToPresentWhatsNew = false
                    self.dismissBlock?()
                })
        }
    }

    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer, swipeGesture.direction == .down {
            track("WhatsNew_Slide_SwipeDownToClose", params: [:], screenName: FTScreenNames.whatsNew)
            self.close()
        }
    }
    
    class func showIfNeeded(on controller:UIViewController, source: FTSourceScreen, placeOfSlideShow: FTWhatsNewSlideShowPlace, dismissBlock: FTEmptyCompletion?) {
        if FTWhatsNewManger.canShow(from:controller, placeOfSlideShow: placeOfSlideShow) || source == .settings {
            if(isAttemptedToPresentWhatsNew == false) {
                let storyboard = UIStoryboard(name: "FTWhatsNew", bundle: nil)
                guard let whatsNewViewController = storyboard.instantiateInitialViewController() as? FTWhatsNewViewController else { dismissBlock?(); return }
                whatsNewViewController.source = source
                whatsNewViewController.placeOfSlideShow = placeOfSlideShow
                whatsNewViewController.dismissBlock = dismissBlock
                if controller.view.window?.visibleViewController is UIAlertController {
                    whatsNewViewController.modalPresentationStyle = .formSheet
                } else {
                    whatsNewViewController.modalPresentationStyle = .custom
                    whatsNewViewController.transitioningDelegate = whatsNewViewController.customTransitioningDelegate
                }
                controller.present(whatsNewViewController, animated: true, completion: nil)
                isAttemptedToPresentWhatsNew = true
            }
        } else {
            dismissBlock?();
        }
    }
}

fileprivate extension FTWhatsNewViewController {

    func currentPageIndex() -> Int {
        return Int(round( scrollView.contentOffset.x / pageSize.width ))
    }

    func currentRenderingViewController() -> FTWhatsNewSlideViewController {
        let index = currentPageIndex()
        return viewControllers[index]
    }

    func updateContainerUIBasedOnCurrentPage() {
        let viewController = currentRenderingViewController()
        closeButton.setImage(viewController.closeButtonImage, for: .normal);
        scrollView.backgroundColor = viewController.view.backgroundColor;
        pageControl.pageIndicatorTintColor = viewController.pageControlTintColor;
        pageControl.currentPageIndicatorTintColor = viewController.pageControlCurrentPageTintColor;
    }

    func moveToPage(index: Int) {
        let targetOffset = CGPoint(x: CGFloat(index) * pageSize.width, y: 0)
        scrollView.setContentOffset(targetOffset, animated: true)
    }

    func updateCurrentPage() {
        self.slideEndTime = Date()
        if self.source == .settings {
            track("Settings_WhatsNew_NextSlide", params: [:], screenName: FTScreenNames.whatsNew)
        }
        let currentIndex = currentPageIndex()
        if pageControl.currentPage != currentIndex { // to avoid swipe gesture slide show times if did multiple times
            let pageTitle = self.getCurrentPageTitle()
            if pageTitle != "" {
                FTSlideShowTimeTracker.shared.trackSlideShowTime(startTime: self.slideStartTime, endTime: self.slideEndTime, pageTitle: pageTitle, source: self.source) // before current page disappears
            }
            self.slideStartTime = Date() // next slide start time
            pageControl.currentPage = currentIndex
        }
        viewControllers.forEach { viewController in
            viewController.stopAnimation()
        }
        viewControllers[currentIndex].playAnimation()
        updateContainerUIBasedOnCurrentPage()
        self.updateWhatsNewPageStatus()
    }

    @IBAction func closeClicked(_ button: UIButton) {
        if self.source == .settings && (self.pageControl.currentPage == self.pageControl.numberOfPages - 1) {
            FTWhatsNewManger.setAsWhatsNewViewed()
            self.close()
        } else {
            self.updateWhatsNewPageStatus()
            self.close()
        }
        if self.source == .settings {
            track("Settings_WhatsNew_Slide_Close", params: ["title" :  getCurrentPageTitle()], screenName: FTScreenNames.whatsNew)
        } else {
            track("WhatsNew_Slide_Close", params: ["title" :  getCurrentPageTitle()], screenName: FTScreenNames.whatsNew)
        }
    }
    
    private func getCurrentPageTitle() -> String {
        var currentPageTitle: String = ""
        if self.pageControl.currentPage < self.viewControllers.count, let title = self.viewControllers[self.pageControl.currentPage].helpTitle?.text {
            currentPageTitle = title
        }
        return currentPageTitle
    }
    
    private func updateWhatsNewPageStatus() {
        let standardUserDefaults = UserDefaults.standard
        if let slidesData = standardUserDefaults.value(forKey: persistenceKey) as? Data, let slides = try? JSONDecoder().decode([FTWhatsNewViewSlide].self, from: slidesData) {
            if let controller = self.children.first {
                let identifier = String(describing: controller.classForCoder)
                for slide in slides where identifier == slide.slideIdentifier {
                    slide.isExpired = true
                }
            }
            let weekInSeconds = Date().timeIntervalSince1970 + nextSlideShowTimeInSeconds
            standardUserDefaults.set(weekInSeconds, forKey: WhatsNewReminderTime)
            standardUserDefaults.synchronize()
            FTWhatsNewManger.storeSlides(slides)
        }
    }

    @IBAction func pageToggled() {
        moveToPage(index: pageControl.currentPage)
    }
}

extension FTWhatsNewViewController: FTWhatsNewSlideViewControllerDelegate {
    func whatsNewSlideViewControllerDidClickNext(whatsNewSlideViewController: FTWhatsNewSlideViewController) {
        let gotoPageIndex = self.pageControl.currentPage + 1;

        let targetContentOffset = CGPoint(x: CGFloat(gotoPageIndex) * pageSize.width, y: 0)
        let targetFrame = CGRect(origin: targetContentOffset, size: pageSize)
        scrollView.scrollRectToVisible(targetFrame, animated: true)
    }

    func close() {
        self.slideEndTime = Date()
        let pageTitle = self.getCurrentPageTitle()
        if pageTitle != "" {
            FTSlideShowTimeTracker.shared.trackSlideShowTime(startTime: self.slideStartTime, endTime: self.slideEndTime, pageTitle: pageTitle, source: self.source)
        }
        dismiss(animated: true, completion: {
            isAttemptedToPresentWhatsNew = false
            self.dismissBlock?();
        });
    }
    
    func learnMoreTapped(whatsNewSlideViewController: FTWhatsNewSlideViewController) {
        self.slideEndTime = Date()
        let pageTitle = self.getCurrentPageTitle()
        if pageTitle != "" {
            track("WhatsNew_Slide_Learnmore", params: ["title" : pageTitle], screenName: FTScreenNames.whatsNew)
            FTSlideShowTimeTracker.shared.trackSlideShowTime(startTime: self.slideStartTime, endTime: self.slideEndTime, pageTitle: pageTitle, source: self.source)
        }
        if let url = URL(string: learnMoreLinkLatestVersion) {
            UIApplication.shared.open(url)
        }
    }
}

extension FTWhatsNewViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentPage()
        }
    }
}
