//
//  FTChooseCoverModels.swift
//  FTNewNotebook
//
//  Created by Narayana on 27/02/23.
//

import UIKit

public enum FTCoverSelectedType {
    case noCover
    case standard
    case custom
}

struct FTCoverVariantModel {
    let name: String
    let imageName: String
}

struct FTCoverStyleVariantConfig {
    let borderWidthSelected: CGFloat = 4.0
    let borderWidthUnSelected: CGFloat = 0.5
    let cornerRadiusSelected: CGFloat = 20.0
    let cornerRadiusUnSelected: CGFloat = 16.0
    let borderLayerId = "Border"
}

struct FTCoverStyleConfig {
    let borderWidthSelected: CGFloat = 6.0
    let borderLayerId = "Border"
    let borderColor = UIColor.appColor(.accent).cgColor
    let leftRadius: CGFloat = 4.0
    let rightRadius: CGFloat = 10.0
}
