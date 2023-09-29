//
//  FTFavoritePensetDataModel.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTFavoritePensetDataModel: Codable {
    let version: String
    var favorites: [FTFavoritePenset]
}

struct FTFavoritePenset: Codable {
    let type: Int
    let color: String
    let size: CGFloat
    let preciseSize: String

    func getPenset() -> FTPenSetProtocol {
        guard let type = FTPenType(rawValue: type), let penSize = FTPenSize(rawValue: Int(size)) else {
            fatalError("Unable to convert to required object")
        }
        let penSet = FTPenSet(type: type, color: color, size: penSize)
        penSet.preciseSize = CGFloat((preciseSize as NSString).floatValue)
        return penSet
    }
}
