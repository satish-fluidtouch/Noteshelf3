//
//  FTInputCustomFontViewController.swift
//  Noteshelf
//
//  Created by Naidu on 18/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

let customFontViewHeight = CGFloat(438)

protocol FTInputCustomFontPickerDelegate: FTTraitCollectionOverridable {
    func didChange(_ picker : FTInputCustomFontViewController ,fontFamily family : String)
    func didChange(_ picker : FTInputCustomFontViewController ,fontFamilyWithStyle fontStyle : String)
    func didChange(_ picker : FTInputCustomFontViewController ,fontStyle style : FTFontStyle)
    func didChange(_ picker : FTInputCustomFontViewController ,fontSize size : CGFloat)
    func didChange(_ picker : FTInputCustomFontViewController ,fontColor color : UIColor)
    func didChangeFavoriteFont(_ picker : FTInputCustomFontViewController, font : FTCustomFontInfo)
    func didUpdateFavoriteFontList(_ picker : FTInputCustomFontViewController)
    func didClosePopOver(_ picker : FTInputCustomFontViewController)
    func willEditFavoriteFont(_ picker : FTInputCustomFontViewController)
    func willEditFavoriteColors(_ picker : FTInputCustomFontViewController)
    func didSetDefaultFont(_ picker : FTInputCustomFontViewController, font : FTCustomFontInfo)
}

extension FTInputCustomFontPickerDelegate {
    func didChange(_ picker : FTInputCustomFontViewController ,fontFamily family : String) { }
    func didChange(_ picker : FTInputCustomFontViewController ,fontFamilyWithStyle fontStyle : String) { }
    func didChange(_ picker : FTInputCustomFontViewController ,fontStyle style : FTFontStyle) { }
    func didChange(_ picker : FTInputCustomFontViewController ,fontSize size : CGFloat) { }
    func didChange(_ picker : FTInputCustomFontViewController ,fontColor color : UIColor) { }
    func didChangeFavoriteFont(_ picker : FTInputCustomFontViewController, font : FTCustomFontInfo) { }
    func didUpdateFavoriteFontList(_ picker : FTInputCustomFontViewController) { }
    func didClosePopOver(_ picker : FTInputCustomFontViewController) { }
    func willEditFavoriteFont(_ picker : FTInputCustomFontViewController) { }
    func willEditFavoriteColors(_ picker : FTInputCustomFontViewController) { }
    func didSetDefaultFont(_ picker : FTInputCustomFontViewController, font : FTCustomFontInfo){ }
}

class FTInputCustomFontViewController: UIViewController, FTCustomFontNameSelectionDelegate {
    
    var customFontManager : FTCustomFontManager!
    var timer: Timer?
    fileprivate weak var delegate : FTInputCustomFontPickerDelegate?;
    let customTransitioningDelegate = FTSlideInPresentationManager(mode: .topToBottom);
    var colorStringArray = [String]()
    var favorites : [FTCustomFontInfo]!
    var favoriteViewController: FTFavoriteFontStylesViewController?
    var keyboardHeight = 0.0
    var selectedIndexPath : IndexPath?
    fileprivate var isEditingFavorite = false
    fileprivate var currentPage = 0
    let maximumFavorites = 15
    fileprivate var tempCustomFontInfo = FTCustomFontManager().customFontInfo
    
    private var favoritePageKey = "IsShowingFavoritePenRack"
    
    @IBOutlet weak var displayNameView: UIView!
    @IBOutlet weak var fontDisplayNameLabel: UILabel?
    @IBOutlet weak var buttonFavorite: UIButton?
    @IBOutlet weak var favoriteContainerView: UIView!
    @IBOutlet weak var textStyleContainerView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var contentView:UIView!
    @IBOutlet weak var contentViewLeadingSpace:NSLayoutConstraint!
    
    @IBOutlet weak var fontNameButton:UIButton?
    @IBOutlet weak var fontSizeView:UIView!
    @IBOutlet weak var fontSizeButton:UIButton?
    
