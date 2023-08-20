//
//  FTTemplateImageView.swift
//  FTTemplatesStore
//
//  Created by Siva on 18/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Combine
class FTTemplateImageView: UIImageView {
    private var cancellabelAction: AnyCancellable?;
    var template: TemplateInfo!
    var premiumView: UIImageView?

     override init(frame: CGRect) {
        super.init(frame: frame)
        // Custom initialization code
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Custom initialization code
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.isRegular {
            premiumView?.isHidden = true
        } else {
            premiumView?.isHidden = false
        }
    }

    func configureImageViewWith(template: TemplateInfo) {
        self.template = template
        showPremiumIconIfNeeded()
        addObserver()
    }
    
    private func showPremiumIconIfNeeded() {
        if template.type == FTDiscoveryItemType.diary.rawValue
            , let premiumUser = FTStoreContainerHandler.shared.premiumUser
            , !premiumUser.isPremiumUser {
            // Add Premium Icon
            let premiumView = UIImageView(frame: CGRect(x: 0 , y: 8, width: self.frame.size.width , height: 20))
            premiumView.image = UIImage(named: "premium", in: storeBundle, with: nil)
            premiumView.contentMode = .scaleAspectFit
            premiumView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(premiumView)
            premiumView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            premiumView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
            if self.traitCollection.isRegular {
                premiumView.isHidden = true
            } else {
                premiumView.isHidden = false
            }

            self.premiumView = premiumView
        }

    }

    private func addObserver() {
        if nil == cancellabelAction
            , let premiumUser = FTStoreContainerHandler.shared.premiumUser, !premiumUser.isPremiumUser {
            cancellabelAction = FTStoreContainerHandler.shared.premiumUser?.$isPremiumUser.sink(receiveValue: { [weak self] isPremiumUser in
                self?.premiumView?.isHidden = true
                if self?.premiumView != nil, isPremiumUser {
                    self?.premiumView?.isHidden = isPremiumUser
                }
            })
        }
    }

    private func removeObserver() {
        cancellabelAction?.cancel();
        cancellabelAction = nil;
    }
    deinit {
        removeObserver();
    }

}
