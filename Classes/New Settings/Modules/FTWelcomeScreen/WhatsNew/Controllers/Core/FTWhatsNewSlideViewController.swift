//
//  FTWhatsNewSlideViewController.swift
//  Noteshelf
//
//  Created by Siva on 13/11/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTWhatsNewSlideViewControllerDelegate: AnyObject {
    func whatsNewSlideViewControllerDidClickNext(whatsNewSlideViewController: FTWhatsNewSlideViewController);
    func close()
    func learnMoreTapped(whatsNewSlideViewController: FTWhatsNewSlideViewController)
}

@objc class FTWhatsNewSlideViewController: UIViewController {
    @IBOutlet weak var helpTitle: FTStyledLabel?
    @IBOutlet weak var helpMessage: FTStyledLabel?
    @IBOutlet weak var learnMoreBtn: UIButton?

    @IBOutlet weak var actionButton1: FTWhatsNewButton?
    @IBOutlet weak var actionButton2: FTWhatsNewButton?
    @IBOutlet weak var animationHolderView: UIView!
    var duration: TimeInterval = 0.5
    
    var animationView: UIView?
    fileprivate var repeatCount = 0

    var clipartTimer: Timer?
    var closeButtonImage: UIImage = UIImage(named: "whatsNewClose")!
    weak var delegate: FTWhatsNewSlideViewControllerDelegate!
    
    var pageControlTintColor: UIColor {
        return UIColor.label.withAlphaComponent(0.2);
    }

    var pageControlCurrentPageTintColor: UIColor {
        return UIColor.label;
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.helpTitle?.textColor = UIColor.label
        self.helpMessage?.textColor = UIColor.label
    }

    deinit {
        #if DEBUG
                debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    @objc func learnMoreBtnAction(_ button: UIButton) {
        self.delegate.learnMoreTapped(whatsNewSlideViewController: self)
    }

    // MARK: - Custom
    func attributedMessageText(forMessage message: String, withLineHeight lineHeight: CGFloat = 26) -> NSAttributedString {
        let attributedSubTitle = NSMutableAttributedString(string: message);

        let paragraphStyle = NSMutableParagraphStyle();
        paragraphStyle.minimumLineHeight = lineHeight;
        paragraphStyle.maximumLineHeight = lineHeight;
        paragraphStyle.alignment = .center;
        attributedSubTitle.setAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributedSubTitle.length));

        return attributedSubTitle;
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
    }
    
    func stopAnimation() {
        self.repeatCount = 0
//        animationView?.stop()
    }
    
    func pauseAnimation() {
//        animationView?.pause()
    }
    
    func playAnimation() {
        
    }
}

extension FTWhatsNewSlideViewController {
    func addImageToLayer(name: String, imageName: String) -> UIImageView? {
        guard let image = UIImage(named: imageName),
            !imageName.isEmpty,
            animationHolderView != nil else {
                return nil
        }

        let imageView = UIImageView(image: image);
        return imageView
    }

    // repeatCount -ve indicates infinite times
    internal func playAnimationIntermal(from: CGFloat = 0.0, to: CGFloat = 1.0, repeatCount: Int = 1, completion: (() -> Void )? = nil ) {
        self.repeatCount = repeatCount
        completion?()
    }
}

extension FTWhatsNewSlideViewController {
    func logEvent(for name: String) {
        track("Whats New", params: ["Screen": name]);
    }

    func setInitialPositions() {
        let verticalOffset = CGAffineTransform(translationX: 0, y: 60)
        self.helpTitle?.alpha = 0.0
        self.helpMessage?.alpha = 0.0
        self.learnMoreBtn?.alpha = 0.0
        
        self.helpTitle?.transform = verticalOffset
        self.helpMessage?.transform = verticalOffset
        self.learnMoreBtn?.transform = verticalOffset
    }
    
    func showSlideUpAnimation() {
        UIView.animate(withDuration: 0.6,
                       delay: 0.2,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.helpTitle?.transform = .identity
                        self.helpTitle?.alpha = 1.0
        })
        UIView.animate(withDuration: 0.6,
                       delay: 0.2,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.helpMessage?.transform = .identity
                        self.helpMessage?.alpha = 1.0
        })
        UIView.animate(withDuration: 0.6,
                       delay: 0.2,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.learnMoreBtn?.transform = .identity
                        self.learnMoreBtn?.alpha = 1.0
        })

    }
}
