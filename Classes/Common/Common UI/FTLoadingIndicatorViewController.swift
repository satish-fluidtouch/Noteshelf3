//
//  FTLoadingIndicatorViewController.swift
//  Noteshelf
//
//  Created by Siva on 23/07/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objc enum FTLoadingIndicatorStyle: Int {
    case justText
    case activityIndicator
    case progressView
}

typealias FTLoadingCancelCallBack = ((FTLoadingIndicatorViewController) -> Void);

@objcMembers class FTLoadingIndicatorViewController: UIViewController {
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var contentStackView: UIStackView?
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet private weak var progressView: RPCircularProgress?
    @IBOutlet private weak var labelText: FTStyledLabel?
    @IBOutlet private weak var successCheckBox:BEMCheckBox?
    
    @IBOutlet private weak var cancelButtonHolderView: UIView?
    @IBOutlet private weak var cancelButton: FTStyledButton?
    @IBOutlet private weak var cancelButtonBorderView: UIView?
    
    @IBOutlet private weak var labelTextHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var contentViewMinimumWidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var contentViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var stackViewCenterAlignmentConstraint: NSLayoutConstraint?
    
    private var style = FTLoadingIndicatorStyle.justText;
    private var text: String?;
    private var cancelCallBack: FTLoadingCancelCallBack?;
    private var delay: TimeInterval = 0;
    
    var progress: CGFloat = 0 {
        didSet {
            if self.isViewLoaded {
                self.progressView?.updateProgress(self.progress,
                                                 animated: false,
                                                 initialDelay: 0,
                                                 duration: 0,
                                                 completion: nil);
            }
        }
    }

    class func show(onMode style: FTLoadingIndicatorStyle,
                    from viewController: UIViewController,
                    withText text: String,
                    andDelay delay: TimeInterval = 0) -> FTLoadingIndicatorViewController
    {
        let loadingIndicatorViewController = UIStoryboard(name: "FTCommon", bundle: nil).instantiateInitialViewController() as! FTLoadingIndicatorViewController;
        loadingIndicatorViewController.style = style;
        loadingIndicatorViewController.text = text;
        loadingIndicatorViewController.delay = delay;
        loadingIndicatorViewController.setCancelCallback(nil)

        if let presentedContorller = viewController.presentedViewController
            ,!presentedContorller.isBeingDismissed
            , !presentedContorller.isBeingPresented
        {
            loadingIndicatorViewController.modalPresentationStyle = .overCurrentContext;
            presentedContorller.present(loadingIndicatorViewController, animated: false) {
                loadingIndicatorViewController.view.layer.zPosition = 100;
                loadingIndicatorViewController.updateIndicator()
            }
            return loadingIndicatorViewController;
        }
        viewController.addChild(loadingIndicatorViewController);
        loadingIndicatorViewController.view.frame = viewController.view.bounds;
        viewController.view.addSubview(loadingIndicatorViewController.view);
        loadingIndicatorViewController.view.layer.zPosition = 100;
        loadingIndicatorViewController.updateIndicator()
        return loadingIndicatorViewController;
    }

    //MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad();
        self.successCheckBox?.onCheckColor = UIColor.white
        self.successCheckBox?.on = false
        self.successCheckBox?.onFillColor = UIColor.init(hexString: "F97641")
        self.successCheckBox?.lineWidth = 3.0
        self.successCheckBox?.onTintColor = UIColor.init(hexString: "F97641")
        self.successCheckBox?.onAnimationType = BEMAnimationType.fill
        
        self.contentView?.addShadow(color: .black.withAlphaComponent(0.2), offset: CGSize(width: 0, height: 10), opacity: 1, shadowRadius: 20)

        self.updateIndicator();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        
        self.layoutUI();
        