    @IBOutlet weak var fontSubTypeView:UIView?
    @IBOutlet weak var boldButton:UIButton?
    @IBOutlet weak var italicButton:UIButton?
    @IBOutlet weak var underlineButton:UIButton?
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    fileprivate var backgroundColors = [UIColor]();
    
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textStyleStackView: UIStackView!
    @IBOutlet weak var segmentTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contentCompactViewHeightConstraint: NSLayoutConstraint!
    
//    var colorPaletteController: FTColorsPaletteViewController!

    class func viewController(_ delegate : FTInputCustomFontPickerDelegate ,
                              fontManager : FTCustomFontManager) -> FTInputCustomFontViewController
    {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil);
        guard let controller = storyboard.instantiateViewController(withIdentifier: "FTInputCustomFontView") as? FTInputCustomFontViewController else {
            fatalError("Programmer error - could not find FTInputCustomFontViewController")
        }
        controller.delegate = delegate
        controller.customFontManager = fontManager
        controller.favorites = fontManager.defaultFavoriteFonts()

        var frame = controller.view.frame;
        frame.size.height = 351
        if delegate.ftOverrideTraitCollection(forWindow: nil)?.verticalSizeClass == .compact {
            frame.size.height = 150
        }
        if let safeAreaInsets = delegate.rootViewController()?.view.safeAreaInsets {
            frame.size.height += safeAreaInsets.bottom;
        }
        controller.view.frame = frame;

        controller.view.autoresizingMask = UIView.AutoresizingMask.init(rawValue: 0)
        return controller;
    }
    
    //MARK:- UIViewController
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.applyDisplaySettings()
        
        if let button = self.fontNameButton {
            let leftInset = button.frame.size.width - 40;
            button.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: leftInset , bottom: 0, right: 0)
        }
    }

    private var isRegular : Bool {
        return self.isRegularClass();
    }
    
    //TODO: As per Apple documentation, We should not override this variable, due to unavoidable circumstances for inputViewController and inputAccessoryViewController, as of now we cannot modify traitCollection, in future if you find any solution, DO NOT hesitate to remove below code
