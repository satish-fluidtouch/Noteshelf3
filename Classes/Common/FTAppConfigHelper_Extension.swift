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

enum iRateMessageType: String {
    case a
    case b
    case c

    var message: String {
        let message: String
        switch self {
        case .a:
            message = "irate.variation.message.a".localized
        case .b:
            message = "irate.variation.message.b".localized
        case .c:
            message = "irate.variation.message.c".localized
        }
        return message
    }

    var title: String {
        let message: String
        switch self {
        case .a:
            message = "irate.variation.title.a".localized
        case .b:
            message = "irate.variation.title.b".localized
        case .c:
            message = "irate.variation.title.c".localized
        }
        return message
    }
}

extension FTAppConfigHelper {
    func variantForOfferPremium() -> OfferPriceLocation {
            OfferPriceLocation.priceOnButton
    }

    @objc func messageforiRate() -> String {
        let variation = self.variationForiRateMessage()

        guard let type = iRateMessageType(rawValue: variation) else {
            return iRateMessageType.a.message
        }

        return type.message
    }

    @objc func titleforiRate() -> String {
        let variation = self.variationForiRateMessage()

        guard let type = iRateMessageType(rawValue: variation) else {
            return iRateMessageType.a.title
        }

        return type.title
    }
}
