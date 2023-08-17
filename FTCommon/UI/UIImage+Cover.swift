//
//  UIImage+Cover.swift
//  FTCommon
//
//  Created by Ramakrishna on 24/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

public let portraitCoverSize: CGSize = CGSize(width: 214, height: 298)
public let portraitNoCoverSize: CGSize = CGSize(width: 215, height: 299)
public let landscapeCoverSize: CGSize = CGSize(width: 259, height: 185)
public let landscapeNoCoverSize: CGSize = CGSize(width: 260, height: 186)
public let defaultCoverSize: CGSize = CGSize(width: 215, height: 299)
extension UIImage {
    //No Cover OR Cover with landscape
    public var needEqualCorners: Bool {
         ((self.size.width.remainder(dividingBy: landscapeCoverSize.width) == 0) ||
          hasNoCover)
    }
    // No Cover
    public var hasNoCover: Bool {
        ((self.size.width.remainder(dividingBy: portraitNoCoverSize.width) == 0) ||
           (self.size.width.remainder(dividingBy: landscapeNoCoverSize.width) == 0))
    }
    //Used for group cover purpose
    public var isAPortCover: Bool {
        (self.size.width.remainder(dividingBy: portraitCoverSize.width) == 0) ||
        (self.size.width.remainder(dividingBy: defaultCoverSize.width) == 0) ||
        (self.size.width.remainder(dividingBy: portraitNoCoverSize.width) == 0)
    }
    //Used for group cover purpose
    public var isALandCover: Bool {
        (self.size.width.remainder(dividingBy: landscapeCoverSize.width) == 0) ||
        (self.size.width.remainder(dividingBy: landscapeNoCoverSize.width) == 0)
    }
    //Fall back cover
    public var isDefaultCover: Bool {
        (self.size.width.remainder(dividingBy: defaultCoverSize.width) == 0)
    }
    //Standard Covers
    public var isAStandardCover: Bool {
        (self.size.width.remainder(dividingBy: portraitCoverSize.width) == 0)
    }
}