//    override var traitCollection: UITraitCollection {
//        return self.delegate?.ftOverrideTraitCollection(forWindow: nil) ?? super.traitCollection;
//    }
    
    //MARK:- Presentation
    class func showAsPopover(fromViewController viewController: UIViewController,
                             withSourceView sourceView: UIView,
                             withFontManager fontManager: FTCustomFontManager,
                             withDelegate delegate: FTInputCustomFontPickerDelegate?,
                             arrowDirection: UIPopoverArrowDirection) -> UIViewController {

        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil);
        guard let controller = storyboard.instantiateViewController(withIdentifier: "FTInputCustomFontView") as? FTInputCustomFontViewController else {
            fatalError("Programmer error - Could not find FTInputCustomFontViewController")
        }
        controller.delegate = delegate;
        controller.customFontManager = fontManager;
        controller.favorites = fontManager.defaultFavoriteFonts()
        if viewController.isRegularClass() {
            let navigationController = UINavigationController.init(rootViewController: controller)
            navigationController.isNavigationBarHidden = true
            navigationController.modalPresentationStyle = .popover;
            let popoverPresentationController = navigationController.popoverPresentationController;
            navigationController.preferredContentSize = CGSize.init(width: customFontViewWidth, height: customFontViewHeight)
            popoverPresentationController?.sourceView = sourceView;
           // popoverPresentationController?.overrideTraitCollection = viewController.traitCollection;
            popoverPresentationController?.sourceRect = sourceView.bounds
            popoverPresentationController?.delegate = controller
            popoverPresentationController?.backgroundColor = UIColor.bgColor;
            popoverPresentationController?.permittedArrowDirections = arrowDirection
            //popoverPresentationController?.overrideTraitCollection = viewController.traitCollection;
            viewController.present(navigationController, animated: true)
        }
        else{
            controller.modalPresentationStyle = .custom;
            let navigationController = UINavigationController.init(rootViewController: controller)
            navigationController.isNavigationBarHidden = true
            navigationController.preferredContentSize = viewController.view.window?.bounds.size ?? .zero
            viewController.present(navigationController, animated: true)
            
        }
        return controller;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isRegular {
            self.navigationController?.preferredContentSize = CGSize(width: 492, height: 438)
        }
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil);
        
        let textButtonTitle = NSLocalizedString("TextStyle", comment: "Text Style");
        self.segmentControl.setTitle(textButtonTitle, forSegmentAt: 0)
        self.segmentControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.appFont(for: .regular, with: 14)], for: UIControl.State.normal)
        self.updateFavoriteCount()
        self.addFavoriteController()
        self.addGesture()
        _ = self.loadDefaultBackgroundColors()
        self.applyFontChanges()
        
        if let button = self.fontNameButton {
            button.layer.cornerRadius = button.frame.size.height/2.0
        }
        track("textrack_opened", params: [:], screenName: FTScreenNames.textbox)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "kTextSelectionToColorsPaletteController", let controller = segue.destination as? FTColorsPaletteViewController {
//            self.colorPaletteController = controller
//            self.colorPaletteController.isTextMode = true
//            self.colorPaletteController.colors = self.customFontManager.getDefaultColors()
//            self.colorPaletteController.selectedColor = self.customFontManager.customFontInfo.textColor.hexStringFromColor()
//            self.colorPaletteController.delegate = self
//        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo : NSDictionary = notification.userInfo! as NSDictionary;
        let endFrame = (userInfo.object(forKey: UIResponder.keyboardFrameEndUserInfoKey) as AnyObject).cgRectValue!;
        keyboardHeight = Double(endFrame.size.height)
    }
    
    func addGesture() {
        let plusLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.plusMinusLongPressed(_:)))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.plusMinusLongPressed(_:)))
        self.minusButton.addGestureRecognizer(longPressGestureRecognizer)
        self.plusButton.addGestureRecognizer(plusLongPressGestureRecognizer)
    }
    
    func addFavoriteController() {
        favoriteViewController = FTFavoriteFontStylesViewController.init(nibName:
            "FTFavoriteFontStylesViewController", bundle: nil)
        favoriteViewController?.delegate=self
        favoriteViewController?.customFontManager = self.customFontManager
        
        self.favoriteContainerView.addSubview((favoriteViewController?.view)!)
        self.addChild(favoriteViewController!)
    }
    
    func applyDisplaySettings(){
        var isregular = false
        if self.isRegular {
            isregular = true
            self.contentViewHeightConstraint.constant = self.view.bounds.size.height
        } else {
            self.topViewHeightConstraint.constant = 0
            let safeAreaInsets = self.view.safeAreaInsets;
            self.contentCompactViewHeightConstraint.constant = self.view.bounds.size.height - safeAreaInsets.bottom
        }
        
        favoriteViewController?.view.frame = self.favoriteContainerView.bounds
        self.fontNameButton?.layer.borderColor=UIColor.thinBorderColor.cgColor
        self.fontNameButton?.layer.borderWidth=1.0
        
        self.fontSizeView.layer.borderColor=UIColor.thinBorderColor.cgColor
        self.fontSizeView.layer.borderWidth=1.0
        self.fontSizeView.layer.cornerRadius=self.fontSizeView.frame.size.height/2.0
        
        self.displayNameView.layer.cornerRadius = 4.0
        
        self.fontDisplayNameLabel?.numberOfLines = 0
        self.fontDisplayNameLabel?.adjustsFontSizeToFitWidth = true
        
        self.fontSubTypeView?.layer.borderColor=UIColor.thinBorderColor.cgColor
        self.fontSubTypeView?.layer.borderWidth=1.0
        if let subView = self.fontSubTypeView {
            subView.layer.cornerRadius=subView.frame.size.height/2.0
        }
        self.fontNameButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        
        self.view.layoutIfNeeded()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) { super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                applyFontChanges()
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func applyFontChanges(){
        self.fontNameButton?.setTitle(self.customFontManager.customFontInfo.displayName, for: UIControl.State.normal)
        self.fontNameButton?.titleLabel?.font=UIFont.init(name: self.customFontManager.customFontInfo.fontStyle, size: 15)
        self.fontSizeButton?.setTitle(String(format: "%.0fpt", self.customFontManager.customFontInfo.fontSize), for: UIControl.State.normal)
        self.fontDisplayNameLabel?.textColor = self.customFontManager.customFontInfo.textColor
        _ = UIFont.init(name: self.customFontManager.customFontInfo.fontStyle, size: self.customFontManager.customFontInfo.fontSize)

        self.fontDisplayNameLabel?.font = UIFont.init(name: self.customFontManager.customFontInfo.fontStyle, size: self.customFontManager.customFontInfo.fontSize)

        if self.customFontManager.customFontInfo.isUnderlined {
            self.fontDisplayNameLabel?.attributedText = NSAttributedString(string: NSLocalizedString("PreviewText", comment: "Preview Text"), attributes:[NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        } else {
            self.fontDisplayNameLabel?.attributedText = NSAttributedString(string: NSLocalizedString("PreviewText", comment: "Preview Text"), attributes:[NSAttributedString.Key.underlineStyle: 0])
        }

        self.boldButton?.alpha = self.customFontManager.customFontInfo.isBold ? 1.0 : 0.5
        self.italicButton?.alpha = self.customFontManager.customFontInfo.isItalic ? 1.0 : 0.5
        self.underlineButton?.alpha = self.customFontManager.customFontInfo.isUnderlined ? 1.0 : 0.5
        self.buttonFavorite?.isSelected = shouldBeSelected()
        
        self.perform(#selector(self.showLastSelectedColor), with: nil, afterDelay: 0.2)

    }
    
    func shouldBeSelected() -> Bool {
        let font = self.customFontManager.customFontInfo
        if self.favorites.contains(font!) {
            return true
        }
        return false
    }
    
    @objc func showLastSelectedColor() {
        if !self.colorStringArray.isEmpty, let colorString = self.customFontManager?.customFontInfo?.textColor.hexStringFromColor(), let index = self.colorStringArray.index(of: colorString) {
//                self.colorPaletteController.updateLastSelection(index: index)
            }
        }

    fileprivate func loadDefaultBackgroundColors() -> [String]
    {   self.backgroundColors.removeAll()
        colorStringArray = self.customFontManager.getDefaultColors()
        for eachColorInfo in colorStringArray {
            let hexString = eachColorInfo
            let color = UIColor.init(hexString: hexString);
            self.backgroundColors.append(color);
        }
        return colorStringArray
    }
    
    @objc fileprivate func plusMinusLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.view?.tag==1 {
            if gestureRecognizer.state == .began {
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector:#selector(increaseFontSize), userInfo: nil, repeats: true)
            } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
                timer?.invalidate()
                timer = nil
            }
        }
        else
        {
            if gestureRecognizer.state == .began {
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector:#selector(decreaseFontSize), userInfo: nil, repeats: true)
            } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
                timer?.invalidate()
                timer = nil
            }
        }
        
    }
    
    @objc func increaseFontSize() {
    self.customFontManager.customFontInfo.fontSize=(self.customFontManager.customFontInfo.fontSize) + 5
        self.applyFontChanges()
        self.delegate?.didChange(self, fontSize: self.customFontManager.customFontInfo.fontSize)
    }
    
    @objc func decreaseFontSize() {
    if(self.customFontManager.customFontInfo.fontSize <= 5) {
            timer?.invalidate()
            timer = nil
        } else {
            self.customFontManager.customFontInfo.fontSize = (self.customFontManager.customFontInfo.fontSize) - 5
            self.applyFontChanges()
            self.delegate?.didChange(self, fontSize: self.customFontManager.customFontInfo.fontSize)
        }
    }
    
    @IBAction func crossClicked(_ sender: Any) {
        self.resetCustomInfo()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func setAsDefaultTapped(_ sender: Any) {
        self.delegate?.didSetDefaultFont(self, font: self.customFontManager.customFontInfo)
        self.resetCustomInfo()
        let alertController = UIAlertController.init(title: "", message: NSLocalizedString("SetAsDefaultMessage", comment: "Default this for all future notebooks?"), preferredStyle: UIAlertController.Style.alert)
        
        let action = UIAlertAction.init(title: NSLocalizedString("No", comment: "No"), style: UIAlertAction.Style.cancel, handler: { (_) in
            track("textrack_setdefault_tapped", params:  ["choice" : "no"], screenName: FTScreenNames.textbox)
        })
        alertController.addAction(action)
        
        let action2 = UIAlertAction.init(title: NSLocalizedString("Yes", comment: "Yes"), style: UIAlertAction.Style.default, handler: { (_) in
            track("textrack_setdefault_tapped", params:  ["choice" : "yes"], screenName: FTScreenNames.textbox)

            var fontInfoDict : [String : String] = [:]
            
            fontInfoDict["fontName"] = self.customFontManager.customFontInfo.fontName
            fontInfoDict["fontStyle"] = self.customFontManager.customFontInfo.fontStyle
            fontInfoDict["fontSize"] = String(format: "%.0f", self.customFontManager.customFontInfo.fontSize)
            fontInfoDict["textColor"] = self.customFontManager.customFontInfo.textColor.hexStringFromColor()
            fontInfoDict["isUnderlined"] = self.customFontManager.customFontInfo.isUnderlined ? "1" : "0"
            
            FTUserDefaults.saveDefaultFontForAll(fontInfoDict)
            
        })
        alertController.addAction(action2)
        
        let controller = self.delegate?.rootViewController();
        if self.isRegular {
            self.dismiss(animated: true) {
                controller?.present(alertController, animated: true, completion: nil)
            }
        } else {
            controller?.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK: -SegmentControl
    @IBAction func favoriteClicked(_ sender: Any) {
        track("textrack_favbutton_tapped", params: [:], screenName: FTScreenNames.textbox)
        let font = self.customFontManager.customFontInfo

        if self.favorites.contains(font!) == true{
            if self.isRegular {
                self.flashTheSegmentControl(NSLocalizedString("Added!", comment: ""))
            }else{
                if let window = self.view.window, let visibleController = window.visibleViewController {
                    let toppadding = window.bounds.height - CGFloat(keyboardHeight + 30)
                    FTTooltipMessageViewController.shared.presentToastInViewConroller(visibleController, withMessage: NSLocalizedString("Already added!", comment: ""), topPadding: CGFloat(toppadding), andStyle: FTTooltipStyle.simpleMessage)
                }
            }
            return
        }
        else if self.favorites.count == maximumFavorites{
            if self.isRegular {
                self.flashTheSegmentControl(NSLocalizedString("FavoritesFull", comment: ""))
            }else{
                if let window = self.view.window, let visibleController = window.visibleViewController {
                    let toppadding = window.bounds.height - CGFloat(keyboardHeight + 30)
                    FTTooltipMessageViewController.shared.presentToastInViewConroller(visibleController, withMessage: NSLocalizedString("FavoritesFull", comment: ""), topPadding: CGFloat(toppadding), andStyle: FTTooltipStyle.simpleMessage)
                }
            }
            return
        }
        if self.isRegular {
            let snapshotView:UIView! = self.fontDisplayNameLabel!.snapshotView(afterScreenUpdates: true)
            let pointFrom = self.fontDisplayNameLabel?.convert(CGPoint.init(x: (self.fontDisplayNameLabel?.center.x)!, y: (self.fontDisplayNameLabel?.center.y)!), to: self.view)
            let pointTo = CGPoint.init(x: self.segmentControl.frame.maxX - 25 + (self.contentView.superview?.frame.origin.x)!, y: self.segmentControl.center.y + (self.contentView.superview?.frame.origin.y)!)
            
            self.view.addSubview(snapshotView)
            
            self.view.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.7, animations: {
                snapshotView.transform = CGAffineTransform.init(scaleX: 0.05, y: 0.05)
                self.animate(view: snapshotView, fromPoint: pointFrom!, toPoint: pointTo)
                snapshotView.alpha = 0.1
            }, completion: { (_) in
                snapshotView.layer.removeAllAnimations()
                snapshotView.removeFromSuperview()
                self.makeChangesForFavorite()
            })
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4, execute: { () -> Void in
                UIView.animate(withDuration: 0.1, animations: {
                    self.segmentControl.transform = CGAffineTransform.init(scaleX: 1.1, y: 1.1)
                    
                }, completion: { (_) in
                    UIView.animate(withDuration: 0.1, animations:{
                        self.segmentControl.transform = CGAffineTransform.identity
                    }, completion: { (_) in
                    })
                })
            })
        }else {
            self.makeChangesForFavorite()
        }
        
    }
    
    func makeChangesForFavorite() {
        self.buttonFavorite?.isSelected = true
        self.customFontManager.saveFontToFavorite()
        self.favorites = self.customFontManager.defaultFavoriteFonts()
        self.updateFavoriteCount()
        self.delegate?.didUpdateFavoriteFontList(self)
        self.view.isUserInteractionEnabled = true
    }
    
    func animate(view : UIView, fromPoint start : CGPoint, toPoint end: CGPoint)
    {
        let animation = CAKeyframeAnimation(keyPath: "position")
        let path = UIBezierPath()
        path.move(to: start)
        let c1 = CGPoint(x: start.x+100, y: (start.y-end.y)/2.0)
        let c2 = CGPoint(x: end.x, y: end.y)
        path.addCurve(to: end, controlPoint1: c1, controlPoint2: c2)
        animation.path = path.cgPath;
        
        animation.fillMode              = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animation.duration              = 0.6
        animation.timingFunction        = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        view.layer.add(animation, forKey:"trash")
    }
    
    func flashTheSegmentControl(_ message:String){
        self.segmentControl.setTitle(message, forSegmentAt: 1)
        self.segmentControl.layer.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint.init(x: self.segmentControl.center.x - 5.0, y: self.segmentControl.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint.init(x: self.segmentControl.center.x + 5.0, y: self.segmentControl.center.y))
        self.segmentControl.layer.add(animation, forKey: "position")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.3) {
            self.updateFavoriteCount()
        }
    }
    
    @IBAction func segmentSelected(_ sender: UISegmentedControl) {
        self.currentPage = self.segmentControl.selectedSegmentIndex
        self.isEditingFavorite = false
        if self.currentPage == 0 {
            self.hideFavoriteView(value: true)
        } else {
            favoriteViewController?.refreshFonts()
            self.hideFavoriteView(value: false)
        }
    }
    
    func hideFavoriteView(value: Bool) {
        self.favoriteContainerView.isHidden = value
        self.textStyleContainerView.isHidden = !value
    }
    
    func updateFavoriteCount(){
        var favoritesButtonTitle = NSLocalizedString("Favorites", comment: "Favorites");
        if(!self.favorites.isEmpty){
            favoritesButtonTitle = String.init(format: "%@ (%d)", favoritesButtonTitle,self.favorites.count);
        }
        self.segmentControl.setTitle(favoritesButtonTitle, forSegmentAt: 1)
    }
    
    @IBAction func didTaponFontSubType(_ sender:UIButton!) {
        if sender.tag == FTFontStyle.bold.rawValue {
            track("textrack_bold_tapped", params: [:], screenName: FTScreenNames.textbox)
            if self.canAddTrait(.traitBold) {
                self.customFontManager.customFontInfo.isBold = !self.customFontManager.customFontInfo.isBold
                self.delegate?.didChange(self, fontStyle: .bold)
            }else{
                self.customFontManager.customFontInfo.isBold = false
            }
        }
        else if sender.tag == FTFontStyle.italic.rawValue {
            track("textrack_italics_tapped", params: [:], screenName: FTScreenNames.textbox)
            if self.canAddTrait(.traitItalic) {
                self.customFontManager.customFontInfo.isItalic = !self.customFontManager.customFontInfo.isItalic
                self.delegate?.didChange(self, fontStyle: .italic)
            }else{
                self.customFontManager.customFontInfo.isItalic = false
            }
        }
        else if sender.tag == FTFontStyle.underline.rawValue {
            track("textrack_underline_tapped", params: [:], screenName: FTScreenNames.textbox)
            self.customFontManager.customFontInfo.isUnderlined = !self.customFontManager.customFontInfo.isUnderlined
            self.delegate?.didChange(self, fontStyle: .underline)
        }
            self.applyFontTrait()
            self.applyFontChanges()
        
    }
    
    func canAddTrait(_ trait : UIFontDescriptor.SymbolicTraits) -> Bool {
        let testFont = UIFont.init(name: self.customFontManager.customFontInfo.fontName, size: self.customFontManager.customFontInfo.fontSize)
        return testFont!.canAddTrait(trait)
    }
    
    func applyFontTrait() {
        var tempFont = UIFont.init(name: self.customFontManager.customFontInfo.fontStyle, size: self.customFontManager.customFontInfo.fontSize)
        if self.customFontManager.customFontInfo.isBold {
            tempFont = tempFont?.addTrait(.traitBold)
        }
        else{
            tempFont = tempFont?.removeTrait(.traitBold)
        }
        if self.customFontManager.customFontInfo.isItalic {
            tempFont = tempFont?.addTrait(.traitItalic)
        }else{
            tempFont = tempFont?.removeTrait(.traitItalic)
        }
        self.customFontManager.customFontInfo.fontStyle = (tempFont?.fontName)!
    }
    
    @IBAction func didTapOnFontSize(_ sender:UIButton!) {
        if sender.tag==1 {
            self.customFontManager.customFontInfo.fontSize = (self.customFontManager.customFontInfo.fontSize) + 1
        }
        else
        {
            if(self.customFontManager.customFontInfo.fontSize == 1) {
                return

            }
            self.customFontManager.customFontInfo.fontSize = (self.customFontManager.customFontInfo.fontSize) - 1
        }
        self.applyFontChanges()
        self.delegate?.didChange(self, fontSize: self.customFontManager.customFontInfo.fontSize)
    }
    
//***************************************************************
    @IBAction func didTapOnFontName(_ sender:UIButton!) {
        FTCLSLog("UI: Select Font");
        var shouldShowDefaultPicker: Bool = true
        #if targetEnvironment(macCatalyst)
            shouldShowDefaultPicker = false
        #endif

        if #available(iOS 13.0, *), shouldShowDefaultPicker {
            let fontPicker: FTFontPickerViewController = FTFontPickerViewController(nibName: "FTFontPickerViewController", bundle: Bundle(for: FTFontPickerViewController.self))
            fontPicker.delegate = self
            if self.isRegular {
                self.navigationController?.pushViewController(fontPicker, animated: true)
            }else {
                fontPicker.presentationController?.overrideTraitCollection = self.traitCollection
                self.present(fontPicker, animated: true, completion: nil)
            }
        } else {
            var fonts = [[[String : String]]]()
            fonts.append(self.customFontManager.recentFonts)
            fonts.append(UIFont.availableFontFamilyNames())
             // Fallback on earlier versions
            let fontPickController = FTCustomFontNameViewController.viewController(self, fontInfo: self.customFontManager.customFontInfo, withFonts: fonts)
            if self.isRegular {
                self.navigationController?.pushViewController(fontPickController, animated: true)
            }else {
                let navigationController = UINavigationController.init(rootViewController: fontPickController)
                navigationController.isNavigationBarHidden = true
                navigationController.preferredContentSize = self.view.window?.bounds.size ?? .zero
                navigationController.modalPresentationStyle = .overCurrentContext;
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: Font Name Selection Delegate
    func didFinish(_ viewController : FTCustomFontNameViewController,pickingFont fontInfo : [String : String]) -> FTCustomFontInfo {
        
        if(fontInfo["isStyle"] != nil) //Check if font style applied
        {
            self.customFontManager.customFontInfo.fontStyle = fontInfo["fontName"]!
            self.delegate?.didChange(self, fontFamilyWithStyle: self.customFontManager.customFontInfo.fontStyle)
        }
        else
        {
            self.customFontManager.customFontInfo.fontStyle = fontInfo["fontName"]!
            self.customFontManager.customFontInfo.fontName = fontInfo["fontName"]!
            self.customFontManager.customFontInfo.displayName = fontInfo["displayName"]!

            self.delegate?.didChange(self, fontFamily: self.customFontManager.customFontInfo.fontName)
        }
        
        self.applyFontChanges()
    self.customFontManager.insertLatestSelectedFont(["fontName":self.customFontManager.customFontInfo.fontName,"displayName":self.customFontManager.customFontInfo.displayName])
        return self.customFontManager.customFontInfo
    }

    func didTapOnFontPickerBackButton(_ viewController : FTCustomFontNameViewController){
        UIView.animate(withDuration: 0.3, animations: {
            var newFrame=viewController.view.frame;
            newFrame.origin.x=self.view.frame.size.width
            viewController.view.frame=newFrame
            self.contentViewLeadingSpace.constant = 0
            self.view.layoutIfNeeded()
        }) { (_) in
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
        self.customFontManager.replaceColors(self.colorStringArray)
    }
    
}

//MARK:- FTFavoriteFontStylesDelegate
extension FTInputCustomFontViewController : FTFavoriteFontStylesDelegate {
    func didChangeFavoriteCount(_viewController: FTFavoriteFontStylesViewController) {
        self.favorites = self.customFontManager.defaultFavoriteFonts()
        self.updateFavoriteCount()
        self.delegate?.didUpdateFavoriteFontList(self)
    }
    func didSelectFavoriteFont(_viewController: FTFavoriteFontStylesViewController, selectedFont: FTCustomFontInfo) {
        self.applyFontChanges()
        self.tempCustomFontInfo = self.customFontManager.customFontInfo
        self.customFontManager.customFontInfo = selectedFont
        self.delegate?.didChangeFavoriteFont(self, font: selectedFont)
        self.delegate?.didClosePopOver(self)
        self.delegate?.didUpdateFavoriteFontList(self)
        self.dismiss(animated: true, completion: nil)
    }
    func willEditFavoriteFonts(_viewController: FTFavoriteFontStylesViewController) {
        self.delegate?.willEditFavoriteFont(self)
    }
}

//MARK:- FTSystemFontPickerDelegate
extension FTInputCustomFontViewController : FTSystemFontPickerDelegate, UIFontPickerViewControllerDelegate {
   
    func didPickFontFromSystemFontPicker(_ viewController : FTFontPickerViewController?, selectedFontDescriptor: UIFontDescriptor) {
        // For font name, we need to take family attribute
        if let fontFamily = selectedFontDescriptor.object(forKey: .family) as? String, let displayName = selectedFontDescriptor.object(forKey: .visibleName) as? String {
            if let _ = selectedFontDescriptor.object(forKey: .face) as? String, let fontName = selectedFontDescriptor.object(forKey: .name) as? String {
                self.customFontManager.customFontInfo.fontStyle = fontName
                self.delegate?.didChange(self, fontFamilyWithStyle: self.customFontManager.customFontInfo.fontStyle)

            } else {
                self.customFontManager.customFontInfo.fontName = fontFamily
                self.customFontManager.customFontInfo.displayName = displayName
                self.delegate?.didChange(self, fontFamily: self.customFontManager.customFontInfo.fontName)
            }
            self.applyFontChanges()
            self.customFontManager.insertLatestSelectedFont(["fontName":self.customFontManager.customFontInfo.fontName,"displayName":self.customFontManager.customFontInfo.displayName])
        }
    }
    
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        self.didPickFontFromSystemFontPicker(nil, selectedFontDescriptor: descriptor)
    }
}

extension UIFont{
    class func availableFontFamilyNames() -> [[String : String]] {
        var fontNames : [[String : String]] = []
        var fontFamilyNames = UIFont.familyNames
        
        let notSupportedFontFmaily : [String] = ["Bangla Sangam MN","Telugu Sangam MN","Heiti TC","Heiti SC"];
        for eachFontName in notSupportedFontFmaily {
            let index = fontFamilyNames.index(of: eachFontName);
            if(nil != index) {
                fontFamilyNames.remove(at: index!);
            }
        }
        
        fontFamilyNames = fontFamilyNames.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
        fontFamilyNames.enumerated().forEach { (arg) in
            let (_, familyName) = arg
            fontNames.append(["displayName":familyName,"fontName":familyName])
        }
        return fontNames
    }
}

extension FTInputCustomFontViewController: UIPopoverPresentationControllerDelegate{
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController){
        self.delegate?.didClosePopOver(self)
    }

    func resetCustomInfo() {
        self.applyFontTrait()
        self.delegate?.didClosePopOver(self)
    }
}
