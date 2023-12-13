//
//  FTIAPContainerViewController.swift
//  Noteshelf3
//
//  Created by Akshay on 04/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTIAPContainerDelegate: AnyObject {
    func purchase(product: SKProduct)
    func restorePurchases()
}

class FTIAPContainerViewController: UIViewController {
    private var viewModel = FTIAPViewModel()
    @IBOutlet weak var activityProgressHolderView: UIView!
    @IBOutlet weak var contentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidSetup()
    }

    @IBAction func closeAction(_ sender: Any) {
        track(EventName.premium_close_tap, screenName: ScreenName.iap)
        self.dismiss(animated: true)
    }
}

extension FTIAPContainerViewController {
    private func showAlert(withMessage message: String,closeOnOk: Bool = false) {
        let alertController = UIAlertController(title: "Noteshelf", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self] _ in
            if(closeOnOk) {
                self?.dismiss(animated: true);
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - ViewModelDelegate
extension FTIAPContainerViewController: FTIAPViewModelDelegate {
    func didfinishLoadingProducts() {
        self.isModalInPresentation = true
        var viewcontroller: UIViewController?
        if FTDocumentMigration.isNS2AppInstalled(),
           let ns2Product = viewModel.ns3PremiumForNS2UserProduct(),
           let ns3Product = viewModel.ns3PremiumProduct() {
            viewcontroller = FTIAPOfferViewController.instatiate(discountedProduct: ns2Product, originalProduct: ns3Product, delegate: self)
        } else if let ns3product = viewModel.ns3PremiumProduct() {
            viewcontroller = FTIAPViewController.instatiate(with: ns3product, delegate: self)
        } else {
            showAlert(withMessage: "MakeSureYouAreConnected".localized)
        }
        if let viewcontroller {
            self.addChild(viewcontroller)
            viewcontroller.view.addFullConstraints(contentView)
        }
    }

    func willStartLongProcess(_ action: FTIAPActionType) {
        self.activityProgressHolderView?.isHidden = false;
    }

    func didFinishLongProcess(_ action: FTIAPActionType) {
        self.activityProgressHolderView?.isHidden = true;
        if action == .purchase, FTIAPurchaseHelper.shared.isPremiumUser {
            self.dismiss(animated: true);
        }
    }

    func showIAPRelatedError(_ error: Error) {
        let message = error.localizedDescription
        showAlert(withMessage: message)
    }

    func didFinishRestoringPurchasesWithZeroProducts() {
        showAlert(withMessage: "iap.restoreSuccessWithNoPurchase".localized)
    }

    func didFinishRestoringPurchasedProducts() {
        showAlert(withMessage: "iap.restoreSuccess".localized,closeOnOk: true)
    }
}

extension FTIAPContainerViewController: FTIAPContainerDelegate {
    func purchase(product: SKProduct) {
        if !self.viewModel.purchase(product: product) {
            self.showAlert(withMessage: "iap.purchaseNotAllowed".localized)
        }
    }

    func restorePurchases() {
        viewModel.restorePurchases()
    }
}
