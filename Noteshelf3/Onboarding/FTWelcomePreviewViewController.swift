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
        self.contentView?.layer.cornerRadius = 32;
        self.contentView?.layer.shadowOffset = CGSize(width: 0, height: 50)
        self.contentView?.layer.shadowRadius = 50;
        self.contentView?.layer.shadowOpacity = 0.4;
        self.contentView?.layer.shadowColor = UIColor.appColor(.welcomeBtnColor).cgColor
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
//        if let leftconstraint = self.contentConstraintLeft, let topconstraint =  self.contentConstraintTop {
//            leftconstraint.constant = (self.view.frame.width - (self.contentConstraintWidth?.constant ?? 0))*0.5;
//            topconstraint.constant = (self.view.frame.height - (self.contentConstraintHeight?.constant ?? 0))*0.5;
//        }
    }
    
    func showPreview(from sourceRect: CGRect,itemSize: CGFloat) {
        guard let item = self.welcomeItem else {
            return;
        }
        let contentSize = item.contentSize(itemSize)
        self.contentInfoLabel?.text = item.displayTitle;

        self.contentConstraintWidth?.constant = sourceRect.width;
        self.contentConstraintHeight?.constant = sourceRect.height;
        self.contentConstraintLeft?.constant = sourceRect.origin.x;
        self.contentConstraintTop?.constant = sourceRect.origin.y;
        
        self.containerConstraintWidth?.constant = sourceRect.width;
        self.containerConstraintHeight?.constant = sourceRect.height;

        let width = min(394, self.view.frame.width);
        let height = contentSize.height + 32 + 12 + 4

        self.contentInfoConstraintWidth?.constant = width
        self.view.layoutIfNeeded();
        
        
        var endRect = CGRect(origin: .zero, size: CGSize(width: width, height: height));
        endRect.origin.x = (self.view.frame.width - endRect.width)*0.5;
        endRect.origin.y = (self.view.frame.height - endRect.height)*0.5;

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.contentConstraintWidth?.constant = endRect.width;
            self.contentConstraintHeight?.constant = endRect.height;
            self.contentConstraintLeft?.constant = endRect.origin.x;
            self.contentConstraintTop?.constant = endRect.origin.y;

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
    
    func dismissPreivew(to sourceRect: CGRect,itemSize: CGFloat,onCompletion: (()->())?) {
        var frame = self.contentInfoLabel?.frame ?? .zero;
        frame.size.width = sourceRect.width

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.contentConstraintWidth?.constant = sourceRect.width;
            self.contentConstraintHeight?.constant = sourceRect.height;
            self.contentConstraintLeft?.constant = sourceRect.origin.x;
            self.contentConstraintTop?.constant = sourceRect.origin.y;
            self.view.layoutIfNeeded();
        } completion: { _ in
            onCompletion?();
        }
    }
    
    @objc @IBAction func didTap(_ tapgesture: UITapGestureRecognizer) {
        self.delegate?.welcomePreviewDidClose(self);
    }
}
