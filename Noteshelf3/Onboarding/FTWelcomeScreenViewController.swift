//
//  FTWelcomeScreenViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 08/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWelcomeScreenViewController: UIViewController {
    private weak var previewController: FTWelcomePreviewViewController?
    @IBOutlet weak var titleLable: UILabel?;
    @IBOutlet weak var dismissButton: UIButton?;
    @IBOutlet weak var subTitle: UILabel?;
    @IBOutlet private weak var topHeaderView: UIStackView?;

    private weak var selectedSlide: FTWelcomeItemViewController?;
    @IBOutlet private weak var headerConstraintTop: NSLayoutConstraint?;
    @IBOutlet private weak var footerConstraintBottom: NSLayoutConstraint?;
    @IBOutlet private weak var contentViewConstraintTop: NSLayoutConstraint?;

    @IBOutlet private weak var contentView: UIView?;

    @IBOutlet private weak var contentHeightConstraint: NSLayoutConstraint?;

    @IBOutlet private weak var scrollView1: UIScrollView?;
    @IBOutlet private weak var scrollView2: UIScrollView?;
    
    private var onDismissBlock: (() -> Void)?
    
    private var model = FTGetStartedItemViewModel();
    class func showWelcome(presenterController: UIViewController, onDismiss : (() -> Void)?) {
        let story = UIStoryboard(name: "FTWelcome", bundle: nil)
        let welcomeController = story.instantiateViewController(withIdentifier: "FTWelcomeScreenViewController") as! FTWelcomeScreenViewController
        welcomeController.onDismissBlock = onDismiss;
        welcomeController.modalPresentationStyle = .overFullScreen;
        welcomeController.modalTransitionStyle = .crossDissolve;
        presenterController.present(welcomeController, animated: true, completion: nil)
    }
    
    private var fontSize: CGFloat {
        return UIDevice.current.isPhone() ? 36 : 52
    }
    
    private var itemSize: CGFloat {
        return (UIDevice.current.isPhone() ? 144 : 180)
    }
    
    override func updateViewConstraints() {
        let viewHeight = self.view.frame.size.height;
        
        let contentHeight = 2 * itemSize + 16 + (self.dismissButton?.frame.height ?? 0) + (self.topHeaderView?.frame.height ?? 0);
        let remainingHeight = (viewHeight - contentHeight) / 4;
               
        self.contentHeightConstraint?.constant = 2 * itemSize + 16;
        self.headerConstraintTop?.constant = remainingHeight;
        self.footerConstraintBottom?.constant = remainingHeight;
        self.contentViewConstraintTop?.constant = remainingHeight;
        super.updateViewConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                         
        self.contentView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.dismissButton?.addShadow(CGSize(width: 0, height: 12), color: UIColor.appColor(.welcomeBtnColor), opacity: 0.24, radius: 16.0)
        self.contentView?.addShadow(CGSize(width: 0, height: 30), color: UIColor.appColor(.welcomeBtnColor), opacity: 0.12, radius: 30)

        self.titleLable?.font = UIFont.clearFaceFont(for: .regular, with: fontSize)
        self.titleLable?.text = self.model.headerTopTitle
        
        let attributedTet = NSMutableAttributedString(string: self.model.headerbottomfirstTitle, attributes: [.font : UIFont.clearFaceFont(for: .regular, with: fontSize)])
        let secondSet = NSAttributedString(string: self.model.headerbottomsecondTitle, attributes: [.font: UIFont.clearFaceFont(for: .regularItalic, with: fontSize)])
        attributedTet.append(secondSet)
        self.subTitle?.attributedText = attributedTet;
        
        self.dismissButton?.setAttributedTitle(NSAttributedString(string: model.btntitle, attributes: [
            .font : UIFont.clearFaceFont(for: .medium, with: 20)
            , .foregroundColor : UIColor.white
        ]), for: .normal);
        self.dismissButton?.backgroundColor = UIColor.appColor(.welcomeBtnColor)
        self.dismissButton?.layer.cornerRadius = 16;
        
        self.view.layoutIfNeeded();
        self.view.setNeedsUpdateConstraints();
        self.view.updateConstraintsIfNeeded()

        var itemsToLoad = [FTGetStartedViewItems]();
        itemsToLoad.append(contentsOf: model.getstartedList);
        itemsToLoad.append(contentsOf: model.getstartedList);
//        itemsToLoad.append(contentsOf: model.getstartedList);
        
        self.loadGrids(itemsToLoad, contentView: self.scrollView1!)
        self.loadGrids(itemsToLoad, contentView: self.scrollView2!)
        
        var offset = self.scrollView2?.contentOffset ?? .zero;
        offset.x = self.scrollView2!.contentSize.width - self.scrollView2!.frame.width
        self.scrollView2?.contentOffset = offset;
        self.startAnimation();
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator);
        let isPaused = self.displayLink.isPaused;
        self.stopAnimation()
        coordinator.animate { context in
            self.view.setNeedsUpdateConstraints();
            self.view.updateConstraintsIfNeeded();
            self.view.layoutIfNeeded()
            self.previewController?.updateViewConstraintsOntransition()
        } completion: { _ in
            if !isPaused {
                self.startAnimation()
            }
        }
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sceneDidEnterForeground(_:)), name: UIApplication.sceneWillEnterForeground, object: self.sceneToObserve)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sceneWillEnterBackground(_:)), name: UIApplication.sceneDidEnterBackground, object: self.sceneToObserve)
    }
    
    @objc private func sceneDidEnterForeground(_ notification: Notification) {
        if nil == self.selectedSlide {
            self.displayLink.isPaused = false
        }
    }
    
    @objc private func sceneWillEnterBackground(_ notification: Notification) {
        self.displayLink.isPaused = true
    }
    
    @IBAction func didTapOnDismiss(_ sender: UIButton?) {
        self.dismiss(animated: true) {
            self.displayLink.invalidate();
            self.onDismissBlock?();
            self.onDismissBlock = nil
        }
    }
                
    private lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(self.updateContent(_:)));
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 40);
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.default);

        return displayLink;
    }();
    
    private func startAnimation() {
        self.displayLink.isPaused = false
    }
    
    private func stopAnimation() {
        self.displayLink.isPaused = true
    }
    
    @objc private func updateContent(_ displayLInk: CADisplayLink) {
        guard let _scrollview1 = self.scrollView1, let _scrollview2 = self.scrollView2 else {
            return;
        }
        
        var offset = _scrollview1.contentOffset;
        offset.x += 1;
        if offset.x > _scrollview1.contentSize.width - _scrollview1.frame.width {
            offset.x = 0;
        }
        _scrollview1.contentOffset = offset;
        
        var offset1 = _scrollview2.contentOffset;
        offset1.x -= 1;
        if offset1.x < 0 {
            offset1.x = _scrollview2.contentSize.width - _scrollview2.frame.width;
        }
        offset1.x = max(offset1.x,0)
        _scrollview2.contentOffset = offset1;
    }
        
    private  func loadGrids( _ items: [FTGetStartedViewItems], contentView: UIScrollView) {
        var previousFrame = CGPoint.zero;
        items.forEach { eachItem in
            let item = FTWelcomeItemViewController.welcomeItemComtroller(eachItem)
            item.delegate = self;
            var frame = item.view.frame
            frame.origin = CGPoint(x:previousFrame.x,y:0);
            frame.size = eachItem.contentSize(self.itemSize)
            item.view.frame = frame
            
            self.addChild(item);
            contentView.addSubview(item.view);
            previousFrame.x = frame.maxX + 16;
        }
        contentView.contentSize = CGSize(width: previousFrame.x - 16, height: contentView.frame.height)
    }
}

