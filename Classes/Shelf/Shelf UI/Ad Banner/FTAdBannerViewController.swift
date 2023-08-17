//
//  FTAdBannerViewController.swift
//  Noteshelf
//
//  Created by Amar on 19/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

fileprivate let FTWatchAdDoNotShowDefaultsKey = "watch_banner_do_not_show";
fileprivate let FTWatchAdLastShownTimeDefaultsKey = "watch_banner_last_shown";

fileprivate let FTBannerAdHeight : CGFloat = 128;
fileprivate let FTBannerAdHeightCompactHeight : CGFloat = 91;

fileprivate let FTBannerAdBottomSpacingRegualr : CGFloat = -12;

class FTTouchByPassView : UIView {
    @IBOutlet weak var contentView : UIView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var view = super.hitTest(point, with: event);
        if let contentHolderView = self.contentView {
            if(!contentHolderView.frame.contains(point)) {
                view = nil;
            }
        }
        return view;
    }
}

class FTAdBannerViewController: UIViewController {
    
    @IBOutlet weak var contentView : UIView?
    @IBOutlet weak var infoLabel : FTStyledLabel?
    @IBOutlet weak var dismissButton : FTStyledButton?
    @IBOutlet weak var remindLaterButton : FTStyledButton?
    @IBOutlet weak var contentWidthLayoutConstraint : NSLayoutConstraint?
    @IBOutlet weak var viewHeightLayoutConstraint : NSLayoutConstraint?

    fileprivate var bottomConstraint : NSLayoutConstraint!;
    

    static func showAdBannerOn(viewController : UIViewController) -> FTAdBannerViewController?
    {
        if(!self.canShowWatchBanner()) {
            return nil;
        }
        let bannerHeight = FTBannerAdHeight;

        let controller = FTAdBannerViewController.init(nibName:"FTAdBannerViewController" ,bundle:nil);
        viewController.addChild(controller);
        var frame = viewController.view.frame;
        frame.size.height = bannerHeight;
        frame.origin.y = viewController.view.frame.height - bannerHeight;
        controller.view.frame = frame;
        controller.view.translatesAutoresizingMaskIntoConstraints = false;
        
        viewController.view.addSubview(controller.view);
        guard let controllerView = controller.view else {
            return controller;
        }
        

        let widthConstraint = NSLayoutConstraint.init(item: controllerView,
                                                      attribute: NSLayoutConstraint.Attribute.width,
                                                      relatedBy: NSLayoutConstraint.Relation.equal,
                                                      toItem: viewController.view,
                                                      attribute: NSLayoutConstraint.Attribute.width,
                                                      multiplier: 1,
                                                      constant: 0);

        var bottomConstant : CGFloat = FTBannerAdBottomSpacingRegualr;
        if(!controller.isRegularClass()) {
            bottomConstant = 0;
        }
        let bottomConstraint = NSLayoutConstraint.init(item: controllerView,
                                                       attribute: NSLayoutConstraint.Attribute.bottom,
                                                      relatedBy: NSLayoutConstraint.Relation.equal,
                                                      toItem: viewController.view,
                                                      attribute: NSLayoutConstraint.Attribute.bottom,
                                                      multiplier: 1,
                                                      constant: bottomConstant);
        controller.bottomConstraint = bottomConstraint;
        
        let centerXConstraint = NSLayoutConstraint.init(item: controllerView,
                                                        attribute: NSLayoutConstraint.Attribute.centerX,
                                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                                       toItem: viewController.view,
                                                       attribute: NSLayoutConstraint.Attribute.centerX,
                                                       multiplier: 1,
                                                       constant: 0);

        let heightConstraint = NSLayoutConstraint.init(item: controllerView,
                                                       attribute: NSLayoutConstraint.Attribute.height,
                                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                                      toItem: nil,
                                                      attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                                                      multiplier: 1,
                                                      constant: bannerHeight);
        controller.viewHeightLayoutConstraint = heightConstraint;
        NSLayoutConstraint.activate([widthConstraint,heightConstraint,centerXConstraint,bottomConstraint]);
        return controller;
    }
    
