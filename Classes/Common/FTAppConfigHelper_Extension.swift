//
//  FTAppConfigHelper_Extension.swift
//  Noteshelf3
//
//  Created by Akshay on 04/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
enum OfferPriceLocation: Int {
    case priceOnButton = 1
    case priceAboveButton = 2
}

extension FTAppConfigHelper {
    func variantForOfferPremium() -> OfferPriceLocation {
        let location = self.offerPriceLocationForIAPOffer()

        guard let location = OfferPriceLocation(rawValue: location) else {
            return OfferPriceLocation.priceOnButton
        }

        return location
    }
}
