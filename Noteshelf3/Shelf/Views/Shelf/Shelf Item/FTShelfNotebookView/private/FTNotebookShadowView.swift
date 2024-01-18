//
//  FTNotebookShadowView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 23/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTNotebookShadowView: View {
    @ObservedObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel

    var thumbnailSize: CGSize = CGSize(width: 214, height: 298)
    private let factor = 1/UIScreen.main.scale

    var body: some View {
        coverImage
    }
    private var shadowImageEdgeInsets: UIEdgeInsets {
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            var insets = UIEdgeInsets(top: 40 * factor, left: 60 * factor, bottom: 85 * factor, right: 60 * factor)
            if shelfViewModel.displayStlye == .List {
                insets = UIEdgeInsets(top: 20 * factor, left: 28 * factor, bottom: 36 * factor, right: 28 * factor)
            }
            return insets
        } else {
            var insets = UIEdgeInsets(top: 50 * factor, left: 60 * factor, bottom: 95 * factor, right: 70 * factor)
            if shelfViewModel.displayStlye == .List {
                insets = UIEdgeInsets(top: 20 * factor, left: 26 * factor, bottom: 34 * factor, right: 26 * factor)
            }
            return insets
        }
    }
    private var coverPadding: EdgeInsets {
        var insets = EdgeInsets(top: 16 * factor, leading: 40 * factor, bottom: 64 * factor, trailing: 40 * factor)
        if shelfViewModel.displayStlye == .List {
            insets = EdgeInsets(top: 8 * factor, leading: 16 * factor, bottom: 25 * factor, trailing: 16 * factor)
        }
        return insets
    }
    private var shadowImage: UIImage {
        var _shadowImage: UIImage?
        var requiredScale: CGFloat = 2
        #if targetEnvironment(macCatalyst)
        requiredScale = 1
        #endif
        var shadowImageName = shelfViewModel.displayStlye == .List ? "noCoverListNBShadow" : "noCoverNBShadow"
        if shelfItem.coverImage.isAStandardCover {
            shadowImageName = shelfViewModel.displayStlye == .List ? "coveredListNBShadow" : "coveredNBShadow"
        }
        if let img = UIImage(named: shadowImageName), let cgImage = img.cgImage {
            _shadowImage = UIImage(cgImage: cgImage, scale: requiredScale, orientation: img.imageOrientation);
        }
        return _shadowImage ?? UIImage(named: shadowImageName)!
    }
    private var coverImage: some View {
    #if targetEnvironment(macCatalyst)
        Image(uiImage: shadowImage.resizableImage(withCapInsets: shadowImageEdgeInsets, resizingMode: .stretch))
            .aspectRatio(CGSize(width: thumbnailSize.width + (coverPadding.leading + coverPadding.trailing), height: thumbnailSize.height + (coverPadding.top + coverPadding.bottom)), contentMode: .fit)
    #else
        Image(uiImage: shadowImage.resizableImage(withCapInsets: shadowImageEdgeInsets, resizingMode: .stretch))
    #endif
    }
}
