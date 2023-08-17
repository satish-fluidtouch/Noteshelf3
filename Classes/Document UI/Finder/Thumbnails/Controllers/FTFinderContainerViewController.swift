//
//  FTFinderContainerViewController.swift
//  Noteshelf
//
//  Created by Siva on 05/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTFinderContainerViewController: UIViewController {
    @IBOutlet weak var containerViewWidthConstraint: NSLayoutConstraint!
    
    var finderViewController: FTFinderViewController!
    let presentationManager = FTSlideInPresentationManager();
    
    fileprivate var purpose = FTFinderPagePurpose.default;
    fileprivate var document:FTThumbnailableCollection!;
    fileprivate weak var delegate: FTFinderThumbnailsActionDelegate!;
    fileprivate var searchOptions: FTFinderSearchOptions!

    //MARK:- ScreenMode
    @IBOutlet weak var buttonToggleFullScreen: UIButton!
    private var isResizing = false;
    private let thresoldWidthChange: CGFloat = 40;
    private var distanceInForwardDirection: CGFloat = 0;
    private let reverseDirectionThresoldDistance: CGFloat = 10;

    private var screenWidth: CGFloat {
        return self.screenWidth(forFullscreenStatus: self.isFullScreen);
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return FTShelfThemeStyle.defaultTheme().preferredStatusBarStyle
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private var isFullScreen: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "FT_Thumbnails_FullScreen");
        }
        set {
            if newValue != self.isFullScreen {
                let userDefaults = UserDefaults.standard;
                userDefaults.set(newValue, forKey: "FT_Thumbnails_FullScreen");
                userDefaults.synchronize();
            }
        }
    }
    
    private func screenWidth(forFullscreenStatus isFullScreen: Bool) -> CGFloat {
        let width: CGFloat;
        if isFullScreen {
            width = AppDelegate.window.frame.width;
        }
        else if self.isRegularClass() {
            width = 300;
        }
        else {
            width = min(AppDelegate.window.frame.width, 335);
        }
        return min(AppDelegate.window.frame.width, width + self.safeAreaAdjustment);
    }

    private var safeAreaAdjustment: CGFloat {
        if (self.isIphoneX()) {
            return self.originalSafeAreaInsets().right;
        }
        else {
            return 0;
        }
    }

    @IBAction func toggleFullScreen() {
        self.finderViewController.isResizing = true;
        self.isResizing = false;
        self.isFullScreen = !self.isFullScreen;
        self.updateContainerLayout(withAnimation: true);
    }
    
    private func updateContainerLayout(withAnimation animated: Bool) {
        self.setScreenModeConstraints();
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            self.view.layoutIfNeeded();
        }) { (finished) in
            self.finderViewController.isResizing = false;
            if !self.isBeingPresented {
                self.finderViewController.view.layoutIfNeeded();
                self.finderViewController.collectionView.performBatchUpdates({
                    self.finderViewController.collectionView.collectionViewLayout.invalidateLayout();
                }, completion: nil);
            }
        }
    }
    
    private func setScreenModeConstraints() {
        let toggleButtonImageName: String!
        if self.isFullScreen {
            toggleButtonImageName = "flatbar";
            self.buttonToggleFullScreen.accessibilityLabel = "Collapse";
        }
        else {
            toggleButtonImageName = "flatbar";
            self.buttonToggleFullScreen.accessibilityLabel = "Expand";
        }
        self.buttonToggleFullScreen.setImage(UIImage(named: toggleButtonImageName), for: .normal);
        
        self.containerViewWidthConstraint.constant = self.screenWidth;
        self.view.needsUpdateConstraints();
    }
    
    @IBAction func handleDrag(_ panGestureRecognizer: UIPanGestureRecognizer) {
        if(self.isIphone()){
            return
        }
        let translation = panGestureRecognizer.translation(in: self.view);
        let widthChange = translation.x * (self.isFullScreen ? 1 : -1);

        switch panGestureRecognizer.state {
        case .began:
            self.finderViewController.isResizing = true;
            self.isResizing = true;
            self.distanceInForwardDirection = 0;
            break;
        case .changed:
            self.distanceInForwardDirection = max(widthChange, self.distanceInForwardDirection);
            let newWidth = self.screenWidth - translation.x;
            if newWidth <= self.screenWidth(forFullscreenStatus: true)
                && newWidth >= self.screenWidth(forFullscreenStatus: false) {
                self.containerViewWidthConstraint.constant = newWidth;
            }
            self.finderViewController.updateThumbnailContentIfNeeded()

            break;
        case .ended:
            if self.isResizing {
                if widthChange >= self.thresoldWidthChange
                    && self.distanceInForwardDirection - widthChange <= self.reverseDirectionThresoldDistance  {
                    self.toggleFullScreen();
                }
                else {
                    self.revertPosition();
                }
            }
            break;
        case .cancelled:
            fallthrough;
        case .possible:
            fallthrough;
        case .failed:
            self.revertPosition();
        }
    }
    
    private func revertPosition() {
        self.isFullScreen = !self.isFullScreen;
        self.toggleFullScreen();
    }
    
    //MARK:- NSObject
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    //MARK:- UIViewController
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.buttonToggleFullScreen.isHidden = self.isIphone()
        
        self.view.updateConstraintsIfNeeded();
        if !self.isResizing {
            self.setScreenModeConstraints();
            if self.isBeingPresented {
                if nil != self.finderViewController, nil != self.finderViewController.collectionView {
                    self.finderViewController.collectionView.collectionViewLayout.invalidateLayout();
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let thumbnailsNavgiationController = segue.destination as? UINavigationController, let finderViewController = thumbnailsNavgiationController.viewControllers[0] as? FTFinderViewController {
            self.finderViewController = finderViewController;
            
            finderViewController.document = document;
            finderViewController.purpose = self.purpose;
            finderViewController.delegate = self.delegate;
            finderViewController.searchOptions = self.searchOptions;
        }
    }

    //MARK:- Custom
    @IBAction func dismiss() { 
        self.dismiss(animated: true, completion: nil);
    }
    
    func configureThumbnails(forPurpose purpose: FTFinderPagePurpose, document:FTThumbnailableCollection, delegate: FTFinderThumbnailsActionDelegate!, searchOptions: FTFinderSearchOptions!) {
        self.document = document;
        self.purpose = purpose;
        self.delegate = delegate;
        self.searchOptions = searchOptions;
    }

}
