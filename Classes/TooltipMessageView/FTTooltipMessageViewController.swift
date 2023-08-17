//
//  FTTooltipMessageViewController.swift
//  Noteshelf
//
//  Created by Naidu on 26/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc enum FTTooltipStyle: Int {
    case darkPositive
    case darkNegative
    case lightPositive
    case lightNegative
    case simpleMessage
    case popOver
}
protocol FTTooltipMessageViewControllerDelegate : NSObjectProtocol {
    func toolTipMessageController(controller : FTTooltipMessageViewController, didTapOnClose : UIButton);
}

class FTTooltipMessageViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    fileprivate var textContainer : NSTextContainer?
    fileprivate var textStorage : NSTextStorage?
    fileprivate var layoutManager = NSLayoutManager();
    fileprivate let TAG_POPOVER = 9999

    @IBOutlet var messageLabel:FTStyledLabel!
    @IBOutlet var contentView:UIView!
    @IBOutlet var overlayView:UIView!
    @IBOutlet var contentHolderView:UIView!
    var tipStyle:FTTooltipStyle! = .lightNegative
    @IBOutlet var contentHolderViewTopY:NSLayoutConstraint!
    @IBOutlet var contentViewTopY:NSLayoutConstraint!
    
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    private var dismissTimer:Timer?
    
    var messageDisplayDuration:Double! = 0.3
    var messageDismissDuration:Double! = 1.5
    #if targetEnvironment(macCatalyst)
        var defaultPadding:CGFloat = 0.0
    #else
        var defaultPadding:CGFloat = 64.0
    #endif

    weak var delegate : FTTooltipMessageViewControllerDelegate?;
    private weak var targetViewController: UIViewController!
    
    @objc static let shared: FTTooltipMessageViewController = FTTooltipMessageViewController.init(nibName: "FTTooltipMessageViewController", bundle: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageLabel.font = UIFont.appFont(for: .regular, with: self.isRegularClass() ? 14:12)
        self.view.isUserInteractionEnabled = false
        self.contentView.layer.shadowOpacity = 0.1;
        self.contentView.layer.shadowRadius = 10;
        self.contentView.layer.shadowOffset = CGSize.init(width: 0, height: 4);
        
        if let touchView = self.view as? FTTouchByPassView {
            touchView.contentView = self.contentHolderView;
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        if #available(iOS 13.0, *) {
            self.contentView.layer.shadowColor = UIColor.black.withAlphaComponent(UITraitCollection.current.userInterfaceStyle == .light ? 0.9 : 0.5).cgColor
        } else {
            self.contentView.layer.shadowColor = UIColor.black.cgColor
        };
        self.textContainer?.size = self.messageLabel.bounds.size;
    }

    func setTipStyle(_ style:FTTooltipStyle){
        self.tipStyle = style
    }
    
    // Created for calling from objective-c classes
    func presentToastInViewConroller(_ targetViewController:UIViewController, withMessage message:String!, andStyleString style:String!){
        switch style
        {
        case "darkPositive":
            self.tipStyle = .darkPositive
        case "darkNegative":
            self.tipStyle = .darkNegative
        case "lightPositive":
            self.tipStyle = .lightPositive
        case "lightNegative":
            self.tipStyle = .lightNegative
        case "simpleMessage":
            self.tipStyle = .simpleMessage
        default:
            break
        }
        self.presentToastInViewConroller(targetViewController, withMessage: message, topPadding: self.defaultPadding, andStyle:self.tipStyle)
    }
    
    func presentToastInViewConroller(_ targetViewController:UIViewController, withMessage message:String!, andStyle style:FTTooltipStyle!){
        let safeAreaInsets = targetViewController.view.safeAreaInsets;
        if(safeAreaInsets.top > 0 || targetViewController.traitCollection.verticalSizeClass == .compact) {
            self.defaultPadding = (44+safeAreaInsets.top)
        }
        self.presentToastInViewConroller(targetViewController, withMessage: message, topPadding: self.defaultPadding, andStyle:style)
    }
    
    func addPopoverMessage(_ targetViewController:UIViewController,
                           withMessage message:NSMutableAttributedString!,
                           withSourceView sourceView: UIView,
                           andSourceRect sourceRect: CGRect,
                           andArrowDirection arrowDirection: UIPopoverArrowDirection) {
        if self.view.viewWithTag(TAG_POPOVER) == nil {
            let messageLbl = FTStyledLabel()
            messageLbl.numberOfLines = 0
            messageLbl.attributedText = message
            messageLbl.textColor = .darkText
            messageLbl.textAlignment = .center
            messageLbl.tag = TAG_POPOVER
            messageLbl.font = UIFont.appFont(for: .regular, with: self.isRegularClass() ? 18:14)
            self.view.addSubview(messageLbl)
        }
        
        if let label = self.view.viewWithTag(TAG_POPOVER) as? UILabel {
            label.attributedText = message
            let maxMessageSize = CGSize(width: targetViewController.view.bounds.size.width/2 , height: targetViewController.view.bounds.size.height + 40)
            let messageSize = label.sizeThatFits(maxMessageSize)
            let actualWidth = min(messageSize.width, maxMessageSize.width)
            let actualHeight = min(messageSize.height, maxMessageSize.height)
            label.frame = CGRect(x: 5.0, y: 10.0, width: actualWidth , height: actualHeight)
            var frame = label.bounds
            frame.size.height += 20
            frame.size.width += 10
            #if DEBUG
            debugPrint("frame: \(frame)")
            #endif
            self.view.frame = frame
        }

        let navigationController = UINavigationController.init(rootViewController: self)
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .popover;
        let popoverPresentationController = navigationController.popoverPresentationController;
        navigationController.preferredContentSize = CGSize.init(width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        popoverPresentationController?.delegate = self
        popoverPresentationController?.sourceView = sourceView;
        popoverPresentationController?.sourceRect = sourceView.bounds
        popoverPresentationController?.backgroundColor = UIColor.white;
        popoverPresentationController?.permittedArrowDirections = arrowDirection
        targetViewController.present(navigationController, animated: true)
    }
    
    func presentToastInViewConroller(_ targetViewController:UIViewController,
                                     withMessage message:String!,
                                     topPadding padding:CGFloat,
                                     andStyle style:FTTooltipStyle!) {
        self.tipStyle=style
        self.targetViewController = targetViewController
        let isAlreadyPresented = (self.view.superview != nil) && (self.contentViewTopY.constant == 0)
        self.contentHolderViewTopY.constant = padding

        if(isAlreadyPresented == false){
            self.view.frame = targetViewController.view.bounds
            targetViewController.view.addSubview(self.view)
            targetViewController.addChild(self)
        }
        self.messageLabel.text = message
        switch style
        {
        case .darkPositive?:
                self.messageLabel.textColor = UIColor.init(hexString: "78B2CC")
                //self.overlayView.backgroundColor = UIColor.init(red: 45/255.0, green: 45/255.0, blue: 45/255.0, alpha: 0.9)

        case .darkNegative?:
                self.messageLabel.textColor = UIColor.init(hexString: "CC4235")
                //self.overlayView.backgroundColor = UIColor.init(red: 45/255.0, green: 45/255.0, blue: 45/255.0, alpha: 0.9)

        case .lightPositive?:
                self.messageLabel.textColor = UIColor.init(hexString: "383838")
                //self.overlayView.backgroundColor = UIColor.init(red: 252/255.0, green: 252/255.0, blue: 250/255.0, alpha: 1.0)

        case .lightNegative?:
                self.messageLabel.textColor = UIColor.init(hexString: "CC4235")
                //self.overlayView.backgroundColor = UIColor.bgColor
                
        case .simpleMessage?:
                self.messageLabel.textColor = UIColor.white
                self.overlayView.backgroundColor = UIColor.init(hexString: "696968")
                self.overlayView.layer.cornerRadius = 10;
                let labelWidth = min(self.messageLabel.intrinsicContentSize.width, (targetViewController.view.window?.frame.width ?? 0.0) - 40)
                self.contentViewWidthConstraint.constant = labelWidth
            
            default:
                break
            }
        self.view.isUserInteractionEnabled = false
        //****************************************************** Handle if already tip is presented
        if(isAlreadyPresented){
            self.dismissTimer?.invalidate();
            self.dismissTimer = Timer.scheduledTimer(timeInterval: self.messageDismissDuration, target: self, selector: #selector(FTTooltipMessageViewController.dismissToolTipMessageController), userInfo: nil, repeats: false)
            self.view.layoutIfNeeded()
            return
        }
        //******************************************************
        self.contentViewTopY.constant = -self.contentView.bounds.size.height
        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: self.messageDisplayDuration, animations: {
            self.contentViewTopY.constant = 0
            self.view.layoutIfNeeded()
        }){ (_) in
            self.dismissTimer?.invalidate()
            self.dismissTimer = Timer.scheduledTimer(timeInterval: self.messageDismissDuration, target: self, selector: #selector(FTTooltipMessageViewController.dismissToolTipMessageController), userInfo: nil, repeats: false)
        }
        //******************************************************
    }
    
    @objc func dismissToolTipMessageController(){
        weak var weakSelf = self
        UIView.animate(withDuration: self.messageDisplayDuration, animations: {
            weakSelf?.contentViewTopY.constant = -(weakSelf?.contentView.bounds.size.height)!
            weakSelf?.view.layoutIfNeeded()
        }){ (_) in
            if let msgView = weakSelf?.view.viewWithTag(weakSelf!.TAG_POPOVER) {
                msgView.removeFromSuperview()
            }
            weakSelf?.dismissTimer?.invalidate()
            weakSelf?.view.removeFromSuperview()
            weakSelf?.removeFromParent()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        dismissToolTipMessageController()
        return true
    }
}
