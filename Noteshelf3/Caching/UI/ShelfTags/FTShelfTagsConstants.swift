//
//  FTShelfTagsConstants.swift
//  Noteshelf3
//
//  Created by Siva on 11/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
struct FTShelfTagsConstants {
    struct Page {
        static let potraitSize = CGSize(width: 163, height: 223)
        static let landscapeSize = CGSize(width: 163, height: 117)
        static let interItemSpacing: CGFloat = 16.0
        static let minInterItemSpacing: CGFloat = 32.0
        static let gridHorizontalPadding: CGFloat = 32.0
        static let extraHeightPadding: CGFloat = 52.0
        static let potraitAspectRation: CGFloat = (163/223)
        static let landscapeAspectRatio: CGFloat = (163/117)
        static let minLineSpacing: CGFloat = 32.0
    }

    struct Book {
        static let potraitSize = CGSize(width: 136, height: 189)
        static let landscapeSize = CGSize(width: 136, height: 97)
        static let interItemSpacing: CGFloat = 16.0
        static let minInterItemSpacing: CGFloat = 16.0
        static let gridHorizontalPadding: CGFloat = 32.0
        static let extraHeightPadding: CGFloat = 56.0
        static let potraitAspectRation: CGFloat = (136/189)
        static let landscapeAspectRatio: CGFloat = (136/97)
    }

}
