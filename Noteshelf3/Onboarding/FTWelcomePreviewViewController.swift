//
//  FTWelcomePreviewViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTWelcomePreviewDelegate: NSObjectProtocol {
    func welcomePreviewDidClose(_ preview: FTWelcomePreviewViewController);
}

class FTWelcomePreviewViewController: UIViewController {

    static func welcomeItemComtroller(_ type: FTGetStartedViewItems) -> FTWelcomePreviewViewController {
        let storyboard = UIStoryboard(name: "FTWelcome", bundle: nil);
        guard let controller = storyboard.instantiateViewController(withIdentifier: "FTWelcomePreviewViewController") as? FTWelcomePreviewViewController else {
            fatalError("ID missing");
        }
        controller.welcomeItem = type;
        return controller;
    }
    
    weak var referenceContentView: UIView?;
    
    private var welcomeItem: FTGetStartedViewItems?;
    private weak var embedController: FTWelcomeItemViewController?;

    @IBOutlet weak var containerView: UIView?;
    @IBOutlet weak var contentView: UIView?;
                
    @IBOutlet weak var contentConstraintWidth: NSLayoutConstraint?;
    @IBOutlet weak var contentConstraintHeight: NSLayoutConstraint?;
    @IBOutlet weak var contentConstraintTop: NSLayoutConstraint?;
    @IBOutlet weak var contentConstraintLeft: NSLayoutConstraint?;

    @IBOutlet weak var containerConstraintWidth: NSLayoutConstraint?;
    @IBOutlet weak var containerConstraintHeight: NSLayoutConstraint?;
    @IBOutlet weak var containerConstraintLeft: NSLayoutConstraint?;
    @IBOutlet weak var containerConstraintTop: NSLayoutConstraint?;
    
    @IBOutlet weak var previewImageView: UIImageView?;
    @IBOutlet weak var previewTitleLabel: UILabel?;
    @IBOutlet weak var previewDescriptionLabel: UILabel?;
    @IBOutlet weak var previewContentView: UIView?;
    
    @IBOutlet weak var previewDescriptionLabelWidthConstraint: NSLayoutConstraint?;
    
    weak var delegate: FTWelcomePreviewDelegate?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previewDescriptionLabelWidthConstraint?.constant = self.requiredContentSize().width - 40;
        self.contentView?.addShadow(CGSize(width: 0, height: 50), color: UIColor.appColor(.welcomeBtnColor), opacity: 0.4, radius: 50)
        self.previewContentView?.layer.cornerRadius = 32;
        self.contentView?.layer.cornerRadius = 32;
        
        self.previewTitleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium);
        self.previewDescriptionLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular);

        if let item = self.welcomeItem {
            self.previewImageView?.image = UIImage(named: item.previewImageName);
            self.previewTitleLabel?.text = item.displayTitle;
            self.previewDescriptionLabel?.text = item.itemDescription;
        }
    }
        
    func showPreview(from sourceRect: CGRect,itemSize: CGFloat) {
        let contentSize = self.requiredContentSize()
        self.setContentViewFrame(sourceRect)
        self.setContainerViewFrame(sourceRect);
        
        self.view.layoutIfNeeded();
        
        let endRect = self.centeredRect(CGRect(origin: .zero, size: contentSize));
        let centeredSourceRect = self.centeredRect(sourceRect);

        self.view.backgroundColor = self.bgColor(true, isPresenting: true)
        
        self.containerView?.alpha = 1.0;
        self.contentView?.alpha = 0.0;
        
        let duration = self.duration(from: sourceRect.origin, to: endRect.origin);

        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: [.curveEaseOut]) {
            self.setContentViewFrame(endRect)
            self.containerConstraintLeft?.constant = centeredSourceRect.minX;
            self.containerConstraintTop?.constant = centeredSourceRect.minY;

            self.containerView?.alpha = 0.0;
            self.contentView?.alpha = 1.0;
            
            self.view.backgroundColor = self.bgColor(false, isPresenting: true)
            self.view.layoutIfNeeded();
        } completion: { _ in
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedWelcomeItem" {
            self.embedController = segue.destination as? FTWelcomeItemViewController;
            if let item = self.welcomeItem {
                self.embedController?.setWelcomeitem(item);
            }
        }
    }
    
    func updateViewConstraintsOntransition() {
        let contentSize = self.requiredContentSize()
        let centeredRect = self.centeredRect(CGRect(origin: .zero, size: contentSize))
        self.contentConstraintLeft?.constant = centeredRect.minX;
        self.contentConstraintTop?.constant = centeredRect.minY;
        self.contentConstraintWidth?.constant = contentSize.width
        self.contentConstraintHeight?.constant = contentSize.height
        self.previewDescriptionLabelWidthConstraint?.constant = contentSize.width - 40;
    }
    
    func dismissPreivew(to sourceRect: CGRect,itemSize: CGFloat,onCompletion: (()->())?) {
        self.view.backgroundColor = self.bgColor(true, isPresenting: false)
        
        self.containerView?.alpha = 0.0;
        self.contentView?.alpha = 1.0;

        let duration = self.duration(from: sourceRect.origin, to: self.contentView?.frame.origin ?? .zero);
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
            self.setContentViewFrame(sourceRect)
            self.setContainerViewFrame(sourceRect);

            self.containerView?.alpha = 1.0;
            self.contentView?.alpha = 0.0;

            self.view.backgroundColor = self.bgColor(false, isPresenting: false)
            self.view.layoutIfNeeded();
        } completion: { _ in
            onCompletion?();
        }
    }
    
    @objc @IBAction func didTap(_ tapgesture: UITapGestureRecognizer) {
        self.delegate?.welcomePreviewDidClose(self);
    }
}

private extension FTWelcomePreviewViewController {
    func duration(from :CGPoint, to :CGPoint) -> TimeInterval {
        let maxDistance = distanceBetweenPoints2(to, CGPoint(x: self.view.frame.width, y: self.view.frame.midY));
        let distanceToCover = distanceBetweenPoints2(from, to);
        let duration = max(min(0.3,(distanceToCover * 0.3) / maxDistance),0.1)
        return TimeInterval(duration);
    }
    
    func setContentViewFrame(_ frame: CGRect) {
        self.contentConstraintWidth?.constant = frame.width;
        self.contentConstraintHeight?.constant = frame.height;
        self.contentConstraintLeft?.constant = frame.origin.x;
        self.contentConstraintTop?.constant = frame.origin.y;
    }
    
    func setContainerViewFrame(_ frame: CGRect) {
        self.containerConstraintWidth?.constant = frame.width;
        self.containerConstraintHeight?.constant = frame.height;
        self.containerConstraintLeft?.constant = frame.origin.x;
        self.containerConstraintTop?.constant = frame.origin.y;
    }

    func bgColor(_ initialState: Bool, isPresenting: Bool) -> UIColor {
        let color1 = UIColor.clear;
        let color2 = UIColor.black.withAlphaComponent(0.2);
        if initialState {
            return isPresenting ? color1 : color2
        }
        return isPresenting ? color2 : color1;
    }
    
    func requiredContentSize() -> CGSize {
        let width = min(394, self.view.frame.width);
        return CGSize(width: width, height: 225);
    }
    
    func centeredRect(_ rect:CGRect) -> CGRect {
        let referenceCenter = self.referenceContentView?.center ?? self.view.center;
        var returnRect = rect;
        returnRect.origin.x = referenceCenter.x - returnRect.width*0.5;
        returnRect.origin.y = referenceCenter.y - returnRect.height*0.5;
        return returnRect;
    }
}