class GradientView: UIView {
    @IBInspectable var gradientColors: [UIColor] = [UIColor.appColor(.welcometopGradiantColor)
                                                    , UIColor.appColor(.welcomeBottonGradiantColor)]
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Create a CGContext
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Create a gradient with the colors array
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors.map { $0.cgColor } as CFArray, locations: nil)
        
        // Draw the gradient
        context.drawLinearGradient(gradient!,
                                    start: CGPoint(x: 0, y: 0),
                                    end: CGPoint(x: bounds.width, y: bounds.height),
                                    options: [])
    }
}

extension FTWelcomeScreenViewController: FTWelcomePreviewDelegate {
    func welcomePreviewDidClose(_ preview: FTWelcomePreviewViewController) {
        guard let slide = self.selectedSlide else {
            return;
        }
        let frame = self.frame(for: slide)
        preview.dismissPreivew(to: frame,itemSize: self.itemSize) {
            preview.removeFromParent()
            preview.view.removeFromSuperview();
            self.selectedSlide?.setAsPreviewed(false)
            self.selectedSlide = nil;
            self.previewController = nil;
            self.startAnimation();
        }
    }
}

extension FTWelcomeScreenViewController: FTWelcomeItemDelegate {
    func welcomeItem(_ controller: FTWelcomeItemViewController, didTapOnItem item: FTGetStartedViewItems) {
        let previewController = FTWelcomePreviewViewController.welcomeItemComtroller(item);
        previewController.referenceContentView = self.contentView;
        
        let frame = self.frame(for: controller)
        previewController.delegate = self;
        self.addChild(previewController);
        previewController.view.frame = self.view.bounds
        previewController.view.addFullConstraints(self.view);
        selectedSlide = controller;
        self.previewController = previewController;
        
        controller.setAsPreviewed(true)
        
        previewController.showPreview(from: frame,itemSize: self.itemSize)
        self.stopAnimation();
    }
}


private extension FTWelcomeScreenViewController {
    func frame(for controller: FTWelcomeItemViewController) -> CGRect {
        var frame = controller.view.frame;
        if let scrollView = controller.view.superview as? UIScrollView {
            let offset = scrollView.contentOffset;
            frame.origin.x -= offset.x;
            frame.origin.y -= offset.y;
            frame.origin.y += scrollView.frame.origin.y;
            frame.origin.y += (scrollView.superview?.frame.origin.y ?? 0);
        }
        return frame;
    }
}

extension UIView {
    func addShadow(_ offset: CGSize, color: UIColor, opacity: Float = 1.0,radius: CGFloat) {
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.shadowColor = color.cgColor
    }
}
