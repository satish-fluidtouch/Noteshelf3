//
//  FTNewNotebookConstants.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 24/02/23.
//

import Foundation
import UIKit
import FTStyles

let currentBundle = Bundle(for: FTCreateNotebookViewController.self)
let regularThreshold: CGFloat = 475

struct FTNewNotebook {
    struct Constants {
        struct ChoosePaperPanel {
            static let regularItemSpacing: CGFloat = 24.0
            static let compactItemSpacing: CGFloat = 16.0
            static let paperTemplateLineItemSpacing: CGFloat = 32.0
            static let templateCellRegularSize = CGSize(width: 120, height: 148)
            static let templateCellCompactSize = CGSize(width: 100, height: 128)
            static let thumbnailRegularSize = CGSize(width: 120, height: 120)
            static let thumbnailCompactSize = CGSize(width: 100, height: 100)
            struct preview {
                static let regularPortraitOrientationPortraitSize = CGSize(width: 224, height: 298)
                static let regularPortraitOrientationLandscapeSize = CGSize(width: 298, height: 224)
                static let regularLandscapeOrientationPortraitSize = CGSize(width: 224, height: 298)
                static let regularLanscapeOrientationLandscapeSize = CGSize(width: 298, height: 224)
            }
        }
        struct ShadowRadius {
            static let newNotebookButton = 16.0
            static let titleView = 10.0
        }
        struct ShadowOffset {
            static let newNotebookButton = CGSize(width: 0, height: 8)
            static let titleView = CGSize(width: 0, height: 4)
        }
        struct ShadowColor {
            static let newNotebookButton = UIColor.appColor(.createNotebookButtonShadow)
            static let titleView = UIColor.appColor(.createNotebookTitleViewShadow)
        }
        struct CoverSize {
            struct Regular {
                static let cover = CGSize(width: 224, height: 298)
            }
            struct Compact {

            }
        }
        struct PaperSize {
            struct Regular {
                static let landscapePaper = CGSize(width: 298, height: 224)
                static let portraitPaper = CGSize(width: 224, height: 298)
            }
            struct Compact {

            }
        }
        struct TintColor {
            static let defaultPassword: UIColor? = UIColor.appColor(.passwordDefaultTint)
            static let selectedPassword: UIColor? = UIColor.appColor(.passwordSelectedTint)
        }
        struct buttonImage {
            static let noPassword: UIImage? = UIImage(systemName: "lock.slash.fill")
            static let withPassword: UIImage? = UIImage(systemName: "lock.fill")
        }
        struct SelectedAccent {
            static let tint: UIColor = UIColor.appColor(.accent)
        }
        struct SelectedCoverRadius{
            static let topLeft: CGFloat = 6
            static let bottomLeft: CGFloat = 6
            static let topRight: CGFloat = 14
            static let bottomRight: CGFloat = 14
        }
        struct NoCoverRadius {
            static let allCorners: CGFloat = 9.0
        }
    }
}
