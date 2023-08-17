//
//  FTGridDataProvider.swift
//  Noteshelf3
//
//  Created by Narayana on 20/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTGridDataProvider: NSObject {
    private static var gridDataUrl: URL {
        guard let url = Bundle.main.url(forResource: "GridColors", withExtension: "plist") else {
            fatalError("Programmer error, Couldn't find GridColors plist")
        }
        return url
    }

    static func getRackData() -> [String] {
        var gridColors: [String] = []
        do {
            let gridData = try Data(contentsOf: self.gridDataUrl)
            if let colorsArray = try PropertyListSerialization.propertyList(from: gridData, options: [], format: nil) as? [String] {
                gridColors = colorsArray
            }
        }
        catch {
            gridColors = []
        }
        return gridColors
    }
}


