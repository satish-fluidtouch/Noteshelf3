//
//  FTShareBasePreviewView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 30/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

protocol FTShareBasePreviewView : View {
    var itemViewModel: FTSharePreviewItemViewModel { get}
}
extension FTShareBasePreviewView {
    var leftCornerRadius: CGFloat {
        var radius: CGFloat = 0.0
        if let coverImage = itemViewModel.coverImage {
            radius = FTShelfItemProperties.leftCornerRadiusForShelfItemImage(coverImage)
        }
        return radius
    }

    var rightCornerRadius: CGFloat {
        var radius: CGFloat = 0.0
        if let coverImage = itemViewModel.coverImage {
            radius = FTShelfItemProperties.rightCornerRadiusForShelfItemImage(coverImage)
        }
        return radius
    }
}
