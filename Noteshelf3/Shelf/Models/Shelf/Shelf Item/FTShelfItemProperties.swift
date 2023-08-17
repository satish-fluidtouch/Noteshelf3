//
//  FTShelfItemProperties.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTShelfItemCoverViewProperties {
    case small
    case medium
    case large

    var topAndBottomLeftCornerRadius: CGFloat {
        switch self {
        case .small:
            return 0.94
        case .medium:
            return 2.47
        case .large:
            return 4.0
        }
    }
    var topAndBottomRightCornerRadius: CGFloat {
        switch self {
        case .small:
            return 2.44
        case .medium:
            return 6.18
        case .large:
            return 10.0
        }
    }
}

enum FTNotebookCoverSizeType {
    case regular
    case compact

    func fetchCoverSize(for image: UIImage) -> CGSize {
        let notebookCoverType : FTNotebookCoverType = image.isLandscapeCover() ? .landscape : .portrait
        let shelfItemSize = FTShelfItemProperties.getCoverSizeFor(notebookCoverSizeType: self, notebookCoverType: notebookCoverType)
        return shelfItemSize
    }
}

enum FTNotebookCoverType {
    case portrait
    case landscape
}
enum FTGroupCoverOrderType {
    case top
    case middle
    case bottom
}
struct FTShelfItemProperties {

    //*********************** For Dynamic shelf Items (New Design) ***********//

    struct Constants {
        struct Notebook {
            static let titleRectHeight: CGFloat = 72
            static let totalHorizontalPadding: CGFloat = 24
            static let landscapeCoverHeightPercnt : CGFloat = (154/214)
            static let portraitCoverHeightPercnt: CGFloat = (298/214)
            static let interItemSpacing: CGFloat = 16
            static let portNBCoverleftCornerRadius: CGFloat = 6
            static let portNBCoverRightCornerRadius: CGFloat = 16
            static let landCoverCornerRadius: CGFloat = 10
            static let portListNBCoverleftCornerRadius: CGFloat = 2
            static let portListNBCoverRightCornerRadius: CGFloat = 4
            static let landListCoverCornerRadius: CGFloat = 4
            static let portIconNBCoverleftCornerRadius: CGFloat = 4
            static let portIconNBCoverRightCornerRadius: CGFloat = 10
            static let landIconCoverCornerRadius: CGFloat = 8

        }
        struct Group {
            static let nbLeftCornerRadius: CGFloat = 2.5
            static let nbRightCornerRadius: CGFloat = 6.5
            static let noCoverCornerRadius: CGFloat = 6.5
            static let coverWidthPercnt: CGFloat = (214/298)
            static let iconViewNBLeftCornerRadius: CGFloat = 2
            static let iconViewNBRightCornerRadius: CGFloat = 4
            static let iconViewNoCoverCornerRadius: CGFloat = 4
            static let listViewNBLeftCornerRadius: CGFloat = 1
            static let listViewNBRightCornerRadius: CGFloat = 2
            static let listViewNoCoverCornerRadius: CGFloat = 2
            static let moveFormsheetNBLeftCornerRadius: CGFloat = 0.4
            static let moveFormsheetNBRightCornerRadius: CGFloat = 1
            static let moveFormsheetNoCoverCornerRadius: CGFloat = 1
        }
    }

    //************** Notebook ************//
    static let portraitRegularNotebookCoverSize: CGSize = CGSize(width: 136, height: 180)
    static let portraitCompactNotebookCoverSize: CGSize = CGSize(width: 84, height: 111)
    static let landscapeRegularNotebookCoverSize: CGSize = CGSize(width: 146, height: 111)
    static let landscapeCompactNotebookCoverSize: CGSize = CGSize(width: 92, height: 70)
    //************************************//

    static func getCoverSizeFor(notebookCoverSizeType: FTNotebookCoverSizeType, notebookCoverType: FTNotebookCoverType) -> CGSize {
        if notebookCoverSizeType == .regular {
            if notebookCoverType == .portrait {
                return portraitRegularNotebookCoverSize
            } else {
                return landscapeRegularNotebookCoverSize
            }
        } else {
            if notebookCoverType == .portrait {
                return portraitCompactNotebookCoverSize
            } else {
                return landscapeCompactNotebookCoverSize
            }
        }
    }
//MARK: - For corner radius
    static func leftCornerRadiusForShelfItemImage(_ image: UIImage, displayStyle: FTShelfDisplayStyle = .Gallery) -> CGFloat {
        let notebookConstants = Constants.Notebook.self
        var radius: CGFloat = landscapedCornerRadiusForDisplayStyle(displayStyle)

        if image.isAStandardCover {
            switch displayStyle {
            case .Gallery:
                radius = notebookConstants.portNBCoverleftCornerRadius
            case .Icon:
                radius = notebookConstants.portIconNBCoverleftCornerRadius
            case .List:
                radius = notebookConstants.portListNBCoverleftCornerRadius
            }
        }
        return radius
    }

    static func rightCornerRadiusForShelfItemImage(_ image: UIImage, displayStyle: FTShelfDisplayStyle = .Gallery) -> CGFloat {
        let notebookConstants = Constants.Notebook.self
        var radius: CGFloat = landscapedCornerRadiusForDisplayStyle(displayStyle)

        if image.isAStandardCover {
            switch displayStyle {
            case .Gallery:
                radius = notebookConstants.portNBCoverRightCornerRadius
            case .Icon:
                radius = notebookConstants.portIconNBCoverRightCornerRadius
            case .List:
                radius = notebookConstants.portListNBCoverRightCornerRadius
            }
        }
        return radius
    }
    static private func landscapedCornerRadiusForDisplayStyle(_ displayStyle: FTShelfDisplayStyle = .Gallery) -> CGFloat {
        let notebookConstants = Constants.Notebook.self
        let radius: CGFloat
        switch displayStyle {
        case .Gallery:
            radius = notebookConstants.landCoverCornerRadius
        case .Icon:
            radius = notebookConstants.landIconCoverCornerRadius
        case .List:
            radius = notebookConstants.landListCoverCornerRadius
        }
        return radius
    }
}