        if self.isCancelable {
            if let text = self.labelText,
                let stackView = self.contentStackView,
                text.sizeThatFits(CGSize.init(width: stackView.frame.width, height: 0)).height > 16 {
                self.stackViewCenterAlignmentConstraint?.constant = -21;
                self.contentStackView?.spacing = 5;
            }
            else {
                self.stackViewCenterAlignmentConstraint?.constant = -25;
                self.contentStackView?.spacing = 13;
            }
        }
        else {
            self.contentStackView?.spacing = 16;
        }
    }
    
    @IBAction func cancelButtonClicked() {
        if let cancelCallBack = self.cancelCallBack {
            cancelCallBack(self);
        }
    }
            
    func setCancelCallback(_ callback: FTLoadingCancelCallBack?)  {
        self.cancelCallBack = callback;
        self.updateCancelButtonVisibility();
    }
        
    func hide(_ completionHandler: (() -> Void)?) {
        if(!Thread.current.isMainThread) {
            runInMainThread {
                self.hide(completionHandler);
            }
            return;
        }
        if nil == self.parent,
           let presentingController = self.presentingViewController {
            self.dismiss(animated: false) {
                completionHandler?();
            }
            return;
        }
        self.removeFromParent();
        self.view.removeFromSuperview();
        completionHandler?();
    }
    
    func hide(afterDelay delay: TimeInterval = 0) {
        if(delay == 0) {
            self.hide(nil)
        }
        else {
            runInMainThread(delay) {
                self.hide(nil);
            }
        }
    }
    
    func hideWithSuccessIndication(){
        DispatchQueue.main.async {
            self.setCancelCallback(nil)
            self.text = NSLocalizedString("Done", comment: "Done") + "!"
            self.updateIndicator()
            
            self.successCheckBox?.isHidden = false
            self.successCheckBox?.setOn(true, animated: true)
            
            self.hide(afterDelay: 2.0);
        }
    }
    
    func setText(_ text:String){
        self.labelText?.styleText = text
        self.view.setNeedsLayout();
    }
}

private extension FTLoadingIndicatorViewController
{
    var isCancelable: Bool {
        if nil != self.cancelCallBack {
            return true;
        }
        return false;
    }
    
    func switchStyle(to style: FTLoadingIndicatorStyle) {
        self.style = style;
        self.view.setNeedsLayout();
    }
    
    func updateIndicator(){
        if(!Thread.current.isMainThread){
            runInMainThread {
                self.updateIndicator()
            }
            return
        }
        if(self.progressView == nil) {
            return
        }
        self.progress = 0
        self.progressView?.updateProgress(self.progress,
                                         animated: false,
                                         initialDelay: 0,
                                         duration: 0,
                                         completion: nil);
        self.labelText?.styleText = self.text;
        self.switchStyle(to: style)

        self.cancelButton?.style = 8;
        self.cancelButton?.setStyleTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal);
        self.cancelButtonBorderView?.layer.borderColor = UIColor.label.cgColor;
        self.cancelButtonBorderView?.layer.borderWidth = 0.5;
        self.cancelButtonBorderView?.layer.cornerRadius = 4;
        self.cancelButtonBorderView?.layer.masksToBounds = true;
        
        self.layoutUI();
        
        if self.delay > 0 {
            self.view.isHidden = true;
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay, execute: { [weak self] in
                self?.view.isHidden = false;
            });
        }
        self.view.setNeedsLayout()
    }

    func updateCancelButtonVisibility() {
        guard nil != self.cancelButton else {
            return;
        }
        
        self.cancelButtonHolderView?.isHidden = false;
        self.contentViewMinimumWidthConstraint?.constant = 152;
        self.contentViewHeightConstraint?.constant = 145;
        self.stackViewCenterAlignmentConstraint?.constant = -25;
        if nil != self.cancelCallBack {
            self.cancelButton?.addTarget(self, action: #selector(self.cancelButtonClicked), for: .touchUpInside);
        }
        else {
            self.contentViewMinimumWidthConstraint?.constant = 120;
            self.contentViewHeightConstraint?.constant = 120;
            self.cancelButtonHolderView?.isHidden = true;
            self.stackViewCenterAlignmentConstraint?.constant = 0;
        }
    }

    func layoutUI() {
        self.labelText?.isHidden = (text == "");
        self.activityIndicatorView?.isHidden = false;
        self.progressView?.isHidden = false;
        
        switch self.style {
        case .justText:
            self.activityIndicatorView?.isHidden = true;
            self.progressView?.isHidden = true;
            if let contentView = self.contentView {
                self.labelTextHeightConstraint?.constant = contentView.frame.height;
            }
        case .activityIndicator:
            self.progressView?.isHidden = true;
            self.activityIndicatorView?.isHidden = false;
            if let indicatorView = self.activityIndicatorView,
                !indicatorView.isAnimating {
                self.activityIndicatorView?.startAnimating();
            }
        case .progressView:
            self.activityIndicatorView?.isHidden = true;
            self.progressView?.isHidden = false;
            self.progressView?.updateProgress(self.progress,
                                              animated: false,
                                              initialDelay: 0,
                                              duration: 0,
                                              completion: nil);
        }
        self.updateCancelButtonVisibility();
    }
}
