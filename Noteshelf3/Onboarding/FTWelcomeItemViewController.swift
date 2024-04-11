//
//  FTWelcomeItemViewController.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 11/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTWelcomeItemDelegate : NSObjectProtocol {
    func welcomeItem(_ item: FTWelcomeItemViewController,didTapOnItem item: FTGetStartedViewItems);
}

class FTWelcomeItemViewController: UIViewController {
    @IBOutlet weak var welcomeItemImageView: UIImageView?;
    @IBOutlet weak var welcomeItemLabel: UILabel?;
    @IBOutlet weak var welcomeItemContentView: UIView?;
    
    @IBOutlet weak var contentView: UIView?;

    weak var delegate: FTWelcomeItemDelegate?;
    
    private var welcomeItem: FTGetStartedViewItems?;
    
    static func welcomeItemComtroller(_ type: FTGetStartedViewItems) -> FTWelcomeItemViewController {
        let storyboard = UIStoryboard(name: "FTWelcome", bundle: nil);
        guard let controller = storyboard.instantiateViewController(withIdentifier: "FTWelcomeItemViewController") as? FTWelcomeItemViewController else {
            fatalError("ID missing");
        }
        controller.setWelcomeitem(type)
        return controller;
    }
    
    func setWelcomeitem(_ item: FTGetStartedViewItems) {
        self.welcomeItem = item;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let _welcomeItem = self.welcomeItem else {
            return
        }
        self.welcomeItemImageView?.image = UIImage(named: _welcomeItem.imageName)
        self.welcomeItemLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium);
        self.welcomeItemLabel?.text = _welcomeItem.displayTitle;
    }
    
    @IBAction func didTapOnButtonAction(_ button: UIButton) {
        UIView.animate(withDuration: AnimationValue.animatedValue, animations: {
            self.contentView?.transform = .identity
        }) { _ in
            self.delegate?.welcomeItem(self, didTapOnItem: self.welcomeItem!)
        }
    }
    
    @IBAction func didBeganTapOnButtonAction(_ button: UIButton) {
        UIView.animate(withDuration: AnimationValue.animatedValue, animations: {
            self.contentView?.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        })
    }
    
    @IBAction func didEndTapOnButtonOutsideAction(_ button: UIButton) {
        UIView.animate(withDuration: AnimationValue.animatedValue, animations: {
            self.contentView?.transform = .identity
        })
    }
}

extension FTGetStartedViewItems {
    func contentSize(_ maxItemSize: CGFloat) -> CGSize {
        guard let image = UIImage(named: self.imageName) else {
            return .zero;
        }

        let aspectRatio = image.size.width/image.size.height;
        let requiredSizeWidth = maxItemSize * aspectRatio;
        
        return CGSize(width: requiredSizeWidth, height: maxItemSize);
    }
}
