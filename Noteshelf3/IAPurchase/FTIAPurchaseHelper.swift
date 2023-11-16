//
//  FTIAPurchaseHelper.swift
//  Noteshelf3
//
//  Created by Siva on 15/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import TPInAppReceipt

let premiumUserStatus = "premiumUserStatus"

final class FTIAPurchaseHelper {

    static let shared = FTIAPurchaseHelper()
    
    func presentIAPIfNeeded(on controller: UIViewController) {
        let storyboard = UIStoryboard(name: "IAPEssentials", bundle: nil)
        guard let inAppPurchase = storyboard.instantiateViewController(withIdentifier: "FTIAPViewController") as? FTIAPViewController else {
            fatalError("FTIAPViewController doesnt exist")
        }
        inAppPurchase.isModalInPresentation = true
        controller.ftPresentFormsheet(vcToPresent: inAppPurchase,contentSize: CGSize(width: 700, height: 740),animated: true);
    }

    func showIAPAlert(on controller: UIViewController) {
        let alertController = UIAlertController(title: "iap.booklimitReachedTitle".localized, message: "iap.booklimitReachedMessage".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "iap.upgradeNow".localized, style: .default, handler: { action in
            self.presentIAPIfNeeded(on: controller)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        controller.present(alertController, animated: true, completion: nil)
    }

    func showIAPAlertForFeature(feature: String, on controller: UIViewController) {
        let alertController = UIAlertController(title: "iap.featureLimitTitle".localized, message: "iap.featureLimitMessage".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "iap.upgradeNow".localized, style: .default, handler: { action in
            self.presentIAPIfNeeded(on: controller)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        controller.present(alertController, animated: true, completion: nil)
    }

    var isPremiumUser: Bool {
        get {
//            #if BETA
//            return true;
//            #else
            var isPremierUser = UserDefaults.standard.bool(forKey: premiumUserStatus)
            if !isPremierUser {
                isPremierUser = isIAPPurchasedViaReceipt();
                if(isPremierUser) {
                    self.isPremiumUser = isPremierUser;
                }
            }
            updatePremiumUserInfoToNS2(isPremium: isPremierUser)
            return isPremierUser;
//            #endif
        } set {
            FTIAPManager.shared.premiumUser.isPremiumUser = newValue;
            UserDefaults.standard.set(newValue, forKey: premiumUserStatus)
            updatePremiumUserInfoToNS2(isPremium: newValue)
        }
    }

    private func isIAPPurchasedViaReceipt() -> Bool {
        var isPremium = false
        if let receipt = try? InAppReceipt.localReceipt() {
            let purchases = receipt.purchases;
            let items = FTIAPManager.shared.iapProductsIdentifier()
            for eachPurchase in purchases {
                if items.contains(eachPurchase.productIdentifier) {
                    isPremium = true;
                    break;
                }
            }
        }
        return isPremium;
    }
}

private extension FTIAPurchaseHelper {
    func updatePremiumUserInfoToNS2(isPremium: Bool) {
        let ns2Defaults = UserDefaults(suiteName: FTSharedGroupID.getNS2AppGroupID())
        ns2Defaults?.set(isPremium, forKey: premiumUserStatus)
    }
}
