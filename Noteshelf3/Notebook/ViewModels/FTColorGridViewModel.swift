//
//  FTColorGridModel.swift
//  Noteshelf3
//
//  Created by Narayana on 09/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTColorGridModel: ObservableObject {
    var gridColors: [FTGridColor] = []

     init() {
         let colors = FTGridDataProvider.getRackData()
        self.gridColors = colors.map({ color in
            FTGridColor(color: color, location: CGRect.zero)
        })
    }

    func getGridColor(at point: CGPoint) -> FTGridColor? {
        let colors = self.gridColors.filter({ gridColor in
            return gridColor.location.contains(point)
        })

        if !colors.isEmpty, let color = colors.first {
            return color
        }
        return nil
    }
}

class FTGridColor: NSObject {
    let color: String
    var location: CGRect = .zero

    init(color: String, location: CGRect) {
        self.color = color
        self.location = location
    }
}
