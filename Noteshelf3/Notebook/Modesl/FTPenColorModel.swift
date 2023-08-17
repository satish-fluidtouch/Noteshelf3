//
//  FTPenColorModel.swift
//  Noteshelf3
//
//  Created by Narayana on 01/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import MobileCoreServices

public class FTPenColorModel: NSObject, NSItemProviderWriting {
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        do {
            let dict = ["PresetHex": self.hex,
                        "isSelected": self.isSelected] as [String: Any]
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                          format: .xml,
                                                          options: 0)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }

    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeData as String]
    }

    var hex: String
    var isSelected: Bool

    init(hex: String, isSelected: Bool = false) {
        self.hex = hex
        self.isSelected = isSelected
    }
}

public enum FavoriteColorPosition: Int, CaseIterable {
    case first = 0
    case second
    case third
    case custom

   static func getPosition(index: Int) -> FavoriteColorPosition {
        var position = FavoriteColorPosition.custom
       if index == 0 {
           position = .first
       } else if index == 1 {
            position = .second
        } else if index == 2 {
            position = .third
        } 
        return position
    }
}
