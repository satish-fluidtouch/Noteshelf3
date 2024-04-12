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
    
    private var welcomeItem: FTGetStartedViewItems?;
    private weak var embedController: FTWelcomeItemViewController?;

    @IBOutlet weak var containerView: UIView?;
    @IBOutlet weak var contentView: UIView?;
    @IBOutlet weak var contentInfoLabel: UILabel?;
                
    @IBOutlet weak var contentConstraintWidth: NSLayoutConstraint?;
    @IBOutlet weak var contentConstraintHeight: NSLayoutConstraint?;
    @IBOutlet weak var contentConstraintTop: NSLayoutConstraint?;
    @IBOutlet weak var contentConstraintLeft: NSLayoutConstraint?;

    @IBOutlet weak var contentInfoConstraintWidth: NSLayoutConstraint?;

    @IBOutlet weak var containerConstraintWidth: NSLayoutConstraint?;
    @IBOutlet weak var containerConstraintHeight: NSLayoutConstraint?;
    
    weak var delegate: FTWelcomePreviewDelegate?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentView?.addShadow(CGSize(width: 0, height: 50), color: UIColor.appColor(.welcomeBtnColor), opacity: 0.4, radius: 50)
        self.contentView?.layer.cornerRadius = 32;
        self.contentInfoLabel?.text = self.welcomeItem?.itemDescription;
    }
        
    func showPreview(from sourceRect: CGRect,itemSize: CGFloat) {
        let contentSize = self.requiredContentSize(itemSize: itemSize)
        self.setContentViewFrame(sourceRect)
        self.containerConstraintWidth?.constant = sourceRect.width;
        self.containerConstraintHeight?.constant = sourceRect.height;
        self.contentInfoConstraintWidth?.constant = contentSize.width
        self.view.layoutIfNeeded();
        
        var endRect = CGRect(origin: .zero, size: contentSize);
        endRect.origin.x = (self.view.frame.width - endRect.width)*0.5;
        endRect.origin.y = (self.view.frame.height - endRect.height)*0.5;

        self.view.backgroundColor = self.bgColor(true, isPresenting: true)
        
        let duration = self.duration(from: sourceRect.origin, to: endRect.origin);
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: [.curveEaseOut]) {
            self.setContentViewFrame(endRect)
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.contentConstraintLeft?.constant = (self.view.frame.width - (self.contentConstraintWidth?.constant ?? 0))*0.5;
            self.contentConstraintTop?.constant = (self.view.frame.height - (self.contentConstraintHeight?.constant ?? 0))*0.5;
        } completion: { _ in
            
        }

    }
    func dismissPreivew(to sourceRect: CGRect,itemSize: CGFloat,onCompletion: (()->())?) {
        self.view.backgroundColor = self.bgColor(true, isPresenting: false)
        let duration = self.duration(from: sourceRect.origin, to: self.contentView?.frame.origin ?? .zero);
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
            self.setContentViewFrame(sourceRect)
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
    
    func bgColor(_ initialState: Bool, isPresenting: Bool) -> UIColor {
        let color1 = UIColor.clear;
        let color2 = UIColor.black.withAlphaComponent(0.2);
        if initialState {
            return isPresenting ? color1 : color2
        }
        return isPresenting ? color2 : color1;
    }
    
    func requiredContentSize(itemSize: CGFloat) -> CGSize {
        let width = min(394, self.view.frame.width);
        guard let item = self.welcomeItem else {
            return CGSize(width: width, height: 225);
        }
        let contentSize = item.contentSize(itemSize)
        let height = contentSize.height + 32 + 12 + 4
        return CGSize(width: width, height: height);
    }
}