    func removeBannerAd(animated : Bool = false)
    {
        if(animated) {
            UIView.animate(withDuration: 0.2, animations: {
                self.bottomConstraint.constant = FTBannerAdHeight + self.view.safeAreaInsets.bottom;
                self.view.superview?.layoutIfNeeded();
            }, completion: { (complete) in
                self.removeFromParent();
                self.view.removeFromSuperview();
            });
        }
        else {
            self.removeFromParent();
            self.view.removeFromSuperview();
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remindLaterButton?.titleLabel?.adjustsFontSizeToFitWidth = true;
        self.remindLaterButton?.titleLabel?.minimumScaleFactor = 0.5;
        self.dismissButton?.titleLabel?.adjustsFontSizeToFitWidth = true;
        self.dismissButton?.titleLabel?.minimumScaleFactor = 0.5;

        self.updateUIStyles();
        
        self.contentView?.layer.shadowColor = UIColor.black.cgColor;
        self.contentView?.layer.shadowOpacity = 0.1;
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();

        if(self.isRegularClass()) {
            self.viewHeightLayoutConstraint?.constant = FTBannerAdHeight;
            self.bottomConstraint.constant = FTBannerAdBottomSpacingRegualr;
            self.view.layoutIfNeeded();
            self.contentView?.layer.shadowPath = nil;
            self.contentView?.layer.cornerRadius = 20;
            self.contentView?.layer.shadowRadius = 40;
        }
        else {
            self.bottomConstraint.constant = 0;
            let veritcalSizeClass = self.traitCollection.verticalSizeClass;
            if(veritcalSizeClass == .compact) {
                self.viewHeightLayoutConstraint?.constant = FTBannerAdHeightCompactHeight;
            }
            else {
                self.viewHeightLayoutConstraint?.constant = FTBannerAdHeight;
            }
            self.view.layoutIfNeeded();
            
            var shadowrect = self.contentView!.bounds;
            shadowrect.size.height = 10;
            let shadowPath = UIBezierPath.init(rect: shadowrect);
            self.contentView?.layer.shadowPath = shadowPath.cgPath;

            self.contentView?.layer.cornerRadius = 0;
            self.contentView?.layer.shadowRadius = 10;
        }
        self.updateUIStyles();
    }
    
    fileprivate func updateUIStyles() {
        if(self.isRegularClass()) {
            self.dismissButton?.style = FTButtonStyle.style8.rawValue;
            self.remindLaterButton?.style = FTButtonStyle.style8.rawValue;
            self.infoLabel?.style = FTLabelStyle.style4.rawValue;
        }
        else {
            self.remindLaterButton?.style = FTButtonStyle.style6.rawValue;
            self.dismissButton?.style = FTButtonStyle.style6.rawValue;
            self.infoLabel?.style = FTLabelStyle.style3.rawValue;
        }
        self.remindLaterButton?.setStyleTitle(NSLocalizedString("RemindMeLater", comment: "Remind Me Later"), for: UIControl.State.normal);
        self.dismissButton?.setStyleTitle(NSLocalizedString("Dismiss", comment: "Dismiss"), for: UIControl.State.normal);
        self.infoLabel?.styleText = NSLocalizedString("WatchAdInfo", comment: "Watch ad info");
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapOnDismiss(_ sender : UIButton?)
    {
        UserDefaults.standard.set(true, forKey: FTWatchAdDoNotShowDefaultsKey);
        UserDefaults.standard.synchronize();
        self.removeBannerAd(animated: true);
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTBannerDidDismiss"),
                                        object: nil);
    }
    
    @IBAction func didTapOnRemindLater(_ sender : UIButton?)
    {

        UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: FTWatchAdLastShownTimeDefaultsKey);
        UserDefaults.standard.synchronize();
        self.removeBannerAd(animated: true);
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTBannerDidDismiss"),
                                        object: nil);
    }
    
    static func canShowWatchBanner() -> Bool {
        let thresholdDuration = Double(60*60*24);
        let donotShow = UserDefaults.standard.bool(forKey: FTWatchAdDoNotShowDefaultsKey);
        if(donotShow) {
            return false;
        }
        
        let lastshowndate = UserDefaults.standard.double(forKey: FTWatchAdLastShownTimeDefaultsKey);
        let currentdate = Date.timeIntervalSinceReferenceDate;
        if(lastshowndate == 0 || ((currentdate-lastshowndate) > thresholdDuration)) {
            return true;
        }
        return false;
    }
}
