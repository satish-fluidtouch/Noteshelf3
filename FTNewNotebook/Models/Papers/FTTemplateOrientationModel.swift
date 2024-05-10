//
//  FTTemplateOrientationModel.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 01/03/23.
//

import UIKit

public enum FTTemplateOrientation: String, CaseIterable {
    case portrait
    case landscape

    public var isLandscape: Bool {
        return self == .landscape
    }

    var title: String {
        if self == .landscape {
            return "Landscape".localized
        }
        return "Portrait".localized
    }

    public var image: UIImage {
        var img = UIImage(systemName: "ipad")
        if self == .landscape {
            img = UIImage(systemName: "ipad.landscape")
        }
        return img ?? UIImage()
    }

    public static func orientation(for size: CGSize) -> FTTemplateOrientation {
        var orientation = FTTemplateOrientation.portrait
        if size.width > size.height {
            orientation = .landscape
        }
        return orientation
    }
}
