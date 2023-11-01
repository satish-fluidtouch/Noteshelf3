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
    
    @IBOutlet weak var contentWidthLayoutConstraint : NSLayoutConstraint?
    @IBOutlet weak var viewHeightLayoutConstraint : NSLayoutConstraint?

    @IBOutlet weak var dismissBtn: FTStyledButton!
    @IBOutlet weak var remindMeLaterBtn: FTStyledButton!
    @IBOutlet weak var infoLbl: FTStyledLabel?

    @IBOutlet weak var contentView: UIView!
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
        self.remindMeLaterBtn?.titleLabel?.adjustsFontSizeToFitWidth = true;
        self.remindMeLaterBtn?.titleLabel?.minimumScaleFactor = 0.5;
        self.dismissBtn?.titleLabel?.adjustsFontSizeToFitWidth = true;
        self.dismissBtn?.titleLabel?.minimumScaleFactor = 0.5;

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
            self.dismissBtn?.style = FTButtonStyle.style8.rawValue;
            self.remindMeLaterBtn?.style = FTButtonStyle.style8.rawValue;
            self.infoLbl?.style = FTLabelStyle.style4.rawValue;
        }
        else {
            self.remindMeLaterBtn?.style = FTButtonStyle.style6.rawValue;
            self.dismissBtn?.style = FTButtonStyle.style6.rawValue;
            self.infoLbl?.style = FTLabelStyle.style3.rawValue;
        }
        self.remindMeLaterBtn?.setStyleTitle(NSLocalizedString("RemindMeLater", comment: "Remind Me Later"), for: UIControl.State.normal);
        self.dismissBtn?.setStyleTitle(NSLocalizedString("Dismiss", comment: "Dismiss"), for: UIControl.State.normal);
        self.infoLbl?.styleText = NSLocalizedString("WatchAdInfo", comment: "Watch ad info");
        self.infoLbl?.tintColor = .label
        self.contentView.backgroundColor = .appColor(.watchViewBg)
        self.dismissBtn.borderColor = .label
        self.remindMeLaterBtn.layer.borderColor = UIColor.label.cgColor
        self.dismissBtn.layer.borderColor = UIColor.label.cgColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func dismissBtnTapped(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: FTWatchAdDoNotShowDefaultsKey);
        UserDefaults.standard.synchronize();
        self.removeBannerAd(animated: true);
    }
    
    @IBAction func remindMeLaterBtnTapped(_ sender: Any) {
        UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey: FTWatchAdLastShownTimeDefaultsKey);
        UserDefaults.standard.synchronize();
        self.removeBannerAd(animated: true);
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
