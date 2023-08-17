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

    let screenScale = UIScreen.main.scale
    var thumbnailSize: CGSize = CGSize(width: 214, height: 298)

    var body: some View {
        coverImage
    }
    private var shadowImageEdgeInsets: UIEdgeInsets {
        if shelfItem.coverImage.needEqualCorners || shelfItem.coverImage.isDefaultCover {
            var insets = UIEdgeInsets(top: 40/screenScale, left: 60/screenScale, bottom: 85/screenScale, right: 60/screenScale)
            if shelfViewModel.displayStlye == .List {
                insets = UIEdgeInsets(top: 20/screenScale, left: 28/screenScale, bottom: 36/screenScale, right: 28/screenScale)
            }
            return insets
        } else {
            var insets = UIEdgeInsets(top: 50/screenScale, left: 60/screenScale, bottom: 95/screenScale, right: 70/screenScale)
            if shelfViewModel.displayStlye == .List {
                insets = UIEdgeInsets(top: 20/screenScale, left: 26/screenScale, bottom: 34/screenScale, right: 26/screenScale)
            }
            return insets
        }
    }
    private var coverPadding: EdgeInsets {
        var insets = EdgeInsets(top: 16/screenScale, leading: 40/screenScale, bottom: 64/screenScale, trailing: 40/screenScale)
        if shelfViewModel.displayStlye == .List {
            insets = EdgeInsets(top: 8/screenScale, leading: 16/screenScale, bottom: 25/screenScale, trailing: 16/screenScale)
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
