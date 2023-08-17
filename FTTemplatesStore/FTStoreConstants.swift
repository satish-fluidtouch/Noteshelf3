//
//  FTStoreConstants.swift
//  FTTemplatesStore
//
//  Created by Siva on 26/05/23.
//

import Foundation
import UIKit

struct FTStoreConstants {
    struct Banner {
        static let maxSize = CGSize(width: 436, height: 224)
        static let aspectRatio: CGFloat = (436/224)
        static let leftIntent: CGFloat = 20
        static let interItemSpacing: CGFloat = 12.0
        static let nextItemVisibleSpacing: CGFloat = 15.0
        static let extraHeightPadding: CGFloat = 32.0
        static let topBottomInset = 32.0

        static func calculateSizeFor(view: UIView) -> CGSize {
            let screenSize = view.frame.size
            let maxBannerSize = maxSize
            let padding: CGFloat = leftIntent + interItemSpacing + nextItemVisibleSpacing
            if maxBannerSize.width + padding > screenSize.width {
                let bannerWidth = screenSize.width - padding
                let bannerHeight = bannerWidth/aspectRatio
                return CGSize(width: bannerWidth, height: bannerHeight)
            }
            return maxBannerSize
        }
    }

    struct StoreTemplate {
        static let extraHeightPadding = 30.0
        static let innerItemSpacing = 24.0
        static let size = CGSize(width: 224, height: 299)
        static let topBottomInset = 32.0
    }

    struct DigitalDiary {
        static let extraHeightPadding = 30.0
        static let innerItemSpacing = 24.0
        static let size = CGSize(width: 178, height: 247)
        static let topBottomInset = 32.0
    }

    struct Sticker {
        static let maxSize = CGSize(width: 340, height: 171)
        static let aspectRatio: CGFloat = (340/171)
        static let leftIntent: CGFloat = 20
        static let interItemSpacing: CGFloat = 16.0
        static let nextItemVisibleSpacing: CGFloat = 15.0
        static let extraHeightPadding: CGFloat = 30.0
        static func calculateSizeFor(view: UIView) -> CGSize {
            let screenSize = view.frame.size
            let maxBannerSize = maxSize
            let padding: CGFloat = leftIntent + interItemSpacing + nextItemVisibleSpacing
            if maxBannerSize.width + padding > screenSize.width {
                let bannerWidth = screenSize.width - padding
                let bannerHeight = bannerWidth/aspectRatio
                return CGSize(width: bannerWidth, height: bannerHeight)
            }
            return maxBannerSize
        }
    }

    struct Template {
        static let potraitSize = CGSize(width: 214, height: 288)
        static let landscapeSize = CGSize(width: 240, height: 181)
        static let interItemSpacing: CGFloat = 20.0
        static let gridHorizontalPadding: CGFloat = 20.0
        static let extraHeightPadding: CGFloat = 30.0
        static let potraitAspectRation: CGFloat = (214/288)
        static let landscapeAspectRatio: CGFloat = (240/181)
    }

    struct TemplatePreview {
        static let potraitAspectSize = CGSize(width: 834, height: 1112)
        static let landscapeAspectSize = CGSize(width: 1112, height: 834)
    }

    struct DiaryPreview {
        static let potraitAspectSize = CGSize(width: 834, height: 1126)
        static let landscapeAspectSize = CGSize(width: 1194, height: 766)

    }

}

