//
//  FTIAPViewModel.swift
//  Noteshelf3
//
//  Created by Siva on 15/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import StoreKit

protocol FTIAPViewModelDelegate: AnyObject  {
    func willStartLongProcess(_ action: FTIAPActionType)
    func didFinishLongProcess(_ action: FTIAPActionType)
    func showIAPRelatedError(_ error: Error)
    func didfinishLoadingProducts()
    func didFinishRestoringPurchasesWithZeroProducts()
    func didFinishRestoringPurchasedProducts()
}

enum FTIAPActionType: Int {
    case getDetails,restore,purchase;
}

class FTIAPViewModel {
    // MARK: - Properties
    private var products: [SKProduct] = []

    weak var delegate: FTIAPViewModelDelegate?

    func viewDidSetup() {
        delegate?.willStartLongProcess(.getDetails)

        FTIAPManager.shared.getProducts { (result) in
            DispatchQueue.main.async {
                self.delegate?.didFinishLongProcess(.getDetails)

                switch result {
                case .success(let products):
                    self.products = products
                    self.delegate?.didfinishLoadingProducts()
                case .failure(let error): self.delegate?.showIAPRelatedError(error)
                }
            }
        }
    }

    func purchase(product: SKProduct) -> Bool {
        if !FTIAPManager.shared.canMakePayments() {
            return false
        } else {
            delegate?.willStartLongProcess(.purchase)

            FTIAPManager.shared.buy(product: product) { (result) in
                DispatchQueue.main.async {
                    self.delegate?.didFinishLongProcess(.purchase)
                    switch result {
                    case .success(_):
                        FTIAPurchaseHelper.shared.isPremiumUser = true
                    case .failure(let error): self.delegate?.showIAPRelatedError(error)
                    }
                }
            }
        }

        return true
    }

    func restorePurchases() {
        delegate?.willStartLongProcess(.restore)
        FTIAPManager.shared.restorePurchases { (result) in
            DispatchQueue.main.async {
                self.delegate?.didFinishLongProcess(.restore)
                switch result {
                case .success(let success):
                    if success {
                        FTIAPurchaseHelper.shared.isPremiumUser = true
                        self.delegate?.didFinishRestoringPurchasedProducts()
                    } else {
                        self.delegate?.didFinishRestoringPurchasesWithZeroProducts()
                    }
                    
                case .failure(let error): self.delegate?.showIAPRelatedError(error)
                }
            }
        }
    }

    func getProduct(at index: Int) -> SKProduct? {
        guard index < products.count else {
            return nil
        }
        return products[index]
    }

}













